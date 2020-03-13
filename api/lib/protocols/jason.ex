defimpl Jason.Encoder, for: Tuple do
  @impl true
  def encode(struct, opts) do
    Jason.Encode.list(Tuple.to_list(struct), opts)
  end
end
