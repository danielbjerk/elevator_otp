defmodule ResetableTimer do
    use GenServer

    def wait_time() do
        10_000
    end

    def start_link(_opts) do
        GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    end

    def reset() do
        IO.puts("Timer reset")
        GenServer.call(__MODULE__, :reset)
    end

    def cancel() do
        IO.puts "Timer cancel"
        GenServer.call(__MODULE__, :cancel)
    end

    def init(_state) do
        timer = Process.send_after(self(), :work, wait_time())
        {:ok, %{timer: timer}}
    end

    def handle_call(:reset, _from, %{timer: timer}) do
        :timer.cancel(timer)
        timer = Process.send_after(self(), :work, wait_time())
        {:reply, :ok, %{timer: timer}}
    end

    def handle_call(:cancel, _from, %{timer: timer}) do
        :timer.cancel(timer)
        {:reply, :ok, %{timer: timer}}
    end

    def handle_info(:work, _state) do
    timer = Process.send_after(self(), :work, wait_time())

    {:noreply, %{timer: timer}}
    end

    def handle_info(_, state) do
        {:ok, state}
    end


end