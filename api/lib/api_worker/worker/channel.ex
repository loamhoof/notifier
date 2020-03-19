defmodule ApiWorker.Worker.Channel do
  @behaviour ApiWorker.Worker

  @impl true
  def run(_config, nil), do: {:ok, "Channel opened.", ""}
  def run(_config, {_body, _url, nil, nil}), do: :nothing
  def run(_config, {_body, _url, _acked_at, message}), do: {:ok, message, ""}
end
