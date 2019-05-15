defmodule Api.Repo.Migrations.AlterTaskResultsAddError do
  use Ecto.Migration

  def change do
    alter table(:task_results) do
      add :error, :boolean, default: false, null: false
      add :error_reason, :string
    end
  end
end
