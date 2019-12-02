defmodule Api.Task.Config.RSS do
  @behaviour Api.Task.Config

  @impl true
  def validate_config(changeset, config) do
    changeset
    |> Api.Task.Config.validate_duration(config, "interval")
    |> Api.Task.Config.validate_binary(config, "feed")
    |> validate_filters(config)
  end

  defp validate_filters(changeset, config) do
    case Map.fetch(config, "filters") do
      {:ok, filters} -> Enum.reduce(filters, changeset, &validate_filter(&2, &1))
      _ -> changeset
    end
  end

  defp validate_filter(changeset, filter) do
    changeset
    |> Api.Task.Config.validate_binary(filter, "field")
    |> Api.Task.Config.validate_in(filter, "field", ~w|title|)
    |> Api.Task.Config.validate_regex(filter, "pattern")
  end
end
