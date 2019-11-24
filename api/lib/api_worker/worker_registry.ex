defmodule ApiWorker.WorkerRegistry do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Client API

  def which_workers(server) do
    GenServer.call(server, :info)
  end

  def new(server, task_name, version, type, config) do
    GenServer.call(server, {:new, task_name, version, type, config})
  end

  def kill(server, task_name) do
    GenServer.call(server, {:kill, task_name})
  end

  def register(server, task_name) do
    GenServer.cast(server, {:update, task_name, self()})
  end

  def which_module(type) do
    case type do
      "rss" -> ApiWorker.Worker.RSS
      "switch_discount" -> ApiWorker.Worker.SwitchDiscount
    end
  end

  ## Defining GenServer Callbacks

  @impl true
  def init(:ok) do
    Supervisor.which_children(ApiWorker.WorkerSupervisor)
    |> Stream.map(&elem(&1, 1))
    |> Stream.map(&{ApiWorker.Worker.whoareyou(&1), &1})
    |> Stream.map(fn {{task_name, version}, pid} -> {task_name, {version, pid}} end)
    |> Map.new()
    |> (&{:ok, &1}).()
  end

  @impl true
  def handle_call(:info, _from, workers) do
    workers
    |> Stream.map(fn {task_name, {version, _}} -> {task_name, version} end)
    |> Map.new()
    |> (&{:reply, &1, workers}).()
  end

  @impl true
  def handle_call({:new, task_name, version, type, config}, _from, workers) do
    module = which_module(type)

    {:ok, pid} =
      DynamicSupervisor.start_child(
        ApiWorker.WorkerSupervisor,
        {module, {task_name, version, config}}
      )

    workers = Map.put(workers, task_name, {version, pid})

    {:reply, :ok, workers, 500}
  end

  @impl true
  def handle_call({:kill, task_name}, _from, workers) do
    {{_, pid}, workers} = Map.pop(workers, task_name)

    GenServer.stop(pid)

    {:reply, :ok, workers, 500}
  end

  @impl true
  def handle_cast({:update, task_name, pid}, workers) do
    workers = Map.update!(workers, task_name, fn {version, _} -> {version, pid} end)

    {:noreply, workers, 500}
  end

  @impl true
  def handle_info(:timeout, state) do
    {:noreply, state, :hibernate}
  end
end
