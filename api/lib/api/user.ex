defmodule Api.User do
  use Ecto.Schema
  import Ecto.Changeset
  @derive {Jason.Encoder, only: [:id, :name, :is_admin, :inserted_at, :updated_at]}

  schema "users" do
    field :name, :string
    field :password, :string, virtual: true
    field :password_hash, :string, source: :password
    field :is_admin, :boolean, default: false

    timestamps()
  end

  def create_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, [:name, :password, :is_admin])
    |> validate_required([:name, :password])
    |> put_pass_hash()
  end

  def update_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, [:name, :password, :is_admin])
    |> validate_required([:name])
    |> put_pass_hash()
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        change(changeset, Argon2.add_hash(password))

      _ ->
        changeset
    end
  end
end
