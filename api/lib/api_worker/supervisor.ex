defmodule ApiWorker.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {DynamicSupervisor, name: ApiWorker.WorkerSupervisor, strategy: :one_for_one},
      {ApiWorker.WorkerRegistry, name: ApiWorker.WorkerRegistry},
      {ApiWorker.ConfigReloader, name: ApiWorker.ConfigReloader},
      {ApiWorker.ResultManager, name: ApiWorker.ResultManager},
      {ApiWorker.NotificationSender, name: ApiWorker.NotificationSender}
      # {ApiWorker.ErrorReporter, name: ApiWorker.ErrorReporter}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
