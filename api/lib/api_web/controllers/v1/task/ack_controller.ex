defmodule ApiWeb.V1.Task.AckController do
  use ApiWeb, :controller

  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query, only: [from: 2]

  alias Api.{Repo, Task.Result}

  def create(conn, %{"task_id" => task_id}) do
    last_result =
      Repo.one(
        from r in Result,
          where: r.task_id == ^task_id,
          order_by: [desc: r.id],
          limit: 1
      )

    cond do
      is_nil(last_result) ->
        conn
        |> Plug.Conn.put_status(400)
        |> json(%{"message" => "No result yet"})

      not last_result.to_ack ->
        conn
        |> Plug.Conn.put_status(400)
        |> json(%{"message" => "Nothing to ack"})

      not is_nil(last_result.acked_at) ->
        conn
        |> Plug.Conn.put_status(400)
        |> json(%{"message" => "Already acked"})

      is_nil(last_result.sent_at) ->
        conn
        |> Plug.Conn.put_status(400)
        |> json(%{"message" => "Cannot ack a result which has not been sent yet"})

      true ->
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        result =
          change(last_result, %{acked_at: now})
          |> Repo.update()

        case result do
          {:ok, last_result} ->
            ApiWorker.EventManager.ack(ApiWorker.EventManager, task_id, now)
            json(conn, last_result)

          {:error, %{errors: errors}} ->
            conn
            |> Plug.Conn.put_status(400)
            |> json(errors)
        end
    end
  end
end
