defmodule Api.Repo.Migrations.AlterTasksDropTypeEnum do
  use Ecto.Migration

  def change do
    drop constraint(:tasks, :task_type_enum)
  end
end
