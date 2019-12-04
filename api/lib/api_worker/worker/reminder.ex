defmodule ApiWorker.Worker.Reminder do
  use ApiWorker.Worker

  @impl true
  def run(%{"description" => _description}, _last_result) do
    :nothing
  end
end
