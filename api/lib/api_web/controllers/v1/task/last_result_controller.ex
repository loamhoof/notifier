defmodule ApiWeb.V1.Task.LastResultController do
  use ApiWeb, :controller

  import Ecto.Query, only: [from: 2]

  alias Api.{Repo, Task, Task.Result}

  def index(conn, %{"task_id" => task_id}) do
    last_result =
      Repo.one(
        from r in Result,
          join: t in Task,
          on: r.task_id == t.id,
          where: t.id == ^task_id,
          order_by: [desc: r.id],
          limit: 1
      )

    json(conn, last_result)
  end
end
