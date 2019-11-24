defmodule ApiWorker.Pushbullet do
  use HTTPoison.Base

  def process_request_url(url) do
    "https://api.pushbullet.com/v2" <> url
  end

  def process_request_headers(headers) do
    token = Application.fetch_env!(:api, :pushbullet_token)
    [{"Content-Type", "application/json"}, {"Access-Token", token}] ++ headers
  end

  defdelegate process_request_body(body), to: Jason, as: :encode_to_iodata!

  defdelegate process_response_body(body), to: Jason, as: :decode!

  def push({title, body, url}) do
    post("/pushes", %{type: "link", title: title, body: body, url: url})
  end
end
