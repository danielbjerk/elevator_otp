defmodule ElevatorOTP.Application do
  @moduledoc false

  use Application

  def start(_type, [elev_number, driver_port, debug]) do
    children = [
      {RuntimeConstants, [elev_number, debug]},
      {Driver, [{127,0,0,1}, driver_port]},
      RepeatingTimeout,
      Queue,
      {BackupQueue, elev_number},
      Position,
      HWUpdateServer,
      HWPoller.Supervisor,
      Actuator,
      DriverFSM,
      {OrderDistribution, elev_number},
      Pinger
    ]

    opts = [strategy: :one_for_one, name: ElevatorOTP.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
