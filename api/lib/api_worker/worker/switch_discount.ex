defmodule ApiWorker.Worker.SwitchDiscount do
  @behaviour ApiWorker.Worker

  import ApiWorker.Worker, only: [if_diff: 2]

  @impl true
  def run(%{"country" => country, "id" => id, "link" => link}, last_result) do
    url = "https://api.ec.nintendo.com/v1/price?country=#{country}&lang=en&ids=#{id}"

    with {:ok, body} <- get(url),
         {:ok, body} <- Jason.decode(body) do
      body
      |> to_notif(link)
      |> if_diff(last_result)
    else
      {:error, reason} -> {:error, "#{inspect(reason)}"}
      anything -> {:error, "unexpected error: #{inspect(anything)}"}
    end
  end

  defp get(url) do
    case HTTPoison.get(url) do
      {:ok, %{body: body, status_code: 200}} -> {:ok, body}
      {:ok, resp} -> {:error, "error contacting Nintendo's API: #{inspect(resp)}}"}
      {:error, error} -> {:error, error}
    end
  end

  defp to_notif(%{"prices" => [prices]}, link) do
    if Map.has_key?(prices, "discount_price") do
      case extract(prices) do
        :error ->
          {:error, "unexpected prices body: #{inspect(prices)}"}

        {:ok, regular_value, discount_value, from, to} ->
          case make_notif_body(regular_value, discount_value, from, to) do
            {:ok, notif_body} -> {:ok, notif_body, link}
            {:error, reason} -> {:error, "unexpected error: #{inspect(reason)}"}
          end
      end
    else
      :nothing
    end
  end

  defp to_notif(body, _link) do
    {:error, "unexpected body: #{inspect(body)}"}
  end

  defp extract(%{
         "regular_price" => %{"raw_value" => regular_value},
         "discount_price" => %{
           "raw_value" => discount_value,
           "start_datetime" => from,
           "end_datetime" => to
         }
       }) do
    {:ok, regular_value, discount_value, from, to}
  end

  defp extract(_prices) do
    :error
  end

  defp make_notif_body(regular_value, discount_value, from, to) do
    with {:ok, from, _} <- DateTime.from_iso8601(from),
         {:ok, to, _} <- DateTime.from_iso8601(to) do
      from = from |> DateTime.to_date() |> Date.to_string()
      to = to |> DateTime.to_date() |> Date.to_string()
      {regular_value, ""} = Float.parse(regular_value)
      {discount_value, ""} = Float.parse(discount_value)
      discount = :erlang.float_to_binary((1 - discount_value / regular_value) * 100, decimals: 0)
      message = "#{discount_value} (-#{discount}%) from #{from} to #{to}"
      {:ok, message}
    else
      anything -> {:error, "unexpected error: #{inspect(anything)}"}
    end
  end
end
