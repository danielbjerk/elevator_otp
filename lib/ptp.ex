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
        # Request min kø (i tilfelle jeg nettopp har vært dau)
        
        # Starte pinger
        spawn fn -> ping_later end
        
        # Initiere containers

        # Starte node
        my_name = elev_number_to_node_name(elev_number)   # Change
        Node.start(my_name, :longnames, 15000)
        Node.set_cookie(:safari)
        #IO.inspect(my_name)
        # Lagre elev_number her? Kun Peer som skal bruke

        # Koble opp m/ andre heiser
        case attempt_to_connect(elev_number) do
            :pong -> {:ok, :ptp_elevator}
            :pang -> {:ok, :single_elevator}
            _else -> {:ok, :something_wrong}
        end
    end



    def handle_hall_call(hall_order) do
        #IO.write("I have recieved: ")
        #IO.inspect(hall_order)

        {replies, bad_nodes} = GenServer.multi_call([Node.self | Node.list], Peer, {:calculate_cost, hall_order}, Constants.peer_wait_for_response)     # Obtuse for timeouts =/= infty

        #IO.write("I have gotten these costs: ")
        #IO.inspect(replies)

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



    def handle_info(:ping, state) do
        # ping network/nodes

        ping_later
        {:noreply, state}
    end
    defp ping_later do
        Process.send_after(self(), :ping, Constants.ping_wait_time_ms)
    end



    def elev_number_to_node_name(elev_number) do #Men bør ikke elev_number lagres i Constants? I tilfelle den skal aksesseres igjen senere?
        String.to_atom("elevator" <> to_string(elev_number) <> "@" <> Constants.elevator_ip_to_string)
    end

    def attempt_to_connect(my_elev_number) do
        Node.ping(elev_number_to_node_name(rem(my_elev_number + 1, Constants.number_of_elevators + 1) + 1))
    end
end



defmodule CostFunction do
    def calculate_cost(order) do
        # calculate here

        :rand.uniform(10)        
    end
end