defmodule ApiWorker.Worker.SwitchDiscount do
  use ApiWorker.Worker

  @impl true
  def run(%{"country" => country, "id" => id}) do
    url = "https://api.ec.nintendo.com/v1/price?country=#{country}&lang=en&ids=#{id}"

    with {:ok, %{body: body}} <- HTTPoison.get(url),
         {:ok, %{"prices" => [%{"discount_price" => price} | _]}} <- Jason.decode(body) do
      {:ok, price}
    else
      {:ok, _body} -> :nothing
      {:error, reason} -> {:error, inspect(reason)}
      anything -> {:error, "unexpected error: #{inspect(anything)}"}
    end
  end

  @impl true
  def to_bullet(task_name, %{"link" => link}, load) do
    %{"amount" => price, "start_datetime" => from, "end_datetime" => to} = load

    with {:ok, from, _} <- DateTime.from_iso8601(from),
         {:ok, to, _} <- DateTime.from_iso8601(to) do
      from = from |> DateTime.to_date() |> Date.to_string()
      to = to |> DateTime.to_date() |> Date.to_string()
      message = "#{price} from #{from} to #{to}"
      {:ok, {task_name, message, link}}
    else
      anything -> {:error, "unexpected error: #{inspect(anything)}"}
    end
  end

  @impl true
  def to_bullet(_, _, _) do
    {:error, "missing `amount` or `start_datetime` or `end_datetime`"}
  end
end
