defmodule Actuator do
  @moduledoc """
  Server for controlling door and motor.
  """

  use GenServer

  # Client-side

  def start_link() do
  GenServer.start_link(__MODULE__)
  end

  # Task.start_async(Door, :door_open_wait_until_closing)

  # Server-side

  @impl true
  def init do
    :door_closed
  end

  # Callbacks

  @impl true
  def handle_cast({:change_direction, direction}, driver_state) do

  end
end



defmodule Door do
  @moduledoc """
  Opens door, and closes it after door_wait_for_obstruction_time_ms as long as obstruction isn't active.
  Call Door.door_open_wait_until_closing() to do this, man.
  """

  def door_open_wait_until_closing() do
    door_open()

    Process.sleep(Constants.door_wait_for_obstruction_time_ms)
    :door_free_to_close = door_wait_until_free_to_close()

    door_close()
  end

  defp door_open() do
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
  def set_light_state(:door_open, state) do
    {:ok, pid} = Task.start()
  end
end
