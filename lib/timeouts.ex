defmodule Pinger do
    @moduledoc """
    Module for continously checking if expected peers respond, and updating distribution of orders based on this.
    """

    use Task
    

    def start_link(_args) do
        empty_ping_responses = Enum.map(
            Constants.peer_list_all_my_peers, 
            fn node_name -> [node_name, Constants.ping_allowed_missed_pings_num] end
            )
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

        if Enum.any?(List.flatten(new_ping_responses), fn ans_or_name -> ans_or_name < Constants.ping_allowed_missed_pings_num end) do
            OrderDistribution.peers_respond
        else
            OrderDistribution.no_peers_respond   # Network timed out
        end

        Enum.each(new_ping_responses, fn [node_name, missed_pings] ->
           if (rem(missed_pings + 1, 5) == 0), do: OrderDistribution.redistribute_hall_orders_of_node(node_name) # Peer timed out
        end)

        Process.sleep(Constants.ping_wait_time_ms)
        ping_peers(new_ping_responses)
    end
end



defmodule RepeatingTimeout do
    @moduledoc """
    Module for implementing function-calls which are reapeated regularly before being cancelled.
    """

    use GenServer


    # Starting

    def start_link(_opts) do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    @impl true
    def init(_inital_value) do
        {:ok, %{}}
    end


    # Wrappers/Interface

    def start_timer(id, timeout_every_ms, action_on_timeout) do
        GenServer.call(__MODULE__, {:start_timer, id, timeout_every_ms, action_on_timeout})
    end
    def stop_timer(id) do
        GenServer.call(__MODULE__, {:stop_timer, id})
    end
    def get_time(id) do
        GenServer.call(__MODULE__, {:get_time, id})
    end


    # Callbacks

    @impl true
    def handle_call({:start_timer, id, timeout_every_ms, action_on_timeout}, _from, active_timers) do
        if RuntimeConstants.debug?, do: Debug.print_debug(:starting_timer, id)

        new_active_timers = Map.put_new(active_timers, id, %{duration: timeout_every_ms, action: action_on_timeout, timeouts: 0})
        Process.send_after(self, {:timeout, id}, timeout_every_ms)
        {:reply, :ok, new_active_timers}
    end

    @impl true
    def handle_call({:stop_timer, id}, _from, active_timers) do
        if RuntimeConstants.debug?, do: Debug.print_debug(:stopping_timer, id)

        {_timer_info, new_active_timers} = Map.pop(active_timers, id)
        {:reply, :stopped, new_active_timers}
    end
    
    @impl true
    def handle_call({:get_time, id}, _from, active_timers) do
        if Map.has_key?(active_timers, id) do
            timer_info = active_timers[id]
            timeout_every_ms = timer_info[:duration]
            amount_of_timeouts = timer_info[:timeouts]
            time = timeout_every_ms * amount_of_timeouts
            {:reply, time, active_timers}
        else
            {:reply, 0, active_timers}
        end
    end

    @impl true
    def handle_info({:timeout, id}, active_timers) do
        if Map.has_key?(active_timers, id) do
            if RuntimeConstants.debug?, do: Debug.print_debug(:timer_timedout, id)

            timer_info = active_timers[id]

            {module, function_at, arguments} = timer_info[:action]
            Task.start(module, function_at, arguments)
            
            new_active_timers = Map.update!(active_timers, id, fn _timer -> Map.update!(timer_info, :timeouts, fn t -> t + 1 end) end)

            timeout_every_ms = timer_info[:duration]
            Process.send_after(self, {:timeout, id}, timeout_every_ms)

            {:noreply, new_active_timers}
        else
            {:noreply, active_timers}
        end
    end
end