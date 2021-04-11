defmodule ElevatorOTP do
  @moduledoc """
  Documentation for ElevatorOTP.
  """

  def start(elev_number) do
    ElevatorOTP.Application.start(:type, [elev_number, :arg2])
  end
end
