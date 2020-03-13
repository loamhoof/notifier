defmodule ApiWorker.Notifier.FCMLegacy do
  @behaviour ApiWorker.Notifier

  alias ApiWorker.HTTP.FCMLegacy

  @impl true
  def init() do
    with {:key, {:ok, key}} <- {:key, System.fetch_env("FCM_SERVER_KEY")},
         {:token, {:ok, token}} <- {:token, System.fetch_env("FCM_DEVICE_TOKEN")} do
      {:ok, {key, token}}
    else
      {:key, :error} -> {:error, "missing fcm server key (`FCM_SERVER_KEY`)"}
      {:token, :error} -> {:error, "missing fcm device token (`FCM_DEVICE_TOKEN`)"}
    end
  end

  @impl true
  def push(config, notif) do
    case FCMLegacy.push(config, notif) do
      {:ok, %{status_code: status_code}} when div(status_code, 100) == 2 ->
        :ok

      {:ok, %{status_code: status_code}} ->
        {:error, "unexpected status code when notifying: #{status_code}"}

      anything ->
        {:error, "error when notifying: #{inspect(anything)}"}
    end
  end
end
