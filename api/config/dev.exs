import Config

# Configure your database
config :api, Api.Repo,
  username: "postgres",
  password: "postgres",
  database: "api_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  log: false

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :api, ApiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "NmRGcz40N4cGn6tCTlCN4upu0+Dyf1zFe+9flNFgmafr+f4ltT8R2c9zR3nbh4ew",
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$time][$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :api, :notification_mode, :log

case File.read("/home/loam/.pushbullet") do
  {:ok, pushbullet_token} -> config :api, :pushbullet_token, pushbullet_token
  _ -> nil
end

case File.read("/home/loam/.firebase/.server_key") do
  {:ok, fcm_server_key} -> config :api, :fcm_server_key, fcm_server_key
  _ -> nil
end

case File.read("/home/loam/.firebase/.device_token") do
  {:ok, fcm_device_token} -> config :api, :fcm_device_token, fcm_device_token
  _ -> nil
end
