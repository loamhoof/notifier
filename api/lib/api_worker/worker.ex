defmodule ApiWorker.Worker do
  @callback run(map()) ::
              {:ok, body :: String.t(), url :: String.t()}
              | :nothing
              | {:error, reason :: String.t()}

  ## Client API

  def whoareyou(server) do
    GenServer.call(server, :info)
  end

  defmacro __using__(_) do
    quote do
      use GenServer, restart: :transient

      require Logger

      @behaviour ApiWorker.Worker

      def start_link(init_state) do
        GenServer.start_link(__MODULE__, init_state)
      end

      ## Defining GenServer Callbacks

      @impl true
      def init({task_name, _, config} = state) do
        ApiWorker.WorkerRegistry.register(ApiWorker.WorkerRegistry, task_name)

        Logger.debug("Start #{task_name}")

        send(self(), :check)

        {:ok, state}
      end

      defp loop(interval), do: Process.send_after(self(), :check, interval)

      @impl true
      def handle_call(:info, _from, {task_name, version, _} = state) do
        {:reply, {task_name, version}, state}
      end

      @impl true
      def handle_info(:check, {task_name, _, config} = state) do
        case run(config) do
          # send to load processor
          {:ok, body, url} ->
            ApiWorker.ResultManager.push(ApiWorker.ResultManager, task_name, body, url)

          {:error, reason} ->
            Logger.warn(reason)

          :nothing ->
            nil
        end

        loop(Map.get(config, "interval"))

        {:noreply, state}
      end

      @impl true
      def terminate(_reason, {task_name, _, _}) do
        Logger.debug("Stop #{task_name}")

        :shutdown
      end

      @impl true
      def handle_info(msg, state) do
        Logger.warn("Unexpected message: #{inspect(msg)}")
        {:noreply, state}
      end
    end
  end
end
