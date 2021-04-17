defmodule Constants do

  # Elevators

  def number_of_elevators, do: 3
  def all_elevators_range, do: 0..(number_of_elevators - 1)



  # Floors

  def bottom_floor, do: 0
  def top_floor, do: 3
  def all_floors_range, do: bottom_floor..top_floor


  # Network

#  def elev_number_to_ip(elev_number) do
#    case elev_number do
#      0 -> 10.24.39.22
#      1 -> 10.24.39.22
#      2 -> 10.24.39.22
#    end
#  end

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

  def elev_number_to_peer_pinger_port(elev_number) do
    30000 + elev_number
  end

  def peer_wait_for_response, do: 500

  def peer_pinger_opts, do: [:binary, active: false, reuseaddr: true, broadcast: true]

  def ping_wait_time_ms, do: 2000

  def find_peer_wait_time_ms, do: 5000

  
  # Hardware

  def door_wait_for_obstruction_time_ms, do: 5000

  def hw_sensor_sleep_time, do: 500
end



defmodule RuntimeConstants do
  use Agent

  def start_link(elev_number, debug \\ false) do
    Agent.start_link(fn -> {elev_number, debug} end, name: __MODULE__)
  end

  def get_elev_number do
    Agent.get(__MODULE__, fn {elev_number, _debug} -> elev_number end)
  end

  def debug? do
    Agent.get(__MODULE__, fn {_elev_number, debug} -> debug end)
  end
end