defmodule ApiWorker.Worker.Reminder do
  @behaviour ApiWorker.Worker

  @impl true
  def run(_config, {_body, _url, nil, nil}), do: :nothing

  @impl true
  def run(%{"description" => description}, nil), do: {:ok, description, ""}

  @impl true
  def run(%{"description" => description, "every" => every}, {_, _, acked_at, _}) do
    now = DateTime.utc_now()
    next = DateTime.add(acked_at, every)

    case DateTime.compare(now, next) do
      :gt -> {:ok, description, ""}
      _eq_lt -> :nothing
    end
  end
end
