defmodule ApiWorker.NotificationSender do
  require Logger

  use GenServer

  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query, only: [from: 2]

  alias Api.{Repo, Task, Task.Result}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    with {:mode?, {:ok, mode}} <- {:mode?, Application.fetch_env(:api, :notification_mode)},
         {:module?, {:ok, module}} <- {:module?, ApiWorker.Notifier.fetch_module(mode)},
         {:init?, {:ok, config}} <- {:init?, module.init()} do
      send(self(), :notify)
      {:ok, {module, config}}
    else
      {:mode?, :error} -> {:stop, "config :notification_mode is not set"}
      {:module?, :error} -> {:stop, "unknown notification mode"}
      {:init?, {:error, reason}} -> {:stop, reason}
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
      notif = {task.name, result.body, result.url}
      patches = Map.get(task.config, "patches", [])

      sent =
        ApiWorker.Notification.apply_patches(patches, notif)
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
end
