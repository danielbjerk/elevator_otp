defmodule ElevatorOTP do
  @moduledoc """
  Elevator-control and fault-handling software, heavily relying on Elixir programming principles like fail fast and the OTP-framework.
  
  Start program by running simulator and then running ElevatorOTP.start
  """

  def start(elev_number, driver_port \\ 15657, debug \\ true) do
    ElevatorOTP.Application.start(:type, [elev_number, driver_port, debug])
  end
end
