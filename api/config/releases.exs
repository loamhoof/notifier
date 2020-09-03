import Config

secret_key_base =
  System.get_env(
    "SECRET_KEY_BASE",
    :crypto.strong_rand_bytes(64) |> Base.encode64() |> binary_part(0, 64)
  )

host = System.get_env("HOST") || raise "HOST is not set"
port = System.get_env("PORT", "4000") |> String.to_integer()

config :api, ApiWeb.Endpoint,
  url: [host: host, port: port],
  http: [
    port: port,
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base,
  server: true

config :api, Api.Repo,
  log: System.get_env("DB_DEBUG", "false") == "true",
  username: System.fetch_env!("DB_USERNAME"),
  password: System.fetch_env!("DB_PASSWORD"),
  hostname: System.fetch_env!("DB_HOSTNAME"),
  database: System.fetch_env!("DB_DATABASE"),
  port: System.get_env("DB_PORT", "5432") |> String.to_integer(),
  pool_size: System.get_env("DB_POOL_SIZE", "10") |> String.to_integer()

config :api,
       :notification_mode,
       System.get_env("NOTIFICATION_MODE", "fcm_legacy") |> String.to_atom()

case System.fetch_env("PUSHBULLET_TOKEN") do
  {:ok, pushbullet_token} -> config :api, :pushbullet_token, pushbullet_token
  :error -> nil
end

case System.fetch_env("FCM_SERVER_KEY") do
  {:ok, fcm_server_key} -> config :api, :fcm_server_key, fcm_server_key
  :error -> nil
end

case System.fetch_env("FCM_DEVICE_TOKEN") do
  {:ok, fcm_device_token} -> config :api, :fcm_device_token, fcm_device_token
  :error -> nil
end
