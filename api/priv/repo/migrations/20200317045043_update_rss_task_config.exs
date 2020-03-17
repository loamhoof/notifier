defmodule Api.Repo.Migrations.UpdateRSSTaskConfig do
  use Ecto.Migration

  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query, only: [from: 2]

  alias Api.{Repo, Task}

  def up do
    update_config_id(&Integer.to_string(&1))
  end

  def down do
    update_config_id(&String.to_integer(&1))
  end

  defp update_config_id(fun) do
    Repo.transaction(fn ->
      tasks = Repo.all(from t in Task, where: t.type == "switch_discount")

      for task <- tasks do
        config = task.config
        config = update_in(config["id"], fun)

        task
        |> change(%{config: config})
        |> Repo.update!()
      end
    end)
  end
end
