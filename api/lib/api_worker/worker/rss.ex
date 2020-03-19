defmodule ApiWorker.Worker.RSS do
  @behaviour ApiWorker.Worker

  import ApiWorker.Worker, only: [if_diff: 2]

  @impl true
  def run(%{"feed" => feed} = config, last_result) do
    filters = Map.get(config, "filters", [])

    with {:ok, %{items: items}} <- Scrape.feed(feed),
         item when not is_nil(item) <- find(items, filters) do
      item
      |> to_notif()
      |> if_diff(last_result)
    else
      nil -> :nothing
      {:ok, %{items: []}} -> {:error, "empty feed"}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  defp find(items, filters) do
    Enum.find(items, fn item -> Enum.all?(filters, &apply_filter(item, &1)) end)
  end

  defp apply_filter(item, %{"field" => field, "pattern" => pattern}) do
    title = Map.get(item, :title, "")
    regex = Regex.compile!(pattern)

    case field do
      "title" -> Regex.match?(regex, title)
    end
  end

  defp to_notif(%{title: title, article_url: article_url}) do
    if String.starts_with?(article_url, "http") do
      {:ok, title, article_url}
    else
      {:ok, title, ""}
    end
  end

  defp to_notif(_feed_item) do
    {:error, "missing `title` or `article_url`"}
  end
end
