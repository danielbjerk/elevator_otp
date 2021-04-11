defmodule Peer do
    @moduledoc """
    Module for peer-to-peer-communication between the elevators
    """

    use GenServer

    def start_link(_opts) do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    @impl true
    def init(_init_arg) do
        # Koble opp m/ andre heiser
        # Request min kø (i tilfelle jeg nettopp har vært dau)
        # Starte pinger
        spawn fn -> ping_later end
        # Initiere containers

        {:ok, ip_info} = :inet.getif
        case Enum.at(ip_info,0) do  # This should not be an enum.at
          {my_ip, _router, {255, 255, 252, 0}} -> 
            my_name = String.to_atom("elevator" <> to_string(Constants.get_elev_number) <> "@" <> Enum.join(Tuple.to_list(my_ip), "."))
            Node.start(my_name)
            Node.set_cookie(:safari)

            IO.inspect(my_name)
          error -> 
            :fuck
        end
        {:ok, :start_state}
    end



    def handle_hall_call(hall_order) do
        IO.write("Hello I have recieved: ")
        IO.inspect(hall_order)

        {replies, bad_nodes} = GenServer.multi_call(Peer, {:calculate_cost, hall_order}, 500)

        IO.write("I have gotten these costs: ")
        IO.inspect(replies)

        {node_to_handle_order, _largest_cost} = Enum.min_by(replies, fn {_node, cost} -> cost end)

        Node.spawn(node_to_handle_order, Peer, :take_order, [hall_order])
    end

    @impl true
    def handle_call({:calculate_cost, hall_order}, _from, state) do
        cost = CostFunction.calculate_cost(hall_order)
        {:reply, cost, state}
    end

    def take_order(hall_order) do
        Queue.add_order(hall_order)
        {floor, order_type, :order} = hall_order
        Lights.turn_on(floor, order_type)
    end

    """
    def handle_hall_call(hall_order) do
        broadcast(&receive_hall_call/1, hall_order)
        cost = CostFunction.calculate_cost(hall_order)
        broadcast(&receive_cost/2,[hall_order, cost])
    end
    def receive_hall_call(hall_order) do
        cost = CostFunction.calculate_cost(hall_order)
        broadcast(&receive_cost/2,[hall_order, cost])
    end
    


    defp broadcast(msg_func, args) do
        Enum.each(Node.list, fn peer -> Node.spawn(peer, Peer, msg_func, args) end)
    end
    """


    def handle_info(:ping, state) do
        # ping network/nodes

        ping_later
        {:noreply, state}
    end
    defp ping_later do
        Process.send_after(self(), :ping, Constants.ping_wait_time_ms)
    end
end



defmodule CostFunction do
    def calculate_cost(order) do
        q = Queue.get
        p = Position.get

        # calculate here

        10000000000
    end
end