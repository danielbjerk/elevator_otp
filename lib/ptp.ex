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
        # Starte pinger
        Task.start(Peer, :ping_later, [])
        

        # Initiere containers?


        # Starte node
        my_name = elev_number_to_node_name(elev_number)   # Change
        Node.start(my_name, :longnames, 15000)
        Node.set_cookie(:safari)


        # Koble opp m/ andre heiser
        case able_to_ping_any_or_all?(elev_number) do
            [true, true] -> 
                # Request min kø (i tilfelle jeg nettopp har vært dau)
                {:ok, :ptp_elevator}
            [true, false] -> 
                # Do something?
                {:ok, :ptp_elevator}
            #[false, true] -> {:error, :something_very_wrong}
            [false, _bool] -> {:ok, :single_elevator}
        end
    end



    def distribute_hall_call(hall_order) do
        # This is obtuse when calling with timeout =/= infty
        {replies, bad_nodes} = GenServer.multi_call([Node.self | Node.list], Peer, {:calculate_cost, hall_order}, Constants.peer_wait_for_response)
        |> IO.inspect

        {node_to_handle_order, _largest_cost} = Enum.min_by(replies, fn {_node, cost} -> cost end)

        Node.spawn(node_to_handle_order, Peer, :take_order, [hall_order])
        node_to_handle_order
    end

    @impl true
    def handle_call({:calculate_cost, hall_order}, _from, state) do
        cost = Cost.calculate_cost_for_order(hall_order)
        {:reply, cost, state}
    end

    def take_order(hall_order) do
        Queue.add_order(hall_order)
        {floor, order_type, :order} = hall_order
        Lights.turn_on(floor, order_type)
    end


    @impl true
    def handle_info(:ping, state) do
        IO.inspect("Received ping")
        Task.start(Peer, :ping_later, [])
        IO.inspect("Pinging other nodes")
        
        # ping network/nodes
        case able_to_ping_any_or_all?(RuntimeConstants.get_elev_number) do   # replace w/ multicall to :alive?
            [true, true] -> 
                # Request min kø (i tilfelle jeg nettopp har vært dau)
                {:noreply, :ptp_elevator}
            [true, false] -> 
                # Do something?
                {:noreply, :ptp_elevator}
            #[false, true] -> {:error, :something_very_wrong}
            [false, _bool] -> {:noreply, :single_elevator}
        end
        # if pong after downtime then request updatesping_later.?
    end
    def ping_later do
        IO.inspect("calling pinger")
        Process.send_after(self(), :ping, Constants.ping_wait_time_ms)
    end



    def elev_number_to_node_name(elev_number) do #Men bør ikke elev_number lagres i Constants? I tilfelle den skal aksesseres igjen senere?
        String.to_atom("elevator" <> to_string(elev_number) <> "@" <> Constants.get_elevator_ip_string)
    end

    def list_all_node_names_except() do
        all_other_nodes_numbers = Enum.to_list(1..Constants.number_of_elevators)
        all_other_nodes_names = Enum.map(all_other_nodes_numbers, &elev_number_to_node_name/1)
    end
    def list_all_node_names_except(list_of_elev_numbers) do
        all_other_nodes_numbers = Enum.to_list(1..Constants.number_of_elevators) -- list_of_elev_numbers
        all_other_nodes_names = Enum.map(all_other_nodes_numbers, &elev_number_to_node_name/1)
    end

    def able_to_ping_any_or_all?(my_elev_number) do
        all_other_nodes_names = list_all_node_names_except([my_elev_number])

        [Enum.any?(all_other_nodes_names, fn name -> Node.ping(name) == :pong end),
        Enum.all?(all_other_nodes_names, fn name -> Node.ping(name) == :pong end)]
    end
end



defmodule CostFunction do
    def calculate_cost(order) do
        # calculate here

        :rand.uniform(10)        
    end
end