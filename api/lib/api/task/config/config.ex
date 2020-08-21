defmodule Api.Task.Config do
  import Ecto.Changeset, only: [validate_change: 3]

  import Api.Validation, only: [validate: 1]

  @spec validate_config(Ecto.Changeset.t(%Api.Task{}), module()) :: Ecto.Changeset.t(%Api.Task{})
  def validate_config(changeset, module) do
    validate_change(changeset, :config, fn :config, config ->
      errors = __MODULE__.validate(config) ++ module.validate(config)

      Enum.map(errors, fn {ctx, error} ->
        ctx
        |> Enum.join(".")
        |> (&("." <> &1)).()
        |> (&{:config, {error, path: &1}}).()
      end)
    end)
  end

  validate do
    list "patches", of: :map do
      @required ["field", "pattern", "replacement"]

      elem "field", of: ~w|body url|
      regex "pattern"
      string "replacement"
    end
  end
end
