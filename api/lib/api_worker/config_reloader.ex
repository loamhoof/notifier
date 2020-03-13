defmodule ApiWorker.ConfigReloader do
  @typep task_name() :: String.t()
  @typep task_names() :: list(task_name())

  use GenServer

  alias Api.{Repo, Task}

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## GenServer Callbacks

  @impl true
  def init(:ok) do
    send(self(), :update)

    {:ok, nil}
  end

  defp loop(), do: Process.send_after(self(), :update, 5_000)

  @impl true
  def handle_info(:update, nil) do
    curr_tasks = ApiWorker.WorkerRegistry.which_workers(ApiWorker.WorkerRegistry)
    new_tasks = get_new_tasks()

    curr_names = curr_tasks |> Map.keys() |> MapSet.new()
    new_names = new_tasks |> Map.keys() |> MapSet.new()

    removed_names = curr_names |> MapSet.difference(new_names) |> MapSet.to_list()
    added_names = new_names |> MapSet.difference(curr_names) |> MapSet.to_list()
    updated_names = get_updated_tasks_names(curr_names, new_names, curr_tasks, new_tasks)

    kill(removed_names ++ updated_names)
    new(new_tasks, added_names ++ updated_names)

    loop()

    {:noreply, nil, :hibernate}
  end

  ## Helpers

  @spec get_new_tasks() :: %{optional(task_name()) => %Task{}}
  defp get_new_tasks() do
    Task
    |> Repo.all()
    |> Stream.map(&{&1.name, &1})
    |> Map.new()
  end

  @spec get_updated_tasks_names(
          MapSet.t(task_name()),
          MapSet.t(task_name()),
          %{optional(task_name()) => NaiveDateTime.t()},
          %{optional(task_name()) => %Task{}}
        ) :: task_names()
  defp get_updated_tasks_names(curr_names, new_names, curr_tasks, new_tasks) do
    curr_names
    |> MapSet.intersection(new_names)
    |> Enum.filter(
      &(:lt ==
          NaiveDateTime.compare(
            Map.get(curr_tasks, &1),
            Map.get(new_tasks, &1).updated_at
          ))
    )
  end

  @spec kill(task_names()) :: nil
  defp kill(names) do
    for name <- names do
      ApiWorker.WorkerRegistry.kill(ApiWorker.WorkerRegistry, name)
    end

    nil
  end

  @spec new(%{optional(task_name()) => %Task{}}, task_names()) :: nil
  defp new(new_tasks, names) do
    for name <- names do
      %Task{type: type, config: config, updated_at: version} = Map.get(new_tasks, name)
      ApiWorker.WorkerRegistry.new(ApiWorker.WorkerRegistry, name, version, type, config)
    end

    nil
  end
end
