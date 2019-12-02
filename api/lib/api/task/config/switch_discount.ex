defmodule Api.Task.Config.SwitchDiscount do
  @behaviour Api.Task.Config

  @impl true
  def validate_config(changeset, config) do
    changeset
    |> Api.Task.Config.validate_duration(config, "interval")
    |> Api.Task.Config.validate_integer(config, "id")
    |> Api.Task.Config.validate_binary(config, "country")
    |> Api.Task.Config.validate_binary(config, "link")
  end
end
