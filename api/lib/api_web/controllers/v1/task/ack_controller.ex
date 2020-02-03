defmodule ApiWeb.V1.Task.AckController do
  use ApiWeb, :controller

  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query, only: [from: 2]

  alias Api.{Repo, Task.Result}

  def create(conn, params) do
    task_result =
      case params do
        %{"task_id" => task_id} ->
          Repo.one(
            from r in Result,
              where: r.task_id == ^task_id,
              order_by: [desc: r.id],
              limit: 1
          )

        %{"result_id" => result_id} ->
          Repo.get(Result, result_id)
      end

    cond do
      is_nil(task_result) ->
        conn
        |> put_status(400)
        |> json(%{"message" => "No result yet"})

      not is_nil(task_result.acked_at) ->
        conn
        |> put_status(400)
        |> json(%{"message" => "Already acked"})

      is_nil(task_result.sent_at) ->
        conn
        |> put_status(400)
        |> json(%{"message" => "Cannot ack a result which has not been sent yet"})

      true ->
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        result =
          change(task_result, %{acked_at: now})
          |> Repo.update()

        case result do
          {:ok, task_result} ->
            ApiWorker.EventManager.ack(ApiWorker.EventManager, task_result.task_id, now)
            json(conn, task_result)

          {:error, %{errors: errors}} ->
            conn
            |> put_status(400)
            |> json(errors)
        end
    end
  end
end
