defmodule Api.Repo.Migrations.Helpers do
  def in_constraint(values) do
    values
    |> Stream.map(&"'#{&1}'")
    |> Enum.join(",")
    |> (&"type IN (#{&1})").()
  end
end
