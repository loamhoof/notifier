defmodule Api.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :type, :config, :inserted_at, :updated_at]}

  schema "tasks" do
    field :name, :string
    field :type, :string
    field :config, :map

    timestamps()
  end

  @types ~w|rss switch_discount reminder|

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:name, :type, :config])
    |> validate_required([:name, :type, :config])
    |> unique_constraint(:name)
    |> validate_inclusion(:type, @types)
    |> validate_config()
  end

  defp validate_config(changeset) do
    type = get_field(changeset, :type)

    module =
      case type do
        "rss" -> Api.Task.Config.RSS
        "switch_discount" -> Api.Task.Config.SwitchDiscount
        "reminder" -> Api.Task.Config.Reminder
      end

    Api.Task.Config.validate_config(changeset, module)
  end
end
