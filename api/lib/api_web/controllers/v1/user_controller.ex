defmodule ApiWeb.V1.UserController do
  use ApiWeb, :controller

  alias Api.{Repo, User}

  @spec index(Plug.Conn.t(), %{}) :: Plug.Conn.t()
  def index(conn, _params) do
    users = Repo.all(User)

    json(conn, users)
  end

  @spec show(Plug.Conn.t(), %{required(String.t()) => String.t()}) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    case Repo.get(User, id) do
      nil -> send_resp(conn, 404, "Not Found")
      user -> json(conn, user)
    end
  end

  @spec create(Plug.Conn.t(), %{}) :: Plug.Conn.t()
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
        |> put_status(400)
        |> json(errors)
    end
  end

  @spec update(Plug.Conn.t(), %{required(String.t()) => String.t()}) :: Plug.Conn.t()
  def update(conn, %{"id" => id}) do
    user =
      case conn.method do
        "PUT" ->
          %User{id: String.to_integer(id)}

        "PATCH" ->
          Repo.get!(User, id)
      end

    result =
      user
      |> User.update_changeset(conn.body_params)
      |> Repo.update()

    case result do
      {:ok, updated_user} ->
        json(conn, updated_user)

      {:error, %{errors: errors}} ->
        conn
        |> put_status(400)
        |> json(errors)
    end
  end

  @spec delete(Plug.Conn.t(), %{required(String.t()) => String.t()}) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    case Repo.get(User, id) do
      nil ->
        send_resp(conn, 404, "Not found")

      user ->
        Repo.delete(user)
        json(conn, user)
    end
  end
end
