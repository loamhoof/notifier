defmodule ApiWorker.Notifier do
  @callback init() :: {:ok, config :: any()} | {:error, reason :: String.t()}
  @callback push(config :: any(), ApiWorker.Notification.t()) ::
              :ok | {:error, reason :: String.t()}

  def fetch_module(:log), do: {:ok, ApiWorker.Notifier.Log}
  def fetch_module(:pushbullet), do: {:ok, ApiWorker.Notifier.Pushbullet}
  def fetch_module(:fcm_legacy), do: {:ok, ApiWorker.Notifier.FCMLegacy}
  def fetch_module(_), do: :error
end
