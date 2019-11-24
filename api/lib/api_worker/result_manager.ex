defmodule ApiWorker.ResultManager do
  use GenServer

  import Ecto.Query, only: [from: 2]
  require Logger

  alias Api.{Repo, Task, Task.Result}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Client API

  def push(server, task_name, body, url) do
    GenServer.cast(server, {:push, task_name, body, url})
  end

  ## Defining GenServer Callbacks

  @impl true
  def init(:ok), do: {:ok, nil}

  @impl true
  def handle_cast({:push, task_name, body, url}, nil) do
    task_id =
      Repo.one(
        from t in Task,
          select: t.id,
          where: [name: ^task_name]
      )

    if is_nil(task_id) do
      Logger.warn("Could not find task #{task_name}")
    else
      new_result = %Result{
        task_id: task_id,
        body: body,
        url: url
      }

      last_result =
        Repo.one(
          from Result,
            where: [task_id: ^task_id],
            order_by: [desc: :id],
            limit: 1
        )

      unless !is_nil(last_result) && new_result.body == last_result.body &&
               new_result.url == last_result.url do
        Repo.insert(new_result)
      end
    end

    {:noreply, nil}
  end
end
