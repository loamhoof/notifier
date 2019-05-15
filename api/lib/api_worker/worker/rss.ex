defmodule ApiWorker.Worker.RSS do
  use ApiWorker.Worker

  @impl true
  def run(%{"feed" => feed} = config) do
    case Scrape.feed(feed) do
      {:error, reason} ->
        {:error, inspect(reason)}

      {:ok, %{items: []}} ->
        {:error, "empty feed"}

      {:ok, %{items: items}} ->
        filters = Map.get(config, "filters", [])

        case find(items, filters) do
          nil ->
            :nothing

          item ->
            {:ok, item |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end)}
        end
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

  @impl true
  def to_bullet(task_name, _config, %{"title" => title, "article_url" => article_url}) do
    {:ok, {task_name, title, article_url}}
  end

  @impl true
  def to_bullet(_, _, _) do
    {:error, "missing `title` or `article_url`"}
  end
end
