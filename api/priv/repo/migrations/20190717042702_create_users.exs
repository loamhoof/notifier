defmodule Api.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :password, :string, null: false
      add :is_admin, :boolean, default: false, null: false

      timestamps()
    end

    create unique_index(:users, [:name])
  end
end
