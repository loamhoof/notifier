[
  import_deps: [:ecto, :phoenix],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test,priv}/**/*.{ex,exs}"],
  subdirectories: ["priv/*/migrations", "lib/api/task/config", "lib/api/test", "test/api"]
]
