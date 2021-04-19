defmodule Pinger do#Bør linkes til Peer
    use Task
    
    def start_link(_args) do
        empty_ping_responses = Enum.map(Peer.list_all_node_names_except([RuntimeConstants.get_elev_number]), fn node_name -> [node_name, 0] end)
        Task.start_link(__MODULE__, :ping_peers, [empty_ping_responses])
    end



    def ping_peers(ping_responses) do
        if RuntimeConstants.debug?, do: Debug.print_debug(:ping_peers_now, [Node.list, ping_responses])

        new_ping_responses = Enum.map(ping_responses, fn [node_name, missed_pings] ->
            case Node.ping(node_name) do
                :pang ->
                    [node_name, missed_pings + 1]
                :pong ->
                    [node_name, 0]
            end
        end)

        if Enum.any?(List.flatten(new_ping_responses), fn ans_or_name -> ans_or_name < 2 end) do
            Peer.peers_respond
        else
            Peer.no_peers_respond
        end

        Enum.each(new_ping_responses, fn [node_name, missed_pings] ->
           if (rem(missed_pings + 1, 5) == 0), do: Peer.redistribute_hall_orders_of_node(node_name)
        end)

        Process.sleep(Constants.ping_wait_time_ms)
        ping_peers(new_ping_responses)
    end
end