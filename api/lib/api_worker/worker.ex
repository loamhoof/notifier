defmodule ApiWorker.Worker do
  @typep on_run() ::
           :nothing
           | {:ok, body :: String.t(), url :: String.t()}
           | {:error, reason :: String.t()}

  @callback run(
              config :: map(),
              last_result ::
                nil
                | ApiWorker.ResultManager.last_result()
            ) :: on_run()

  require Logger

  use GenServer, restart: :transient

  alias ApiWorker.ResultManager

  @spec start_link({String.t(), {String.t(), NaiveDateTime.t(), map()}}) :: GenServer.on_start()
  def start_link({task_type, init_state}) do
    GenServer.start_link(__MODULE__, {task_type, init_state})
  end

  ## Client API

  @spec whoareyou(GenServer.server()) :: {String.t(), NaiveDateTime.t()}
  def whoareyou(server) do
    GenServer.call(server, :info)
  end

  @spec ack(GenServer.server(), DateTime.t(), term()) :: :ok
  def ack(server, acked_at, acked_with) do
    GenServer.cast(server, {:ack, acked_at, acked_with})
  end

  @spec unack(GenServer.server()) :: :ok
  def unack(server) do
    GenServer.cast(server, :unack)
  end

  ## GenServer Callbacks

  @impl true
  def init({task_type, {task_name, _, _}} = init_state) do
    module =
      case task_type do
        "rss" -> ApiWorker.Worker.RSS
        "switch_discount" -> ApiWorker.Worker.SwitchDiscount
        "reminder" -> ApiWorker.Worker.Reminder
      end

    Logger.debug("Start #{task_name}")

    {:ok, put_elem(init_state, 0, module), {:continue, nil}}
  end

  defp loop(interval), do: Process.send_after(self(), :check, interval)

  @impl true
  def handle_continue(nil, {_, {task_name, _, _}} = init_state) do
    last_result = ApiWorker.WorkerRegistry.register(ApiWorker.WorkerRegistry, task_name)

    send(self(), :check)

    {:noreply, Tuple.append(init_state, last_result)}
  end

  @impl true
  def handle_call(:info, _from, {_, {task_name, version, _}, _} = state) do
    {:reply, {task_name, version}, state, :hibernate}
  end

  @impl true
  def handle_cast({:ack, acked_at, acked_with}, {_, _, last_result} = state) do
    new_last_result =
      last_result
      |> put_elem(2, acked_at)
      |> put_elem(3, acked_with)

    {:noreply, put_elem(state, 2, new_last_result), :hibernate}
  end

  @impl true
  def handle_cast(:unack, {_, _, last_result} = state) do
    new_last_result = put_elem(last_result, 2, nil)

    {:noreply, put_elem(state, 2, new_last_result), :hibernate}
  end

  @impl true
  def handle_info(:check, {module, {task_name, _, config}, last_result} = state) do
    new_last_result =
      case module.run(config, last_result) do
        # send to load processor
        {:ok, body, url} ->
          ResultManager.push(ApiWorker.ResultManager, task_name, body, url)
          {body, url, nil, nil}

        {:error, reason} ->
          Logger.warn(reason)
          last_result

        :nothing ->
          last_result
      end

    loop(5_000)

    {:noreply, put_elem(state, 2, new_last_result), :hibernate}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warn("Unexpected message: #{inspect(msg)}")
    {:noreply, state, :hibernate}
  end

  @impl true
  def terminate(_reason, {_, {task_name, _, _}, _}) do
    Logger.debug("Stop #{task_name}")

    :shutdown
  end

  ## Helpers

  @spec if_diff(on_run(), ResultManager.last_result()) ::
          on_run()
  def if_diff(notif, nil), do: notif

  def if_diff(notif, {last_body, last_url, _, _}) do
    case notif do
      {:ok, new_body, new_url} when {new_body, new_url} == {last_body, last_url} ->
        :nothing

      anything ->
        anything
    end
  end
end
