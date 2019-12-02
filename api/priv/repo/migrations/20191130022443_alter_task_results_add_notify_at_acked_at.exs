defmodule Api.Repo.Migrations.AlterTaskResultsAddNotifyAtAckedAt do
  use Ecto.Migration

  def change do
    alter table(:task_results) do
      add :notify_at, :utc_datetime
      add :acked_at, :utc_datetime
    end
  end
end
