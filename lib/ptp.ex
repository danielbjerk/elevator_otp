defmodule Peer do
    @moduledoc """
    Module for peer-to-peer-communication between the elevators
    """

    use GenServer

    def start_link(elev_number) do
        GenServer.start_link(__MODULE__, elev_number, name: __MODULE__)
    end

    @impl true
    def init(elev_number) do
        # Initiere containers?


        # Starte node
        my_name = elev_number_to_node_name(elev_number)
        Node.start(my_name, :longnames, 15000)
        Node.set_cookie(:safari)


        # Starte pinger
        ping_later


        # Koble opp m/ andre heiser
        IO.inspect("Able to connect to other nodes?")
        res = able_to_ping_any?
        IO.inspect(res)
        if res do
            # Request min kø (i tilfelle jeg nettopp har vært dau)
            {:ok, :ptp_elevator}
        else
            {:ok, :single_elevator}
        end
    end



    def handle_order(order) do
        IO.inspect("-----------------------------------------")
        IO.write("New order received from HW: ")
        IO.inspect(order)

        GenServer.cast(__MODULE__, {:new_order, order})
    end

    @impl true
    def handle_cast({:new_order, order}, :single_elevator) do
        IO.inspect("-----------------------------------------")
        IO.write("Accepting order in single elevator: ")
        IO.inspect(order)

        accept_order(order)
        {:noreply, :single_elevator}
    end

    @impl true
    def handle_cast({:new_order, {floor, :cab, :order}}, :ptp_elevator) do
        IO.inspect("-----------------------------------------")
        IO.write("Accepting cab order in ptp-mode to floor: ")
        IO.inspect(floor)

        order = {floor, :cab, :order}
        {replies, bad_nodes} = GenServer.multi_call(Node.list, Peer, {:log_this_order, order}, Constants.peer_wait_for_response)   #if timeout, then?
        if replies != [], do: accept_order(order)
        {:noreply, :ptp_elevator}
    end

    @impl true
    def handle_cast({:new_order, order}, :ptp_elevator) do
        node_to_assign_order = find_node_with_lowest_cost(order)

        IO.inspect("-----------------------------------------")
        IO.inspect("The order: ")
        IO.inspect(order)
        IO.write("has been assigned to: ")
        IO.inspect(node_to_assign_order)

        #{reply, bad_reply} = GenServer.multi_call(node_to_assign_order, Peer, {:take_this_order, order}, Constants.peer_wait_for_response)  # if timeout, then?
        Node.spawn(node_to_assign_order, Peer, :take_this_order, [order])   # Would prefer this to be a call to the module, as to keep track of  the assigner
        {:noreply, :ptp_elevator}
    end



    def take_this_order(order) do
        GenServer.call(__MODULE__, {:take_this_order, order})
    end
    @impl true
    def handle_call({:take_this_order, order}, from, state) do
        IO.inspect("-----------------------------------------")
        IO.write("I've been told to take order: ")
        IO.inspect(order)
        IO.write("From: ")
        IO.inspect(from)

        {replies, bad_nodes} = GenServer.multi_call(Node.list, Peer, {:log_this_order, order}, Constants.peer_wait_for_response)
        if replies != [], do: accept_order(order)
        {:reply, :ok, state}
    end

    @impl true
    def handle_call({:log_this_order, order}, from, state) do
        IO.inspect("-----------------------------------------")
        IO.write("I am logging order: ")
        IO.inspect(order)
        IO.write("From: ")
        IO.inspect(from)
        #OrderLogger.add_order(from, order) # TODO
        
        {floor, order_type, :order} = order
        if order_type != :cab, do: Lights.turn_on(floor, order_type)

        {:reply, :ok, state}
    end

    @impl true
    def handle_call({:orders_served, floor}, from, state) do
        #OrderLogger.remove_all_orders_to_floor(floor)  # TODO
        IO.inspect("-----------------------------------------")
        IO.write("I am clearing orders at floor: ")
        IO.inspect(floor)
        
        Lights.turn_off(floor, :hall_up)
        Lights.turn_off(floor, :hall_down)

        {:reply, :ok, state}
    end

    @impl true
    def handle_call({:calculate_cost, hall_order}, from, state) do
        IO.inspect("-----------------------------------------")
        IO.write("I am calculating cost for order: ")
        IO.inspect(hall_order)
        IO.write("From: ")
        IO.inspect(from)

        cost = Cost.calculate_cost_for_order(hall_order)
        {:reply, cost, state}
    end






    def find_node_with_lowest_cost(order) do
        # This is obtuse when calling with timeout =/= infty
        my_cost = {Node.self, Cost.calculate_cost_for_order(order)}
        {replies, bad_nodes} = GenServer.multi_call(Node.list, Peer, {:calculate_cost, order}, Constants.peer_wait_for_response)
        all_costs = [my_cost | replies]
        {node_with_lowest_cost, _lowest_cost} = Enum.min_by(all_costs, fn {_node, cost} -> cost end)
        node_with_lowest_cost
    end

    def accept_order(order) do
        IO.write("I am accepting order ")
        IO.inspect(order)

        :ok = Queue.add_order(order)
        
        {floor, order_type, _order_here} = order
        Lights.turn_on(floor, order_type)

        DriverFSM.notify_queue_updated(order)   # change this to a call and repeat until reply?
    end

    def notify_orders_served(floor) do
        {replies, bad_nodes} = GenServer.multi_call(Node.list, Peer, {:orders_served, floor}, Constants.peer_wait_for_response)
        :ok
    end




    @impl true
    def handle_info(:ping_now, state) do
        IO.inspect("Received ping-request")
        ping_later

        if able_to_ping_any? do
            # if state == :single_elevator, do: request_state
            IO.inspect("Got response!")
            {:noreply, :ptp_elevator}
        else
            IO.inspect("No response!")
            {:noreply, :single_elevator}
        end
    end
    def ping_later do
        IO.inspect("Calling pinger")
        Process.send_after(self(), :ping_now, 2000)# Constants.ping_wait_time_ms)
    end

    def able_to_ping_any? do
        all_other_nodes_names = list_all_node_names_except([RuntimeConstants.get_elev_number])
        Enum.any?(all_other_nodes_names, fn node_name -> Node.ping(node_name) == :pong end)
    end
    def able_to_ping_any_or_all? do # Bad! Implement as multicall to :ping
    all_other_nodes_names = list_all_node_names_except([RuntimeConstants.get_elev_number])

    [Enum.any?(all_other_nodes_names, fn name -> Node.ping(name) == :pong end),
    Enum.all?(all_other_nodes_names, fn name -> Node.ping(name) == :pong end)]
    end




    # Helper function

    def elev_number_to_node_name(elev_number) do
        String.to_atom("elevator" <> to_string(elev_number) <> "@" <> Constants.get_elevator_ip_string) # Her er pinging en by-effect -> BAD
    end

    # Call with list_of_elev_numbers_exceptions = [] to list all node names
    def list_all_node_names_except(list_of_elev_numbers_exceptions) do
        all_other_nodes_numbers = Enum.to_list(Constants.all_elevators_range) -- list_of_elev_numbers_exceptions
        all_other_nodes_names = Enum.map(all_other_nodes_numbers, &elev_number_to_node_name/1)
    end
end