defmodule Constants do
  def number_of_elevators, do: 3

  def number_of_floors, do: 3

  def get_elevator_ip_string do # This is not really constant
    {:ok, ip_info} = :inet.getif
    case Enum.at(ip_info,0) do  # This should not be an enum.at
      {my_ip, _router, {255, 255, _255_or_252, 0}} -> Enum.join(Tuple.to_list(my_ip), ".")
      {:error, _error_msg} -> :failed_to_get_ip
    end
  end

  def elev_number_to_driver_port(elev_number) do
    15657 + elev_number
  end

  def peer_wait_for_response, do: 5000

  def door_wait_for_obstruction_time_ms, do: 5000

  def hw_sensor_sleep_time, do: 100

  def driver_wait_loop_sleep_time, do: 100

  def ping_wait_time_ms, do: 1000
end



defmodule RuntimeConstants do
  use Agent

  def start_link(elev_number) do
    Agent.start_link(fn -> elev_number end, name: __MODULE__)
  end

  def get_elev_number do
    Agent.get(__MODULE__, & &1)
  end
end