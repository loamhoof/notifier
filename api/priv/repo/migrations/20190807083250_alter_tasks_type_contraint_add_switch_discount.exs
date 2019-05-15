defmodule Api.Repo.Migrations.AlterTasksTypeConstraintAddSwitchDiscount do
  use Ecto.Migration

  import Api.Repo.Migrations.Helpers, only: [in_constraint: 1]

  @types ~w|rss switch_discount|

  def change do
    drop constraint(:tasks, :task_type_enum)
    create constraint(:tasks, :task_type_enum, check: in_constraint(@types))
  end
end
