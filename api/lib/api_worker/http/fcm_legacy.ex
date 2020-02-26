defmodule ApiWorker.HTTP.FCMLegacy do
  use HTTPoison.Base

  @impl true
  def process_request_url(url) do
    "https://fcm.googleapis.com/fcm" <> url
  end

  @impl true
  def process_request_headers(headers) do
    ["Content-Type": "application/json"] ++ headers
  end

  @impl true
  defdelegate process_request_body(body), to: Jason, as: :encode_to_iodata!

  @impl true
  defdelegate process_response_body(body), to: Jason, as: :decode!

  def push(config, {title, body}) do
    push(config, {title, body, ""})
  end

  def push({server_key, device_token}, {title, body, _url}) do
    post(
      "/send",
      %{to: device_token, notification: %{title: title, body: body}},
      Authorization: "key=#{server_key}"
    )
  end
end
