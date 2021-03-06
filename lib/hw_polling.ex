defmodule HWUpdateServer do
  @moduledoc """
  Server for receiving button-presses and floor updates and forewarding these to the correct module.
  """

  use GenServer


  # Start

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    {:ok, :receiving}
  end


  # Wrapper/Interface

  def notify_update(sensor_change) do
    GenServer.cast(__MODULE__, sensor_change)
  end


  # Callbacks

  @impl true
  def handle_cast({:stop_button, _new_state}, _state) do
    # Do more?
    {:noreply, :stop_updated}
  end

  @impl true
  def handle_cast({:floor_sensor, new_state}, _state) do
    Position.update(new_state)
    {:noreply, :floor_updated}
  end

  @impl true
  def handle_cast({at_button_type, floor, 1}, _state) do
    Task.start(OrderDistribution, :distribute_order, [{floor, at_button_type, :order}])
    {:noreply, :order_received}
  end

  @impl true
  def handle_cast({_at_button_, _floor, 0}, _state) do
    {:noreply, :order_button_low}
  end
end



defmodule HWPoller.Supervisor do
  
  use Supervisor

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = list_child_spec_of_all_buttons
    
    Supervisor.init(children, strategy: :one_for_one)
  end



  defp list_child_spec_of_all_buttons do
    hall_up_buttons = create_child_spec_of_button(:hall_up)
    hall_down_buttons = create_child_spec_of_button(:hall_down)
    cab_buttons = create_child_spec_of_button(:cab)

    floor_sensor = [%{id: :floor_sensor_reporter, start: {HWPoller, :start_link, [:floor_sensor, :not_a_floor]}}]

    hall_up_buttons ++ hall_down_buttons ++ cab_buttons ++ floor_sensor # ++ stop_button
  end

  defp create_child_spec_of_button(at_button_type) do
    Enum.map(Constants.all_floors_range,
    fn floor -> %{
      id: String.to_atom(
        Atom.to_string(at_button_type) <> "_floor_" <> Integer.to_string(floor)
        ),
      start: {HWPoller, :start_link, [at_button_type, floor]}
      }
    end)
  end
end



defmodule HWPoller do
  @moduledoc """
  Module for converting generalized polling of hardware to specific interrupts.
  """

  use Task

  def start_link(at_sensor_type, floor) do
    Task.start_link(__MODULE__, :state_change_reporter, [at_sensor_type, floor, :init])
  end



  def state_change_reporter(:stop_button, _floor, last_state) do
    new_state = Driver.get_stop_button_state
    if new_state !== last_state, do: HWUpdateServer.notify_update({:stop_button, new_state})

    Process.sleep(Constants.hw_sensor_sleep_time_ms)
    state_change_reporter(:stop_button, :not_a_floor, new_state)
  end


  def state_change_reporter(:floor_sensor, _floor, last_state) do
    new_state = Driver.get_floor_sensor_state
    if new_state !== last_state, do: HWUpdateServer.notify_update({:floor_sensor, new_state})

    Process.sleep(Constants.hw_sensor_sleep_time_ms)
    state_change_reporter(:floor_sensor, :not_a_floor, new_state)
  end


  # Use this for order buttons (at_button_type is either :hall_up, :hall_down or :cab)
  def state_change_reporter(at_button_type, floor, last_state) do
    new_state = Driver.get_order_button_state(floor, at_button_type)
    if new_state !== last_state, do: HWUpdateServer.notify_update({at_button_type, floor, new_state})

    Process.sleep(Constants.hw_sensor_sleep_time_ms)
    state_change_reporter(at_button_type, floor, new_state)
  end
end
