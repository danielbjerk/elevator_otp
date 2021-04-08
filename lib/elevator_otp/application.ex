defmodule ElevatorOTP.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _elevator_num) do
    children = [
      Driver,
      Queue,
      Position,
      HWUpdateReceiver,
      HWPoller.Supervisor,
      Actuator,
      DriverFSM
      
      # Starts a worker by calling: ElevatorOtp.Worker.start_link(arg)
      # {ElevatorOtp.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElevatorOTP.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
