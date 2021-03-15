defmodule ElevatorDriver do
  @moduledoc """
  Server for controlling actions of the elevator, driving, stopping and opening of doors.
  """

  use GenServer

  def start_link do # Options?
    GenServer.start_link(__MODULE__)
  end

  @impl true
  def init do
    Actuator.change_direction(:down)
    {:ok, pid} = Task.async(__MODULE__, loop_until_at_a_floor, [])
    Task.await(pid)
  end





  defp loop_until_at_a_floor() do
    Process.sleep(Constants.driver_wait_loop_sleep_time)
    case Position.at_a_floor? do
      false -> loop_until_at_a_floor
      true -> :ok
    end
  end
end
