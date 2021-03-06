defmodule ApiWorker.WorkerRegistry do
  use GenServer

  alias ApiWorker.ResultManager

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Client API

  @spec which_workers(GenServer.server()) :: %{optional(String.t()) => NaiveDateTime.t()}
  def which_workers(server) do
    GenServer.call(server, :info)
  end

  @spec new(GenServer.server(), String.t(), NaiveDateTime.t(), String.t(), map()) :: :ok
  def new(server, task_name, version, type, config) do
    GenServer.call(server, {:new, task_name, version, type, config})
  end

  @spec kill(GenServer.server(), String.t()) :: :ok
  def kill(server, task_name) do
    GenServer.call(server, {:kill, task_name})
  end

  @spec register(GenServer.server(), String.t()) :: ResultManager.last_result()
  def register(server, task_name) do
    GenServer.call(server, {:register, task_name, self()})
  end

  @spec on_task_ack(GenServer.server(), String.t(), DateTime.t(), term()) :: :ok
  def on_task_ack(server, task_name, acked_at, acked_with) do
    GenServer.cast(server, {:send_ack, task_name, acked_at, acked_with})
  end

  @spec on_task_unack(GenServer.server(), String.t()) :: :ok
  def on_task_unack(server, task_name) do
    GenServer.cast(server, {:send_unack, task_name})
  end

  ## GenServer Callbacks

  @impl true
  def init(:ok) do
    ApiWorker.WorkerSupervisor
    |> Supervisor.which_children()
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
  def handle_call({:new, task_name, version, task_type, config}, _from, workers) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        ApiWorker.WorkerSupervisor,
        {ApiWorker.Worker, {task_type, {task_name, version, config}}}
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
  def handle_call({:register, task_name, pid}, _from, workers) do
    workers = Map.update!(workers, task_name, fn {version, _} -> {version, pid} end)

    last_result = ResultManager.last_result(ApiWorker.ResultManager, task_name)

    {:reply, last_result, workers, 500}
  end

  @impl true
  def handle_cast({:send_ack, task_name, acked_at, acked_with}, workers) do
    worker_info = Map.get(workers, task_name)

    unless is_nil(worker_info) do
      {_, worker_pid} = worker_info

      ApiWorker.Worker.ack(worker_pid, acked_at, acked_with)
    end

    {:noreply, workers, 500}
  end

  @impl true
  def handle_cast({:send_unack, task_name}, workers) do
    worker_info = Map.get(workers, task_name)

    unless is_nil(worker_info) do
      {_, worker_pid} = worker_info

      ApiWorker.Worker.unack(worker_pid)
    end

    {:noreply, workers, 500}
  end

  @impl true
  def handle_info(:timeout, state) do
    {:noreply, state, :hibernate}
  end
end
