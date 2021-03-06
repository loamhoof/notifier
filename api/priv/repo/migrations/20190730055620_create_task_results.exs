defmodule Api.Repo.Migrations.CreateTaskResults do
  use Ecto.Migration

  def change do
    create table(:task_results) do
      add :load, :map, null: false
      add :sent, :boolean, default: false, null: false
      add :task_id, references(:tasks, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:task_results, [:task_id])
  end
end
