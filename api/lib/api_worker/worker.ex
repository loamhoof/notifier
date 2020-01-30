defmodule ApiWorker.Worker do
  @callback run(
              config :: map(),
              last_result ::
                nil | {body :: String.t(), url :: String.t(), acked_at :: DateTime.t()}
            ) ::
              :nothing
              | {:ok, body :: String.t(), url :: String.t()}
              | {:ok, body :: String.t(), url :: String.t(),
                 [notify_at: DateTime.t(), to_ack: boolean()]}
              | {:error, reason :: String.t()}

  require Logger

  use GenServer, restart: :transient

  def start_link({task_type, init_state}) do
    GenServer.start_link(__MODULE__, {task_type, init_state})
  end

  ## Client API

  def whoareyou(server) do
    GenServer.call(server, :info)
  end

  def ack(server, acked_at) do
    GenServer.cast(server, {:ack, acked_at})
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
  def handle_cast({:ack, acked_at}, {_, _, last_result} = state) do
    new_last_result = put_elem(last_result, 2, acked_at)

    {:noreply, put_elem(state, 2, new_last_result)}
  end

  @impl true
  def handle_info(:check, {module, {task_name, _, config}, last_result} = state) do
    new_last_result =
      case module.run(config, last_result) do
        # send to load processor
        {:ok, body, url} ->
          ApiWorker.ResultManager.push(ApiWorker.ResultManager, task_name, body, url)
          {body, url, nil}

        {:ok, body, url, opts} ->
          ApiWorker.ResultManager.push(
            ApiWorker.ResultManager,
            task_name,
            body,
            url,
            opts
          )

          {body, url, nil}

        {:error, reason} ->
          Logger.warn(reason)
          last_result

        :nothing ->
          last_result
      end

    loop(Map.get(config, "interval"))

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

  def if_diff(notif, nil), do: notif

  def if_diff(notif, {last_body, last_url, _}) do
    case notif do
      {:ok, new_body, new_url} when {new_body, new_url} == {last_body, last_url} ->
        :nothing

      anything ->
        anything
    end
  end
end
