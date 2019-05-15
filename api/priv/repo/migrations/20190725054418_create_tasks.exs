defmodule Api.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  import Api.Repo.Migrations.Helpers, only: [in_constraint: 1]

  @types ~w|rss|

  def change do
    create table(:tasks) do
      add :name, :string, null: false
      add :type, :string, null: false
      add :config, :map, null: false

      timestamps()
    end

    create constraint(:tasks, :task_type_enum, check: in_constraint(@types))
  end
end
