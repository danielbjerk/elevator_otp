defmodule ElevatorOTP do
  @moduledoc """
  Documentation for ElevatorOTP.
  """

  def start(elev_number, debug \\ true) do
    ElevatorOTP.Application.start(:type, [elev_number, debug])
  end
end
