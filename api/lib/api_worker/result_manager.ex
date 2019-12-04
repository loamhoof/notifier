defmodule ApiWorker.ResultManager do
  use GenServer

  import Ecto.Query, only: [from: 2]
  require Logger

  alias Api.{Repo, Task, Task.Result}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Client API

  def last_result(server, task_name) do
    GenServer.call(server, {:last_result, task_name})
  end

  def push(server, task_name, body, url) do
    notify_at = DateTime.utc_now() |> DateTime.truncate(:second)
    GenServer.cast(server, {:push, task_name, body, url, notify_at})
  end

  def push(server, task_name, body, url, notify_at) do
    GenServer.cast(server, {:push, task_name, body, url, notify_at})
  end

  ## Defining GenServer Callbacks

  @impl true
  def init(:ok), do: {:ok, nil}

  @impl true
  def handle_call({:last_result, task_name}, _from, state) do
    last_result =
      Repo.one(
        from r in Result,
          join: t in Task,
          on: r.task_id == t.id,
          select: {r.body, r.url, r.acked_at},
          where: t.name == ^task_name,
          order_by: [desc: t.id],
          limit: 1
      )

    {:reply, last_result, state}
  end

  @impl true
  def handle_cast({:push, task_name, body, url, notify_at}, state) do
    save_result(task_name, body, url, notify_at)

    {:noreply, state}
  end

  defp save_result(task_name, body, url, notify_at) do
    task_id =
      Repo.one(
        from t in Task,
          select: t.id,
          where: t.name == ^task_name
      )

    if is_nil(task_id) do
      Logger.warn("Could not find task #{task_name}")
    else
      result = %Result{
        task_id: task_id,
        body: body,
        url: url,
        notify_at: notify_at
      }

      Repo.insert(result)
    end
  end
end
