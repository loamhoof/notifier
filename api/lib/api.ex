defmodule Api do
  @type ok() :: :ok | {:error, reason :: Inspect.t()}
  @type ok(return_type) :: {:ok, return_type} | {:error, reason :: Inspect.t()}
  @type ok(return_type, error_type) :: {:ok, return_type} | {:error, error_type}
end
