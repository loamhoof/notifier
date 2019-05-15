defmodule ApiWorker.ResultManager do
  use GenServer

  import Ecto.Query, only: [from: 2]
  require Logger

  alias Api.{Repo, Task, Task.Result}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Client API

  def push(server, task_name, load) do
    GenServer.cast(server, {:push, task_name, load})
  end

  ## Defining GenServer Callbacks

  @impl true
  def init(:ok), do: {:ok, nil}

  @impl true
  def handle_cast({:push, task_name, load}, nil) do
    task_id =
      Repo.one(
        from t in Task,
          select: t.id,
          where: [name: ^task_name]
      )

    case task_id do
      _ when is_nil(task_id) ->
        Logger.warn("Could not find task #{task_name}")

      _ ->
        new_result = %Result{
          task_id: task_id,
          load: load
        }

        last_result =
          Repo.one(
            from Result,
              where: [task_id: ^task_id],
              order_by: [desc: :id],
              limit: 1
          )

        unless !is_nil(last_result) && new_result.load == last_result.load do
          Repo.insert(new_result)
        end
    end

    {:noreply, nil}
  end
end
