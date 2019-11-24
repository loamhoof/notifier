defmodule ApiWorker.ConfigReloader do
  use GenServer

  alias Api.{Repo, Task}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    send(self(), :update)

    {:ok, nil}
  end

  defp loop(), do: Process.send_after(self(), :update, 5_000)

  @impl true
  def handle_info(:update, nil) do
    tasks = ApiWorker.WorkerRegistry.which_workers(ApiWorker.WorkerRegistry)

    new_tasks =
      Repo.all(Task)
      |> Enum.reduce(%{}, &Map.put(&2, &1.name, &1))

    names = Map.keys(tasks) |> MapSet.new()
    new_names = Map.keys(new_tasks) |> MapSet.new()

    removed_names = MapSet.difference(names, new_names) |> MapSet.to_list()
    added_names = MapSet.difference(new_names, names) |> MapSet.to_list()

    updated_names =
      MapSet.intersection(names, new_names)
      |> Enum.filter(
        &(:lt ==
            NaiveDateTime.compare(
              Map.get(tasks, &1),
              Map.get(new_tasks, &1).updated_at
            ))
      )

    for name <- removed_names ++ updated_names do
      ApiWorker.WorkerRegistry.kill(ApiWorker.WorkerRegistry, name)
    end

    for name <- added_names ++ updated_names do
      %Task{type: type, config: config, updated_at: version} = Map.get(new_tasks, name)
      ApiWorker.WorkerRegistry.new(ApiWorker.WorkerRegistry, name, version, type, config)
    end

    loop()

    {:noreply, nil, :hibernate}
  end
end
