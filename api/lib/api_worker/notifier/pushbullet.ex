defmodule ApiWorker.Notifier.Pushbullet do
  @behaviour ApiWorker.Notifier

  @impl true
  def init() do
    case System.fetch_env("PUSHBULLET_TOKEN") do
      {:ok, token} -> {:ok, token}
      :error -> {:error, "missing pushbullet token (`PUSHBULLET_TOKEN`)"}
    end
  end

  @impl true
  def push(config, notif) do
    case ApiWorker.Pushbullet.push(config, notif) do
      {:ok, %{status_code: status_code}} when div(status_code, 100) == 2 ->
        :ok

      {:ok, %{status_code: status_code}} ->
        {:error, "unexpected status code when notifying: #{status_code}"}

      anything ->
        {:error, "error when notifying: #{inspect(anything)}"}
    end
  end
end
