defmodule Constants do
  #def set_elev_number(elev_number) do
  #  @const_elev_number elev_number
  #end
  def get_elev_number do
    1
  end
  
  def number_of_floors, do: 3

  def door_wait_for_obstruction_time_ms, do: 5000

  def hw_sensor_sleep_time, do: 100

  def driver_wait_loop_sleep_time, do: 100

  def ping_wait_time_ms, do: 1000
end
