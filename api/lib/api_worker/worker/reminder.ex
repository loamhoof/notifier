defmodule ApiWorker.Worker.Reminder do
  use ApiWorker.Worker

  @impl true
  def run(%{"description" => description, "every" => every}, last_result) do
    notify_at =
      case last_result do
        {_, _, nil} -> nil
        nil -> DateTime.utc_now() |> DateTime.truncate(:second) |> next(every)
        {_, _, acked_at} -> acked_at |> next(every)
      end

    case notify_at do
      nil -> :nothing
      _ -> {:ok, description, "", notify_at}
    end
  end

  defp next(from, interval) do
    DateTime.add(from, interval)
  end
end
