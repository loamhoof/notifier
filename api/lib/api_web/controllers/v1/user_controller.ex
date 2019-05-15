defmodule ApiWeb.V1.UserController do
  use ApiWeb, :controller

  alias Api.{Repo, User}

  def index(conn, _params) do
    users = Repo.all(User)

    json(conn, users)
  end

  def show(conn, %{"id" => id}) do
    case Repo.get(User, id) do
      nil -> Plug.Conn.send_resp(conn, 404, "Not Found")
      user -> json(conn, user)
    end
  end

  def create(conn, _params) do
    result =
      %User{}
      |> User.create_changeset(conn.body_params)
      |> Repo.insert()

    case result do
      {:ok, user} ->
        json(conn, user)

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
          %User{id: String.to_integer(id)}

        "PATCH" ->
          Repo.get!(User, id)
      end
      |> User.update_changeset(conn.body_params)
      |> Repo.update()

    case result do
      {:ok, user} ->
        json(conn, user)

      {:error, %{errors: errors}} ->
        conn
        |> Plug.Conn.put_status(400)
        |> json(errors)
    end
  end

  def delete(conn, %{"id" => id}) do
    case Repo.get(User, id) do
      nil ->
        Plug.Conn.send_resp(conn, 404, "Not found")

      user ->
        Repo.delete(user)
        json(conn, user)
    end
  end
end
