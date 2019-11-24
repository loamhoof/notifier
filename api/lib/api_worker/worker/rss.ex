defmodule ApiWorker.Worker.RSS do
  use ApiWorker.Worker

  @impl true
  def run(%{"feed" => feed} = config) do
    filters = Map.get(config, "filters", [])

    with {:ok, %{items: items}} <- Scrape.feed(feed),
         item when not is_nil(item) <- find(items, filters) do
      to_notif(item)
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

  def to_notif(%{title: title, article_url: article_url}) do
    {:ok, title, article_url}
  end

  def to_notif(_) do
    {:error, "missing `title` or `article_url`"}
  end
end
