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

  def push(server, task_name, body, url, opts \\ []) do
    GenServer.cast(server, {:push, task_name, body, url, opts})
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
          order_by: [desc: r.id],
          limit: 1
      )

    {:reply, last_result, state}
  end

  @impl true
  def handle_cast({:push, task_name, body, url, opts}, state) do
    save_result(task_name, body, url, opts)

    {:noreply, state}
  end

  defp save_result(task_name, body, url, opts) do
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
        notify_at:
          Keyword.get(opts, :notify_at, DateTime.utc_now() |> DateTime.truncate(:second)),
        to_ack: Keyword.get(opts, :to_ack, false)
      }

      Repo.insert(result)
    end
  end
end
