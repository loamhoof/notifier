defmodule Api.Repo.Migrations.AlterTaskResultsAddErrorReported do
  use Ecto.Migration

  def change do
    alter table(:task_results) do
      add :error_reported, :boolean, default: false, null: false
    end
  end
end
