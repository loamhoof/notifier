defmodule Api.Repo.Migrations.AlterTaskResultsTaskIDNotNullable do
  use Ecto.Migration

  def change do
    alter table(:task_results) do
      modify :task_id, :id, null: false
    end
  end
end
