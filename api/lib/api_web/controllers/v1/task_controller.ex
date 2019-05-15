defmodule ApiWeb.V1.TaskController do
  use ApiWeb, :controller

  alias Api.{Repo, Task}

  def index(conn, _params) do
    tasks = Repo.all(Task)

    json(conn, tasks)
  end

  def show(conn, %{"id" => id}) do
    case Repo.get(Task, id) do
      nil -> Plug.Conn.send_resp(conn, 404, "Not found")
      task -> json(conn, task)
    end
  end

  def create(conn, _params) do
    result =
      %Task{}
      |> Task.changeset(conn.body_params)
      |> Repo.insert()

    case result do
      {:ok, task} ->
        json(conn, task)

      {:error, %{errors: errors}} ->
        conn
        |> Plug.Conn.put_status(400)
        |> json(errors)
    end
  end

  def update(conn, %{"id" => id}) do
    result =
      case conn.method do
        "PUT" ->
          %Task{id: String.to_integer(id)}

        "PATCH" ->
          Repo.get!(Task, id)
      end
      |> Task.changeset(conn.body_params)
      |> Repo.update()

    case result do
      {:ok, task} ->
        json(conn, task)

      {:error, %{errors: errors}} ->
        conn
        |> Plug.Conn.put_status(400)
        |> json(errors)
    end
  end

  def delete(conn, %{"id" => id}) do
    case Repo.get(Task, id) do
      nil ->
        Plug.Conn.send_resp(conn, 404, "Not found")

      task ->
        Repo.delete(task)
        json(conn, task)
    end
  end
end
