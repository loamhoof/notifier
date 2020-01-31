import Config

config :api, ApiWeb.Endpoint,
  server: true,
  secret_key_base:
    System.get_env(
      "SECRET_KEY_BASE",
      :crypto.strong_rand_bytes(64) |> Base.encode64() |> binary_part(0, 64)
    )

config :logger, level: :info

config :api, Api.Repo, show_sensitive_data_on_connection_error: false
