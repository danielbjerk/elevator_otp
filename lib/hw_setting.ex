defmodule Actuator do
  @moduledoc """
  Server for controlling door and motor, especially ensuring the door is never open when the motor is commanded to move.
  """

  use GenServer

  
  # Starting

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_args) do
    Driver.set_door_open_light(:off)
    {:ok, :door_closed}
  end


  # Wrappers/Interface

  def change_direction(new_direction) do
    GenServer.cast(__MODULE__, {:change_direction, new_direction})
    Position.update(new_direction)
  end

  def open_door do
    GenServer.cast(__MODULE__, {:open_door})
  end


  # Callbacks

  @impl true
  def handle_cast({:change_direction, direction}, _driver_state) do
    Motor.change_direction(direction)
    {:noreply, :driving}
  end

  @impl true
  def handle_cast({:open_door}, _driver_state) do
    Door.door_open_wait_until_closing
    {:noreply, :door_closed}
  end
end



defmodule Door do
  @moduledoc """
  Opens door, and closes it after door_wait_for_obstruction_time_ms as long as obstruction isn't active.
  """

  def door_open_wait_until_closing() do
    door_open()

    Process.sleep(Constants.door_wait_for_obstruction_time_ms)
    :door_free_to_close = door_wait_until_free_to_close()

    door_close()
  end



  defp door_open() do
    # Should be calls to light, but door is implemented as just a light
    Driver.set_door_open_light(:on)
  end

  defp door_close() do
    Driver.set_door_open_light(:off)
  end

  defp door_wait_until_free_to_close() do
    case Driver.get_obstruction_switch_state() do
      :active ->
        door_wait_until_free_to_close()

      :inactive ->
        :door_free_to_close
    end

  end

end



defmodule Motor do
  def change_direction(motor_direction) do
    Driver.set_motor_direction(motor_direction)
  end
end



defmodule Lights do
  # Small wrapper around Driver.
  
  def turn_on(floor, order_type) do
    Driver.set_order_button_light(order_type, floor, :on)
  end

  def turn_off(floor, order_type) do
    Driver.set_order_button_light(order_type, floor, :off)
  end

  def turn_off_all_at_floor(floor) do
    turn_off(floor, :hall_up)
    turn_off(floor, :hall_down)
    turn_off(floor, :cab)
  end

  def turn_off_all do
    Enum.each(Constants.all_floors_range, fn floor -> turn_off_all_at_floor(floor) end)
  end

  def change_floor_indicator(floor) do
    Driver.set_floor_indicator(floor)
  end
end
