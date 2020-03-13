defmodule Api.Repo.Migrations.Helpers do
  @moduledoc false

  @spec in_constraint(Enumerable.t()) :: String.t()
  def in_constraint(values) do
    values
    |> Stream.map(&"'#{&1}'")
    |> Enum.join(",")
    |> (&"type IN (#{&1})").()
  end
end
