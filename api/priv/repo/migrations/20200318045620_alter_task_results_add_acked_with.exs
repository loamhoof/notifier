defmodule Api.Repo.Migrations.AlterTaskResultsAddAckedWith do
  use Ecto.Migration

  alias Api.{Repo, Task.Result}

  def change do
    alter table(:task_results) do
      add :acked_with, :text
    end

    execute(&execute_up/0, fn -> nil end)
  end

  def execute_up do
    Repo.update_all(Result, set: [acked_with: Jason.encode!(nil)])
  end
end
