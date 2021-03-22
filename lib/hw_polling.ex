defmodule HWPolling do
  @moduledoc """
  Server for receiving button-presses and floor updates and forewarding these to the correct module. Also acts as the supervisor for all 3*n buttons.
  The state of the server is the last update it has recevied.
  """

  use GenServer


  # Client-side

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end


  # Server-side

  @impl true
  def init(_init_arg) do
    {:ok, :receiving}
  end

  def notify_update({at_button_type, update}) do
    GenServer.cast(__MODULE__, {at_button_type, update})
  end


  # Callbacks

  @impl true
  def handle_cast({:stop_button, new_state}, _state) do
    # Do more?
    {:noreply, :stop_updated}
  end

  @impl true
  def handle_cast({:floor_sensor, new_state}, _state) do
    Position.update(new_state)
    {:noreply, :floor_updated}
  end

  @impl true
  def handle_cast({:cab, floor, 1}, _state) do
    Queue.add_order({floor, :cab, :order})
    # Turn on light here?
    {:noreply, :order_received}
  end

  @impl true
  def handle_cast({at_button_type, floor, 1}, _state) do
    # Send to server here
    {:noreply, :order_received}
  end

  @impl true
  def handle_cast({_at_button_, _floor, 0}, _state) do
    {:noreply, :order_button_low}
  end
end



defmodule HWSensor.Supervisor do
  
  use Supervisor

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {HWSensor, [:floor_sensor, :not_a_floor]},
      {HWSensor, [:hall_up, Constants.number_of_floors]},
      {HWSensor, [:hall_down, Constants.number_of_floors]},
      {HWSensor, [:cab, Constants.number_of_floors]}
    ]
    
    Supervisor.init(children, strategy: :one_for_one)
  end
end



defmodule HWSensor do
  @moduledoc """
  Module for implementing "interrupts" from the elevator into elixir in the form of standardized messages
  """

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, opts},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end


  def start_link(at_sensor_type, :not_a_floor) do
    Task.start_link(__MODULE__, :state_change_reporter, [at_sensor_type, :not_a_floor, :init])
  end

  def start_link(_at_button_type, -1) do
    :ok
  end
  def start_link(at_button_type, this_floor) do
    Task.start_link(__MODULE__, :state_change_reporter, [at_button_type, this_floor, :init])
    start_link(at_button_type, this_floor - 1)
  end



  def state_change_reporter(:stop_button, _floor, last_state) do
    new_state = Driver.get_stop_button_state
    if new_state !== last_state, do: HWPolling.notify_update({:stop_button, new_state})

    # Recursion
    Process.sleep(Constants.hw_sensor_sleep_time)
    state_change_reporter(:stop_button, :not_a_floor, new_state)
  end


  def state_change_reporter(:floor_sensor, _floor, last_state) do
    new_state = Driver.get_floor_sensor_state
    if new_state !== last_state, do: HWPolling.notify_update({:floor_sensor, new_state})

    # Recursion
    Process.sleep(Constants.hw_sensor_sleep_time)
    state_change_reporter(:floor_sensor, :not_a_floor, new_state)
  end


  # Use this for order buttons (at_button_type is either :hall_up, :hall_down or :cab)
  def state_change_reporter(at_button_type, floor, last_state) do
    new_state = Driver.get_order_button_state(floor, at_button_type)
    if new_state !== last_state, do: HWPolling.notify_update({at_button_type, floor, new_state})

    # Recursion
    Process.sleep(Constants.hw_sensor_sleep_time)
    state_change_reporter(at_button_type, floor, new_state)
  end
end
