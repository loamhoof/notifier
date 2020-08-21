defmodule ApiWeb.V1.TaskController do
  use ApiWeb, :controller

  import Ecto.Query, only: [from: 2]

  alias Api.{Repo, Task}

  @spec index(Plug.Conn.t(), %{}) :: Plug.Conn.t()
  def index(conn, _params) do
    tasks = Repo.all(from Task, order_by: :name)

    json(conn, tasks)
  end

  @spec show(Plug.Conn.t(), %{required(String.t()) => String.t()}) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    case Repo.get(Task, id) do
      nil -> send_resp(conn, 404, "Not found")
      task -> json(conn, task)
    end
  end

  @spec create(Plug.Conn.t(), %{}) :: Plug.Conn.t()
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
        |> put_status(400)
        |> json(errors)
    end
  end

  @spec update(Plug.Conn.t(), %{required(String.t()) => String.t()}) :: Plug.Conn.t()
  def update(conn, %{"id" => id}) do
    task =
      case conn.method do
        "PUT" ->
          %Task{id: String.to_integer(id)}

        "PATCH" ->
          Repo.get!(Task, id)
      end

    result =
      task
      |> Task.changeset(conn.body_params)
      |> Repo.update()

    case result do
      {:ok, updated_task} ->
        json(conn, updated_task)

      {:error, %{errors: errors}} ->
        conn
        |> put_status(400)
        |> json(errors)
    end
  end

  @spec delete(Plug.Conn.t(), %{required(String.t()) => String.t()}) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    case Repo.get(Task, id) do
      nil ->
        send_resp(conn, 404, "Not found")

      task ->
        Repo.delete(task)
        json(conn, task)
    end
  end
end
