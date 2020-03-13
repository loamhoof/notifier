defmodule ApiWorker.EventManager do
  use GenServer

  import Ecto.Query, only: [from: 2]

  alias Api.{Repo, Task}

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Client API

  @spec ack(GenServer.server(), pos_integer(), DateTime.t()) :: :ok
  def ack(server, task_id, acked_at) do
    GenServer.cast(server, {:ack, task_id, acked_at})
  end

  @spec unack(GenServer.server(), pos_integer()) :: :ok
  def unack(server, task_id) do
    GenServer.cast(server, {:unack, task_id})
  end

  ## GenServer Callbacks

  @impl true
  def init(:ok) do
    {:ok, nil}
  end

  @impl true
  def handle_cast({:ack, task_id, acked_at}, state) do
    task_name = task_name_from_task_id(task_id)

    ApiWorker.WorkerRegistry.on_task_ack(ApiWorker.WorkerRegistry, task_name, acked_at)

    {:noreply, state, :hibernate}
  end

  @impl true
  def handle_cast({:unack, task_id}, state) do
    task_name = task_name_from_task_id(task_id)

    ApiWorker.WorkerRegistry.on_task_unack(ApiWorker.WorkerRegistry, task_name)

    {:noreply, state, :hibernate}
  end

  defp task_name_from_task_id(task_id) do
    Repo.one(
      from t in Task,
        select: t.name,
        where: t.id == ^task_id
    )
  end
end
