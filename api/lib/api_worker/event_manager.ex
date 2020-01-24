defmodule ApiWorker.EventManager do
  use GenServer

  import Ecto.Query, only: [from: 2]

  alias Api.{Repo, Task}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Client API

  def ack(server, task_id, acked_at) do
    GenServer.cast(server, {:ack, task_id, acked_at})
  end

  ## GenServer Callbacks

  @impl true
  def init(:ok) do
    {:ok, nil}
  end

  @impl true
  def handle_cast({:ack, task_id, acked_at}, state) do
    task_name =
      Repo.one(
        from t in Task,
          select: t.name,
          where: t.id == ^task_id
      )

    ApiWorker.WorkerRegistry.on_task_ack(ApiWorker.WorkerRegistry, task_name, acked_at)

    {:noreply, state, :hibernate}
  end
end
