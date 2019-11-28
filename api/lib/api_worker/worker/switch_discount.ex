defmodule ApiWorker.Worker.SwitchDiscount do
  use ApiWorker.Worker

  @impl true
  def run(%{"country" => country, "id" => id, "link" => link}) do
    url = "https://api.ec.nintendo.com/v1/price?country=#{country}&lang=en&ids=#{id}"

    with {:ok, body} <- get(url),
         {:ok, body} <- Jason.decode(body) do
      to_notif(body, link)
    else
      {:error, reason} -> {:error, reason}
      anything -> {:error, "unexpected error: #{inspect(anything)}"}
    end
  end

  defp get(url) do
    case HTTPoison.get(url) do
      {:ok, %{body: body, status_code: 200}} -> {:ok, body}
      {:ok, resp} -> {:error, "error contacting Nintendo's API: #{inspect(resp)}}"}
      {:error, error} -> {:error, inspect(error)}
    end
  end

  defp to_notif(%{"prices" => [prices]}, link) do
    unless Map.has_key?(prices, "discount_price") do
      :nothing
    else
      case extract(prices) do
        :error ->
          {:error, "unexpected prices body: #{inspect(prices)}"}

        {:ok, regular_value, discount_value, from, to} ->
          case make_notif_body(regular_value, discount_value, from, to) do
            {:ok, notif_body} -> {:ok, notif_body, link}
            {:error, reason} -> {:error, "unexpected error: #{inspect(reason)}"}
          end
      end
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
      regular_value = String.to_float(regular_value)
      discount_value = String.to_float(discount_value)
      discount = :erlang.float_to_binary((1 - discount_value / regular_value) * 100, decimals: 0)
      message = "#{discount_value} (-#{discount}%) from #{from} to #{to}"
      {:ok, message}
    else
      anything -> {:error, "unexpected error: #{inspect(anything)}"}
    end
  end
end

# {"personalized":false,"country":"JP","prices":[{"title_id":70010000016519,"sales_status":"onsale","regular_price":{"amount":"3,500円","currency":"JPY","raw_value":"3500"},"discount_price":{"amount":"2,800円","currency":"JPY","raw_value":"2800","start_datetime":"2019-11-10T15:00:00Z","end_datetime":"2019-12-04T14:59:59Z"}}]}
