defmodule Api.Task.Config.Reminder do
  @behaviour Api.Task.Config

  @impl true
  def validate_config(changeset, config) do
    changeset
    |> Api.Task.Config.validate_duration(config, "interval")
    |> Api.Task.Config.validate_binary(config, "description")
  end
end
