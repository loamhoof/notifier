defmodule ApiWorker.Notifier do
  @type notif() ::
          {id :: pos_integer(), title :: String.t(), body :: String.t(), url :: String.t()}
  @type patch() :: %{field: String.t(), pattern: String.t(), replacement: String.t()}

  @callback init() :: {:ok, config :: any()} | {:error, reason :: String.t()}
  @callback push(config :: any(), notif()) ::
              :ok | {:error, reason :: String.t()}

  require Logger

  use GenServer

  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query, only: [from: 2]

  alias Api.{Repo, Task, Task.Result}

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
      _ -> :error
    end
  end

  defp loop(), do: Process.send_after(self(), :notify, 5000)

  @impl true
  def handle_info(:notify, state = {module, config}) do
    results =
      Repo.all(
        from r in Result,
          join: t in Task,
          on: r.task_id == t.id,
          select: {t, r},
          where: is_nil(r.sent_at)
      )

    for {task, result} <- results do
      notif = {result.id, task.name, result.body, result.url}
      patches = Map.get(task.config, "patches", [])

      sent =
        apply_patches(patches, notif)
        |> (&module.push(config, &1)).()

      case sent do
        :ok ->
          now = DateTime.utc_now() |> DateTime.truncate(:second)

          change(result, %{sent_at: now})
          |> Repo.update()

        {:error, reason} ->
          Logger.warn(
            "could not send notification [#{task.name} / #{result.id}]: #{inspect(reason)}"
          )
      end
    end

    loop()

    {:noreply, state, :hibernate}
  end

  ## Helpers

  @spec apply_patches(list(patch()), notif()) :: notif()
  defp apply_patches(patches, notif) do
    Enum.reduce(patches, notif, &apply_patch(&1, &2))
  end

  @spec apply_patch(patch(), notif()) :: notif()
  defp apply_patch(
         %{"field" => field, "pattern" => pattern, "replacement" => replacement},
         notif
       ) do
    regex = Regex.compile!(pattern)

    elem_index =
      case field do
        "title" -> 1
        "body" -> 2
        "url" -> 3
      end

    update_in(notif, [Access.elem(elem_index)], &Regex.replace(regex, &1, replacement))
  end
end
