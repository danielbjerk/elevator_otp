defmodule ElevatorOTP do
  @moduledoc """
  Documentation for ElevatorOTP.
  """

  def start(elev_number) do
    #Constants.set_elev_number(elev_number)

    ElevatorOTP.Application.start(:arg1, :arg2)
  end
end
