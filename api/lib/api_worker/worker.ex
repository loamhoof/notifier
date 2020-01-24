defmodule ApiWorker.Worker do
  @callback run(
              config :: map(),
              last_result ::
                nil | {body :: String.t(), url :: String.t(), acked_at :: DateTime.t()}
            ) ::
              :nothing
              | {:ok, body :: String.t(), url :: String.t()}
              | {:ok, body :: String.t(), url :: String.t(), notify_at :: DateTime.t()}
              | {:error, reason :: String.t()}

  ## Client API

  def whoareyou(server) do
    GenServer.call(server, :info)
  end

  def ack(server, acked_at) do
    GenServer.cast(server, {:ack, acked_at})
  end

  defmacro __using__(_) do
    quote do
      use GenServer, restart: :transient

      require Logger

      @behaviour ApiWorker.Worker

      def start_link(init_state) do
        GenServer.start_link(__MODULE__, init_state)
      end

      ## GenServer Callbacks

      @impl true
      def init({task_name, _, _} = init_state) do
        Logger.debug("Start #{task_name}")

        {:ok, init_state, {:continue, nil}}
      end

      defp loop(interval), do: Process.send_after(self(), :check, interval)

      @impl true
      def handle_continue(nil, {task_name, _, _} = init_state) do
        last_result = ApiWorker.WorkerRegistry.register(ApiWorker.WorkerRegistry, task_name)

        send(self(), :check)

        {:noreply, {init_state, last_result}}
      end

      @impl true
      def handle_call(:info, _from, {{task_name, version, _}, _} = state) do
        {:reply, {task_name, version}, state, :hibernate}
      end

      @impl true
      def handle_cast({:ack, acked_at}, {task_info, last_result}) do
        new_last_result = put_elem(last_result, 2, acked_at)

        {:noreply, {task_info, new_last_result}}
      end

      @impl true
      def handle_info(:check, {{task_name, _, config}, last_result} = state) do
        new_last_result =
          case run(config, last_result) do
            # send to load processor
            {:ok, body, url} ->
              ApiWorker.ResultManager.push(ApiWorker.ResultManager, task_name, body, url)
              {body, url, nil}

            {:ok, body, url, notify_at} ->
              ApiWorker.ResultManager.push(
                ApiWorker.ResultManager,
                task_name,
                body,
                url,
                notify_at
              )

              {body, url, nil}

            {:error, reason} ->
              Logger.warn(reason)
              last_result

            :nothing ->
              last_result
          end

        loop(Map.get(config, "interval"))

        {:noreply, put_elem(state, 1, new_last_result), :hibernate}
      end

      @impl true
      def terminate(_reason, {{task_name, _, _}, _}) do
        Logger.debug("Stop #{task_name}")

        :shutdown
      end

      @impl true
      def handle_info(msg, state) do
        Logger.warn("Unexpected message: #{inspect(msg)}")
        {:noreply, state, :hibernate}
      end

      ## Helpers

      defp if_diff(notif, nil), do: notif

      defp if_diff(notif, {last_body, last_url, _}) do
        case notif do
          {:ok, new_body, new_url} ->
            if new_body == last_body and new_url == last_url do
              :nothing
            else
              {:ok, new_body, new_url}
            end

          anything ->
            anything
        end
      end
    end
  end
end
