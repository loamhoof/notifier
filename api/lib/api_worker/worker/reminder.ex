defmodule ApiWorker.Worker.Reminder do
  @behaviour ApiWorker.Worker

  @impl true
  def run(_config, {_, _, nil}), do: :nothing

  @impl true
  def run(%{"description" => description}, nil), do: {:ok, description, ""}

  @impl true
  def run(%{"description" => description, "every" => every}, {_, _, acked_at}) do
    now = DateTime.utc_now()
    next = DateTime.add(acked_at, every)

    case DateTime.compare(now, next) do
      :gt -> {:ok, description, ""}
      _ -> :nothing
    end
  end
end
