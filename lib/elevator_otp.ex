defmodule ElevatorOTP do
  @moduledoc """
  Documentation for ElevatorOTP.
  """

  def start(elev_number, driver_port \\ 15657, debug \\ true) do
    ElevatorOTP.Application.start(:type, [elev_number, driver_port, debug])
  end
end
