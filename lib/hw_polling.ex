defmodule HWPolling.Superviser do
  @moduledoc """

  """

  use Supervisor

  def start_link() do # Hit??
    link_floor_sensor(__MODULE__)
    link_all_buttons(__MODULE__, :hall_up, Constants.number_of_floors)
    link_all_buttons(__MODULE__, :hall_down, Constants.number_of_floors)
    link_all_buttons(__MODULE__, :cab, Constants.number_of_floors)
    HWPolling.start_link()
  end
end

defmodule HWPolling do
  @moduledoc """
  Server for receiving button-presses and floor updates and forewarding these to the correct module. Also acts as the supervisor for all 3*n buttons.
  The state of the server is the last update it has recevied.
  """

  use GenServer

  # Client-side

  def start_link() do   # Options?
    GenServer.start_link(__MODULE__)
  end

  def notify_update(pid_recipient, update) do
    Genserver.cast(pid_recipient, update)
  end

  # Server-side

  defp link_floor_sensor(pid_recipient) do
    {:ok, _pid_button} = HWSensor.start_link(pid_recipient, :floor_sensor, :not_a_floor)
  end

  defp link_all_buttons(_pid_recipient, _button_type, -1) do
    :ok
  end
  defp link_all_buttons(pid_recipient, button_type, this_floor) do
    {:ok, _pid_button} = HWSensor.start_link(pid_recipient, button_type, this_floor)
    link_all_buttons(pid_recipient, button_type, this_floor - 1)
  end

  @impl true
  def init do
    """
    link_floor_sensor(__MODULE__)
    link_all_buttons(__MODULE__, :hall_up, Constants.number_of_floors)
    link_all_buttons(__MODULE__, :hall_down, Constants.number_of_floors)
    link_all_buttons(__MODULE__, :cab, Constants.number_of_floors)
    """
    {:ok, :receiving}
  end

  # Callbacks

  @impl true
  def handle_cast({:stop_button, new_state}, _state) do
    {:noreply, :stop_updated}
  end

  @impl true
  def handle_cast({:floor_sensor, new_state}, _state) do
    Position.update(new_state)
    {:noreply, :floor_updated}
  end

  @impl true
  def handle_cast({:cab, floor, :on}, _state) do
    Queue.add_order({floor, :cab, :order})
    # Turn on light here?
    {:noreply, :order_received}
  end

  @impl true
  def handle_cast({at_button_type, floor, :on}, _state) do
    # Send to server here
    {:noreply, :order_received}
  end

  @impl true
  def handle_cast({_at_button_, _floor, :off}, _state) do
    {:noreply, :order_button_low}
  end
end



defmodule HWSensor do
  @moduledoc """
  Module for implementing "interrupts" from the elevator into elixir in the form of standardized messages
  """

  def start_link(pid_recipient, at_sensor_type, floor) do
    Task.start_link(__MODULE__, :state_change_reporter, [pid_recipient, at_sensor_type, floor, :init])
  end

  def state_change_reporter(pid_recipient, :stop_button, _floor, last_state) do
    new_state = Driver.get_stop_button_state
    if new_state !== last_state, do: HWPolling.notify_update(pid_recipient, {:stop_button, new_state})

    # Recursion
    Process.sleep(Constants.hw_sensor_sleep_time)
    state_change_reporter(pid_recipient, :stop_button, :not_a_floor, new_state)
  end

  def state_change_reporter(pid_recipient, :floor_sensor, _floor, last_state) do
    new_state = Driver.get_floor_sensor_state
    if new_state !== last_state, do: HWPolling.notify_update(pid_recipient, {:floor_sensor, new_state})

    # Recursion
    Process.sleep(Constants.hw_sensor_sleep_time)
    state_change_reporter(pid_recipient, :floor_sensor, :not_a_floor, new_state)
  end


  # Use this for order buttons (at_button_type is either :hall_up, :hall_down or :cab)
  def state_change_reporter(pid_recipient, at_button_type, floor, last_state) do
    new_state = Driver.get_order_button_state(floor, at_button_type)
    if new_state !== last_state, do: HWPolling.notify_update(pid_recipient, {at_button_type, floor, new_state})

    # Recursion
    Process.sleep(Constants.hw_sensor_sleep_time)
    state_change_reporter(pid_recipient, at_button_type, floor, new_state)
  end
end
