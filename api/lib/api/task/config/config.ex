defmodule Api.Task.Config do
  import Ecto.Changeset, only: [validate_change: 3]

  import Api.Validation, only: [validate: 1]

  def validate_config(changeset, module) do
    validate_change(changeset, :config, fn :config, config ->
      errors = __MODULE__.validate(config) ++ module.validate(config)

      Enum.map(errors, fn {ctx, error} ->
        Enum.join(ctx, ".")
        |> (&String.to_atom("config." <> &1)).()
        |> (&{&1, error}).()
      end)
    end)
  end

  validate do
    list "patches", of: :map do
      elem "field", of: ~w|title body url|
      regex "pattern"
      string "replacement"
    end
  end
end
