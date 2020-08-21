defmodule ApiWorker.Notifier do
  @typep notif() ::
           {id :: pos_integer(), title :: String.t(), body :: String.t(), url :: String.t()}

  @callback init() :: {:ok, config :: any()} | {:error, reason :: String.t()}
  @callback push(config :: any(), notif()) ::
              :ok | {:error, reason :: String.t()}

  require Logger

  use GenServer

  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query, only: [from: 2]

  alias Api.{Repo, Task, Task.Result}

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## GenServer Callbacks

  @impl true
  def init(:ok) do
    with {:mode?, {:ok, mode}} <- {:mode?, Application.fetch_env(:api, :notification_mode)},
         {:module?, {:ok, module}} <- {:module?, fetch_module(mode)},
         {:init?, {:ok, config}} <- {:init?, module.init()} do
      send(self(), :notify)
      {:ok, {module, config}}
    else
      {:mode?, :error} -> {:stop, "config :notification_mode is not set"}
      {:module?, :error} -> {:stop, "unknown notification mode"}
      {:init?, {:error, reason}} -> {:stop, reason}
    end
  end

  defp fetch_module(mode) do
    case mode do
      :log -> {:ok, ApiWorker.Notifier.Log}
      :pushbullet -> {:ok, ApiWorker.Notifier.Pushbullet}
      :fcm_legacy -> {:ok, ApiWorker.Notifier.FCMLegacy}
      _mode -> :error
    end
  end

  defp loop(), do: Process.send_after(self(), :notify, 5000)

  @impl true
  def handle_info(:notify, {module, config} = state) do
    results =
      Repo.all(
        from r in Result,
          join: t in Task,
          on: r.task_id == t.id,
          select: {t, r},
          where: is_nil(r.sent_at)
      )

    for {task, result} <- results do
      with :ok <- send_notif(task, result, module, config) do
        update_result(task, result)
      end
    end

    loop()

    {:noreply, state, :hibernate}
  end

  ## Helpers

  @spec send_notif(%Task{}, %Result{}, module(), map()) :: :ok | :error
  defp send_notif(task, result, module, config) do
    sent? =
      {result.id, task.name, result.body, result.url}
      |> (&module.push(config, &1)).()

    case sent? do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warn(
          "could not send notification [#{task.name} / #{result.id}]: #{inspect(reason)}"
        )

        :error
    end
  end

  @spec update_result(%Task{}, %Result{}) :: :ok | :error
  defp update_result(task, result) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    updated? =
      result
      |> change(%{sent_at: now})
      |> Repo.update()

    case updated? do
      {:ok, _result} ->
        :ok

      {:error, %{errors: errors}} ->
        Logger.warn("could not update result [#{task.name} / #{result.id}]: #{inspect(errors)}")
    end
  end
end
