defmodule BioMonitor do
  use Application
  @moduledoc"""
    Starting point for the application.
  """
  alias BioMonitor.Endpoint
  alias BioMonitor.SensorManager

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(BioMonitor.Repo, []),
      supervisor(BioMonitor.Endpoint, []),
      worker(BioMonitor.SerialMonitor, [[name: SensorManager.arduino_gs_id()]]),
      worker(BioMonitor.RoutineMonitor, []),
    ]

    opts = [strategy: :one_for_one, name: BioMonitor.Supervisor]
    BioMonitor.StateContainer.start_link()
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
