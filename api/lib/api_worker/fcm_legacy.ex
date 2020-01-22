defmodule ApiWorker.FCMLegacy do
  use HTTPoison.Base

  def process_request_url(url) do
    "https://fcm.googleapis.com/fcm" <> url
  end

  def process_request_headers(headers) do
    server_key = Application.fetch_env!(:api, :fcm_server_key)
    [{"Content-Type", "application/json"}, {"Authorization", "key=#{server_key}"}] ++ headers
  end

  defdelegate process_request_body(body), to: Jason, as: :encode_to_iodata!

  defdelegate process_response_body(body), to: Jason, as: :decode!

  def push({title, body}) do
    push({title, body, ""})
  end

  def push({title, body, _url}) do
    device_token = Application.fetch_env!(:api, :fcm_device_token)

    post("/send", %{to: device_token, notification: %{title: title, body: body}})
  end
end
