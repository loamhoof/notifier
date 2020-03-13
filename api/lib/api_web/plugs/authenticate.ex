defmodule ApiWeb.Plug.Authenticate do
  @behaviour Plug
  import Plug.Conn

  alias Api.{Repo, User}

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    res =
      with [authorization | _] <- get_req_header(conn, "authorization"),
           [type, token] <- String.split(authorization, " ", parts: 2) do
        case type do
          "Basic" -> authenticate_basic(token)
          _unknown_type -> :error
        end
      else
        _else -> :error
      end

    case res do
      {:ok, user} -> conn |> assign(:user, user)
      :error -> conn |> send_resp(401, "") |> halt()
    end
  end

  defp authenticate_basic(token) do
    res =
      with {:ok, decoded_token} <- Base.decode64(token),
           [username, password] <- String.split(decoded_token, ":", parts: 2),
           %User{} = user <- Repo.get_by(User, name: username),
           do: Argon2.check_pass(user, password)

    case res do
      {:ok, user} -> {:ok, user}
      _else -> :error
    end
  end
end
