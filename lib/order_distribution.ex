defmodule OrderDistribution do
    @moduledoc """
    Module for peer-to-peer-communication between the elevators
    """

    use GenServer

    def start_link(_args) do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    @impl true
    def init(_init_args) do
        Lights.turn_off_all

        my_name = Constants.elev_number_to_node_name(RuntimeConstants.get_elev_number)
        Node.start(my_name, :longnames, 15000)
        Node.set_cookie(:safari)

        {:ok, :single_elevator}
    end



    def handle_order(order) do
        if RuntimeConstants.debug?, do: Debug.print_debug(:hw_order, order)

        GenServer.cast(__MODULE__, {:new_order, order})
    end

    @impl true
    def handle_cast({:new_order, order}, :single_elevator) do
        if RuntimeConstants.debug?, do: Debug.print_debug(:new_order_single_elevator, order)

        accept_order(order)
        {:noreply, :single_elevator}
    end

    @impl true
    def handle_cast({:new_order, {floor, :cab, :order}}, :ptp_elevator) do
        if RuntimeConstants.debug?, do: Debug.print_debug(:new_cab_order_ptp_elevator, {floor, :cab, :order})

        order = {floor, :cab, :order}
        {replies, _bad_nodes} = GenServer.multi_call(Node.list, OrderDistribution, {:log_this_order, order, Node.self}, Constants.peer_wait_for_response_ms)   #if timeout, then?
        if replies != [], do: accept_order(order)
        {:noreply, :ptp_elevator}
    end

    @impl true
    def handle_cast({:new_order, order}, :ptp_elevator) do
        node_to_assign_order = find_node_with_lowest_cost(order)

        if RuntimeConstants.debug?, do: Debug.print_debug(:new_order_ptp_elevator, [order, node_to_assign_order])

        Node.spawn(node_to_assign_order, OrderDistribution, :take_this_order, [order])   # Would prefer this to be a call to the module, as to keep track of  the assigner
        {:noreply, :ptp_elevator}
    end



    def take_this_order(order) do
        GenServer.call(__MODULE__, {:take_this_order, order})
    end
    @impl true
    def handle_call({:take_this_order, order}, from, state) do
        if RuntimeConstants.debug?, do: Debug.print_debug(:take_this_order, [order, from])

        {replies, _bad_nodes} = GenServer.multi_call(Node.list, OrderDistribution, {:log_this_order, order, Node.self}, Constants.peer_wait_for_response_ms)
        if replies != [], do: accept_order(order)
        {:reply, :ok, state}
    end

    @impl true
    def handle_call({:log_this_order, order, from_node}, _from, state) do
        if RuntimeConstants.debug?, do: Debug.print_debug(:log_this_order, [order, from_node])

        BackupQueue.add_order(from_node, order)
        
        {floor, order_type, :order} = order
        if order_type != :cab, do: Lights.turn_on(floor, order_type)

        {:reply, :ok, state}
    end

    @impl true
    def handle_call({:unlog_hall_orders_to, node_name}, _from, state) do
        IO.write("Unlogging hall_orders of :")
        IO.inspect(node_name)

        BackupQueue.pop_active_hall_orders(node_name)
        {:reply, :ok, state}
    end

    @impl true
    def handle_call({:orders_served, floor, from_node}, _from, state) do
        if RuntimeConstants.debug?, do: Debug.print_debug(:orders_served, [floor, from_node])

        BackupQueue.remove_all_orders_to_floor(from_node, floor)
        
        Lights.turn_off(floor, :hall_up)
        Lights.turn_off(floor, :hall_down)

        {:reply, :ok, state}
    end

    @impl true
    def handle_call({:calculate_cost, hall_order}, from, state) do
        if RuntimeConstants.debug?, do: Debug.print_debug(:calculate_cost, [hall_order, from])

        cost = Cost.calculate_cost_for_order(hall_order)
        {:reply, cost, state}
    end

    @impl true
    def handle_call({:give_active_cab_calls_of_node, node_name}, _from, state) do
        if RuntimeConstants.debug?, do: Debug.print_debug(:give_active_cab_calls_of_node, node_name)

        active_cab_calls = BackupQueue.get_all_active_orders_of_type(node_name, :cab)
        {:reply, active_cab_calls, state}
    end

    @impl true
    def handle_call({:give_active_orders}, from, state) do
        if RuntimeConstants.debug?, do: Debug.print_debug(:give_active_orders, from)

        active_orders = Queue.get_all_active_orders
        {:reply, active_orders, state}
    end



    def recover_cab_calls do
        if RuntimeConstants.debug?, do: Debug.print_debug(:recovering_cab_calls, [])

        {replies, _bad_nodes} = GenServer.multi_call(Node.list, OrderDistribution, {:give_active_cab_calls_of_node, Node.self}, Constants.peer_wait_for_response_ms)
        
        if (replies != []) do
            Enum.each(replies, fn {_from, cab_calls} -> 
                Enum.each(cab_calls, fn order -> 
                    take_this_order(order) 
                end) 
            end)
            :ok
        else
            :fuck
        end
    end

    def recover_order_logger do
        if RuntimeConstants.debug?, do: Debug.print_debug(:recovering_order_logger, [])

        {replies, _bad_nodes} = GenServer.multi_call(Node.list, OrderDistribution, {:give_active_orders}, Constants.peer_wait_for_response_ms)

        if (replies != []) do
            Enum.each(replies, fn {from_node, active_orders} -> 
                Enum.each(active_orders, fn order -> 
                    GenServer.call(__MODULE__, {:log_this_order, order, from_node})
                end)
            end)
        end
    end

    def redistribute_hall_orders_of_node(node_name) do
        GenServer.call(__MODULE__, {:redistribute_hall_orders, node_name})
    end
    @impl true
    def handle_call({:redistribute_hall_orders, node_name}, _from, state) do
        IO.write("Redistributing hall orders of elevator: ")
        IO.inspect(node_name)

        if node_name == Node.self do
            active_hall_orders = Queue.pop_active_hall_orders
            GenServer.multi_call(Node.list, OrderDistribution, {:unlog_hall_orders_to, node_name}, Constants.peer_wait_for_response_ms)
            Enum.each(active_hall_orders, fn order -> 
                handle_order(order)
            end)
        else
            active_hall_orders = BackupQueue.pop_active_hall_orders(node_name)
            GenServer.multi_call(Node.list -- [node_name], OrderDistribution, {:unlog_hall_orders_to, node_name}, Constants.peer_wait_for_response_ms)
            Enum.each(active_hall_orders, fn order -> 
                handle_order(order)
            end)
        end

        {:reply, :ok, state}
    end


    def find_node_with_lowest_cost(order) do
        # This is obtuse when calling with timeout =/= infty
        my_cost = {Node.self, Cost.calculate_cost_for_order(order)}
        {replies, _bad_nodes} = GenServer.multi_call(Node.list, OrderDistribution, {:calculate_cost, order}, Constants.peer_wait_for_response_ms)
        all_costs = [my_cost | replies]
        |> IO.inspect
        {node_with_lowest_cost, _lowest_cost} = Enum.min_by(all_costs, fn {_node, cost} -> cost end)
        node_with_lowest_cost
    end



    def accept_order(order) do
        if RuntimeConstants.debug?, do: Debug.print_debug(:accepting_order, order)

        :ok = Queue.add_order(order)
        
        {floor, order_type, _order_here} = order
        Lights.turn_on(floor, order_type)

        DriverFSM.notify_queue_updated(order)   # change this to a call and repeat until reply?
    end

    def notify_orders_served(floor) do
        GenServer.multi_call(Node.list, OrderDistribution, {:orders_served, floor, Node.self}, Constants.peer_wait_for_response_ms)
        :ok
    end



    def peers_respond do
        GenServer.call(__MODULE__, :peers_respond)
    end
    @impl true
    def handle_call(:peers_respond, _from, state) do
        IO.inspect("I think I am online!")

        if state == :single_elevator do
            Task.start(__MODULE__, :recover_cab_calls, [])
            
            Task.start(__MODULE__, :recover_order_logger, [])
        end

        {:reply, :ok, :ptp_elevator}
    end
    
    def no_peers_respond do
        GenServer.call(__MODULE__, :no_peers_respond)
    end
    @impl true
    def handle_call(:no_peers_respond, _from, _state) do
        IO.inspect("I think I am offline!")
        {:reply, :ok, :single_elevator}
    end
end