defmodule ApiWorker.Pushbullet do
  use HTTPoison.Base

  def process_request_url(url) do
    "https://api.pushbullet.com/v2" <> url
  end

  def process_request_headers(headers) do
    ["Content-Type": "application/json"] ++ headers
  end

  defdelegate process_request_body(body), to: Jason, as: :encode_to_iodata!

  defdelegate process_response_body(body), to: Jason, as: :decode!

  def push(token, {title, body}) do
    post("/pushes", %{type: "link", title: title, body: body}, "Access-Token": token)
  end

  def push(token, {title, body, url}) do
    post("/pushes", %{type: "link", title: title, body: body, url: url}, "Access-Token": token)
  end
end
