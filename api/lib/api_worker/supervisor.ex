defmodule ApiWorker.Supervisor do
  use Supervisor

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {DynamicSupervisor, name: ApiWorker.WorkerSupervisor, strategy: :one_for_one},
      {ApiWorker.WorkerRegistry, name: ApiWorker.WorkerRegistry},
      {ApiWorker.EventManager, name: ApiWorker.EventManager},
      {ApiWorker.ConfigReloader, name: ApiWorker.ConfigReloader},
      {ApiWorker.ResultManager, name: ApiWorker.ResultManager},
      {ApiWorker.Notifier, name: ApiWorker.Notifier}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
