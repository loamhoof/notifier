defmodule ApiWorker.Worker.Reminder do
  use ApiWorker.Worker

  @impl true
  def run(%{"description" => description} = config) do
    {:ok, description, ""}
  end
end
