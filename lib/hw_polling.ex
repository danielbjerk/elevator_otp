defmodule HWPolling do
  use GenServer

  @moduledoc """
  Server for receiving button-presses and floor updates and forewarding these to the correct module. Also acts as the supervisor for all 3*n buttons.
  """


  defp link_floor_sensor(pid_recipient) do
    {:ok, _pid_button} = HWSensor.start_link(pid_recipient, :floor_sensor, :not_a_floor)
  end

  defp link_all_buttons(_pid_recipient, _button_type -1) do
    :ok
  end
  defp link_all_buttons(pid_recipient, button_type, this_floor) do
    {:ok, _pid_button} = HWSensor.start_link(pid_recipient, button_type, this_floor)
    link_all_buttons(pid_recipient, this_floor)
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
      if new_state !== last_state, do: send(pid_recipient, {:stop_button, {:stop_button, new_state}})
      state_change_reporter(pid_recipient, :stop_button, :not_a_floor, new_state)
  end

  def state_change_reporter(pid_recipient, :floor_sensor, _floor, last_state) do
    new_state = Driver.get_floor_sensor_state
    if new_state !== last_state, do: send(pid_recipient, {:floor_sensor, new_state})
    state_change_reporter(pid_recipient, :floor_sensor, :not_a_floor, new_state)
  end

  def state_change_reporter(pid_recipient, at_button_type, floor, last_state) do
      new_state = Driver.get_order_button_state(floor, at_button_type)
      if new_state !== last_state, do: send(pid_recipient, {:hw_button, {at_button_type, floor, new_state}})
      state_change_reporter(pid_recipient, at_button_type, floor, new_state)
  end
end
