defmodule ApiWorker.ResultManager do
  @type last_result() ::
          {body :: String.t(), url :: String.t(), acked_at :: DateTime.t(), acked_with :: term()}

  use GenServer

  import Ecto.Query, only: [from: 2]
  require Logger

  alias Api.{Repo, Task, Task.Result}

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Client API

  @spec last_result(GenServer.server(), String.t()) :: last_result()
  def last_result(server, task_name) do
    GenServer.call(server, {:last_result, task_name})
  end

  @spec push(GenServer.server(), String.t(), String.t(), String.t()) :: :ok
  def push(server, task_name, body, url) do
    GenServer.cast(server, {:push, task_name, body, url})
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
          select: {r.body, r.url, r.acked_at, r.acked_with},
          where: t.name == ^task_name,
          order_by: [desc: r.id],
          limit: 1
      )

    decoded_last_result =
      if is_nil(last_result) do
        nil
      else
        update_in(last_result, [Access.elem(3)], fn
          nil -> nil
          encoded_json -> Jason.decode!(encoded_json)
        end)
      end

    {:reply, decoded_last_result, state}
  end

  @impl true
  def handle_cast({:push, task_name, body, url}, state) do
    save_result(task_name, body, url)

    {:noreply, state}
  end

  defp save_result(task_name, body, url) do
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
        url: url
      }

      Repo.insert(result)
    end
  end
end
