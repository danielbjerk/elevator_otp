defmodule Pinger do#Bør linkes til Peer
    use Task
    
    def start_link(_args) do
        Task.start_link(__MODULE__, :find_peers, [])
        Task.start_link(__MODULE__, :ping_peers, [])
    end
    def ping_later do
        IO.inspect("Calling pinger")
        Process.send_after(self(), :ping_now, Constants.ping_wait_time_ms)
    end



    def find_peers do   # Denne funksjonen er stor og ekkel
        if RuntimeConstants.debug?, do: Debug.print_debug(:opening_socket, [])

        my_elev_number = RuntimeConstants.get_elev_number
        port = Constants.elev_number_to_peer_pinger_port(my_elev_number)
        {:ok, socket} = :gen_udp.open(port, Constants.peer_pinger_opts)
        
        broadcast_my_elev_number_to_all_ports(my_elev_number, socket)
        
        case :gen_udp.recv(socket, 0) do #Timeout? Hva hjelper det isåfall? jo stopper deadlock hvor alle bare venter på at andre skal bc-e
            {:ok, {ip, _port, elev_num_bin}} ->
                elev_num = :binary.decode_unsigned(elev_num_bin)
                
                if RuntimeConstants.debug?, do: Debug.print_debug(:received_udp_msg, elev_num)

                potential_peer_name = elev_number_and_ip_to_node_name(elev_num, ip)

                if potential_peer_name not in [Node.self | Node.list] do
                    case Node.ping(potential_peer_name) do
                        :pong -> :ok
                            Peer.new_peer_found(potential_peer_name)
                        :pang -> :ok
                    end
                end
            _timeout ->
                :fuck
        end
        
        if RuntimeConstants.debug?, do: Debug.print_debug(:closing_socket, [])
        :gen_udp.close(socket)

        Process.sleep(Constants.find_peer_wait_time_ms)
        find_peers
    end



    def ping_peers do
        if RuntimeConstants.debug?, do: Debug.print_debug(:ping_peers_now, [])
        
        IO.write("My peers are")
        IO.inspect(Node.list)

        response = Enum.map(Node.list, fn node_name -># Mye side-effects av map-kallet her nå
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



    # Helper functions

    def elev_number_and_ip_to_node_name(elev_num, ip) do
        String.to_atom("elevator" <> to_string(elev_num) <> "@" <> Enum.join(Tuple.to_list(ip), "."))
    end

    def broadcast_my_elev_number_to_all_ports(my_elev_number, socket) do    # Bør vi heller bc-e node.self?
        Enum.each(Enum.to_list(Constants.all_elevators_range) -- [my_elev_number], fn elev_number ->
            :gen_udp.send(socket, 
            {255, 255, 255, 255}, 
            Constants.elev_number_to_peer_pinger_port(elev_number),
            RuntimeConstants.get_elev_number) end)
    end
end