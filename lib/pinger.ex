defmodule Pinger do#Bør linkes til Peer
    use Task
    
    def start_link(_args) do
        Task.start_link(__MODULE__, :ping_peers, [])
    end



    def ping_peers do
        if RuntimeConstants.debug?, do: Debug.print_debug(:ping_peers_now, [])
        
        IO.write("My peers are")
        IO.inspect(Node.list)

        response = Enum.map(Peer.list_all_node_names_except([RuntimeConstants.get_elev_number]), fn node_name -># Mye side-effects av map-kallet her nå
            case Node.ping(node_name) do
                :pang ->
                    # if more pangs from this elev_num than allowed, (how to store??) take hall calls self (and mark as dead?)
                    :pang
                :pong ->
                    :pong
            end
        end)
        
        IO.write("Result from pinging peers: ")
        IO.inspect(response)
        if not (:pong in response) do
            Peer.no_peers_respond
        else    # This bad
            Peer.new_peer_found(Enum.at(Node.list, 0))
        end

        Process.sleep(Constants.ping_wait_time_ms)
        ping_peers
    end
end