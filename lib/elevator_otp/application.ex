defmodule ElevatorOTP.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, [elev_number, _arg2]) do  # Extend args?
    children = [
      {RuntimeConstants, elev_number},
      {Driver, [{127,0,0,1}, Constants.elev_number_to_driver_port(elev_number)]},
      Queue,
      {OrderLogger, elev_number},
      Position,
      HWUpdateReceiver,
      HWPoller.Supervisor,
      Actuator,
      DriverFSM,
      {Peer, elev_number} # recall that start_link with mult. init args must be list
      # Drivers args should be a map for security

      # Starts a worker by calling: ElevatorOtp.Worker.start_link(arg)
      # {ElevatorOtp.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElevatorOTP.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
