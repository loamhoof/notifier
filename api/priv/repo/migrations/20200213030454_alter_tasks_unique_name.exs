defmodule Api.Repo.Migrations.AlterTasksUniqueName do
  use Ecto.Migration

  def change do
    create unique_index(:tasks, :name)
  end
end
