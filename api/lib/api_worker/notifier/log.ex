defmodule ApiWorker.Notifier.Log do
  @behaviour ApiWorker.Notifier

  require Logger

  @impl true
  def init(), do: {:ok, nil}

  @impl true
  def push(nil, notif) do
    Logger.info(Enum.join(["notif:"] ++ Tuple.to_list(notif), " "))

    :ok
  end
end
