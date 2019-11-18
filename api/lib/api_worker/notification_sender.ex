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
          where: r.sent == false and r.error == false
      )

    for {task, result} <- results do
      module = ApiWorker.WorkerRegistry.which_module(task.type)

      with {:ok, bullet} <- module.to_bullet(task.name, task.config, result.load),
           {title, body, url} <- apply_patches(task.config, bullet),
           :ok <- apply(__MODULE__, String.to_atom("notify_#{mode}"), [title, body, url]) do
        change(result, %{sent: true})
        |> Repo.update()
      else
        {:error, reason} ->
          Logger.warn("could not send bullet [#{task.name} / #{result.id}]: #{inspect(reason)}")

          change(result, %{error: true, error_reason: inspect(reason)})
          |> Repo.update()

        anything ->
          Logger.warn(
            "could not send bullet, will retry later [#{task.name} / #{result.id}]: #{
              inspect(anything)
            }"
          )
      end
    end

    loop()

    {:noreply, state}
  end

  def notify_log(title, body, url) do
    Logger.info(Enum.join(["bullet", title, body, url], " "))

    :ok
  end

  def notify_bullet(title, body, url) do
    case ApiWorker.Pushbullet.push(title, body, url) do
      {:ok, %{status_code: status_code}} when div(status_code, 100) == 2 ->
        :ok

      {:ok, %{status_code: status_code}} ->
        {:error, "unexpected status code when notifying: #{status_code}"}

      anything ->
        {:error, "error when notifying: #{inspect(anything)}"}
    end
  end

  defp apply_patches(config, bullet) do
    Map.get(config, "patches", [])
    |> Enum.reduce(bullet, &apply_patch(&1, &2))
  end

  defp apply_patch(
         %{"field" => field, "pattern" => pattern, "replacement" => replacement},
         {title, body, url}
       ) do
    regex = Regex.compile!(pattern)

    case field do
      "title" -> {Regex.replace(regex, title, replacement), body, url}
      "body" -> {title, Regex.replace(regex, body, replacement), url}
      "link" -> {title, body, Regex.replace(regex, url, replacement)}
    end
  end
end
