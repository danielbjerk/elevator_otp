defmodule ResetableTimer do

    use GenServer

    def wait_time() do
        10_000
    end

    def start_link() do
        GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    end

    def reset_timer() do
        GenServer.call(__MODULE__, :reset_timer)
    end

    def init(_state) do
        timer = Process.send_after(self(), :work, wait_time())
        {:ok, %{timer: timer}}
    end

    def handle_call(:reset_timer, _from, %{timer: timer}) do
        :timer.cancel(timer)
        timer = Process.send_after(self(), :work, wait_time())
        {:reply, :ok, %{timer: timer}}
    end

    def handle_info(:work, _state) do
    IO.puts("TIMER EXPIRED")
    timer = Process.send_after(self(), :work, wait_time())

    {:noreply, %{timer: timer}}
    end

    def handle_info(_, state) do
        {:ok, state}
    end

end