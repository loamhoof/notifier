defimpl Jason.Encoder, for: Tuple do
  @impl true
  def encode(struct, opts) do
    struct
    |> Tuple.to_list()
    |> Jason.Encode.list(opts)
  end
end
