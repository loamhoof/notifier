defmodule Api.Repo.Migrations.AlterTaskResultsRemoveToAckNotifyAt do
  use Ecto.Migration

  def change do
    alter table(:task_results) do
      remove :to_ack
      remove :notify_at
    end
  end
end
