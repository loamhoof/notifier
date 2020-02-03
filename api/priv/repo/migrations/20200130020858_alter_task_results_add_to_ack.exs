defmodule Api.Repo.Migrations.AlterTaskResultsAddToAck do
  use Ecto.Migration

  def change do
    alter table(:task_results) do
      add :to_ack, :boolean, default: false, null: false
    end
  end
end
