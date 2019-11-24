defmodule ApiWorker.NotificationSender do
  use GenServer

  require Logger

  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query, only: [from: 2]

  alias Api.{Repo, Task, Task.Result}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    mode =
      case Application.fetch_env(:api, :notification_mode) do
        :error -> :log
        {:ok, mode} -> mode
      end

    unless mode in [:log, :bullet] do
      error_reason = "invalid notification_mode: #{inspect(mode)}"
      Logger.error(error_reason)

      {:stop, error_reason}
    else
      send(self(), :notify)

      {:ok, %{mode: mode}}
    end
  end

  defp loop(), do: Process.send_after(self(), :notify, 5000)

  @impl true
  def handle_info(:notify, state = %{mode: mode}) do
    results =
      Repo.all(
        from r in Result,
          join: t in Task,
          on: r.task_id == t.id,
          select: {t, r},
          where: r.sent == false
      )

    for {task, result} <- results do
      notif = {task.name, result.body, result.url}
      patches = Map.get(task.config, "patches", [])

      sent =
        ApiWorker.Notification.apply_patches(patches, notif)
        |> notify(mode)

      case sent do
        :ok ->
          now = DateTime.utc_now() |> DateTime.truncate(:second)

          change(result, %{sent: true, sent_at: now})
          |> Repo.update()

        {:error, reason} ->
          Logger.warn("could not send bullet [#{task.name} / #{result.id}]: #{inspect(reason)}")
      end
    end

    loop()

    {:noreply, state, :hibernate}
  end

  @spec notify(ApiWorker.Notification.t(), atom) :: :ok | {:error, iodata}
  defp notify(notif, mode) do
    apply(__MODULE__, String.to_atom("notify_#{mode}"), [notif])
  end

  def notify_log(notif) do
    Logger.info(Enum.join(["notif:"] ++ Tuple.to_list(notif), " "))

    :ok
  end

  def notify_bullet(notif) do
    case ApiWorker.Pushbullet.push(notif) do
      {:ok, %{status_code: status_code}} when div(status_code, 100) == 2 ->
        :ok

      {:ok, %{status_code: status_code}} ->
        {:error, "unexpected status code when notifying: #{status_code}"}

      anything ->
        {:error, "error when notifying: #{inspect(anything)}"}
    end
  end
end
