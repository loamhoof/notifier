defmodule Api.Task.Config do
  @callback validate_config(changeset :: Ecto.Changeset.t(), config :: map()) ::
              Ecto.Changeset.t()

  import Ecto.Changeset, only: [add_error: 3]

  def validate_config(changeset, %{} = config) do
    changeset
    |> validate_patches(config)
  end

  def validate_config(changeset, _) do
    add_error(changeset, :config, "config should be a map")
  end

  defp validate_patches(changeset, config) do
    case Map.fetch(config, "patches") do
      {:ok, patches} -> Enum.reduce(patches, changeset, &validate_patch(&2, &1))
      _ -> changeset
    end
  end

  defp validate_patch(changeset, patch) do
    changeset
    |> validate_binary(patch, "field")
    |> validate_in(patch, "field", ~w|title body url|)
    |> validate_regex(patch, "pattern")
    |> validate_binary(patch, "replacement")
  end

  def validate_interval(changeset, config) do
    case Map.fetch(config, "interval") do
      :error ->
        add_error(changeset, :config, "missing interval")

      {:ok, interval} when not is_integer(interval) ->
        add_error(changeset, :config, "interval should be an integer")

      {:ok, interval} when interval <= 0 ->
        add_error(changeset, :config, "interval should be a positive integer")

      _ ->
        changeset
    end
  end

  def validate_binary(changeset, map, field) do
    case Map.fetch(map, field) do
      :error ->
        add_error(changeset, :config, "missing #{field}")

      {:ok, value} when not is_binary(value) ->
        add_error(changeset, :config, "#{field} should be a string")

      _ ->
        changeset
    end
  end

  def validate_integer(changeset, map, field) do
    case Map.fetch(map, field) do
      :error ->
        add_error(changeset, :config, "missing #{field}")

      {:ok, value} when not is_integer(value) ->
        add_error(changeset, :config, "#{field} should be an integer")

      _ ->
        changeset
    end
  end

  def validate_regex(changeset, map, field) do
    case Map.fetch(map, field) do
      :error ->
        add_error(changeset, :config, "missing #{field}")

      {:ok, value} ->
        case Regex.compile(value) do
          {:error, _} ->
            add_error(changeset, :config, "#{field} should be a regex")

          {:ok, _} ->
            changeset
        end
    end
  end

  def validate_in(changeset, map, field, values) do
    case Map.fetch(map, field) do
      :error ->
        add_error(changeset, :config, "missing #{field}")

      {:ok, value} ->
        if value in values do
          changeset
        else
          add_error(changeset, :config, "#{field} should be one of those #{inspect(values)}")
        end
    end
  end
end
