defmodule Api.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :type, :config, :inserted_at]}

  schema "tasks" do
    field :name, :string
    field :type, :string
    field :config, :map

    timestamps()
  end

  @types ~w|rss switch_discount|

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:name, :type, :config])
    |> validate_required([:name, :type, :config])
    |> validate_inclusion(:type, @types)
    |> validate_config()
  end

  defp validate_config(changeset) do
    config = get_field(changeset, :config)
    type = get_field(changeset, :type)

    changeset = Api.Task.Config.validate_config(changeset, config)

    case type do
      "rss" -> Api.Task.Config.RSS.validate_config(changeset, config)
      "switch_discount" -> Api.Task.Config.SwitchDiscount.validate_config(changeset, config)
      _ -> changeset
    end
  end
end
