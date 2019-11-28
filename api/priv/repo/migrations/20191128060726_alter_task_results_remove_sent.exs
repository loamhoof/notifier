defmodule Api.Repo.Migrations.AlterTaskResultsRemoveSent do
  use Ecto.Migration

  def change do
    alter table(:task_results) do
      remove :sent
    end
  end
end
