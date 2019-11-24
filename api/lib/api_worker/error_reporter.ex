defmodule ApiWorker.ErrorReporter do
  use GenServer

  require Logger

  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query, only: [from: 2]

  alias Api.{Repo, Task.Result}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    loop()

    {:ok, nil}
  end

  defp loop() do
    now = DateTime.utc_now()

    days_remaining = 8 - Calendar.ISO.day_of_week(now.year, now.month, now.day)

    seconds_remaining =
      %{now | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
      |> DateTime.add(days_remaining * 60 * 60 * 24)
      |> DateTime.diff(now)

    Process.send_after(self(), :report, seconds_remaining * 1000)
  end

  @impl true
  def handle_info(:report, nil) do
    Logger.info("TODO: error reporter")

    results =
      Repo.all(
        from r in Result,
          where: r.error == true and r.error_reported == false
      )

    case ApiWorker.Pushbullet.push({"Error Report", "#{length(results)} errors"}) do
      {:ok, %{status_code: status_code}} when div(status_code, 100) == 2 ->
        for result <- results do
          change(result, %{error_reported: true})
          |> Repo.update()
        end

      {:error, reason} ->
        Logger.error("could not send report: #{inspect(reason)}")

      anything ->
        Logger.warn("could not send report: #{inspect(anything)}")
    end

    loop()

    {:noreply, nil, :hibernate}
  end
end
