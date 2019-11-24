defmodule Api.Repo.Migrations.AlterTaskResultsLoad do
  use Ecto.Migration

  def change do
    alter table(:task_results) do
      remove :load
      remove :error
      remove :error_reason
      remove :error_reported

      add :body, :string, default: ""
      add :url, :string, default: ""
      add :sent_at, :utc_datetime
    end
  end
end
