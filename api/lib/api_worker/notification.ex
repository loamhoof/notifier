defmodule ApiWorker.Notification do
  @type t :: {title :: String.t(), body :: String.t(), url :: String.t()}
  @type patch :: %{field: String.t(), pattern: String.t(), replacement: String.t()}

  @spec apply_patches(list(patch), t) :: t
  def apply_patches(patches, notif) do
    Enum.reduce(patches, notif, &apply_patch(&1, &2))
  end

  @spec apply_patch(patch, t) :: t
  defp apply_patch(
         %{"field" => field, "pattern" => pattern, "replacement" => replacement},
         {title, body, url}
       ) do
    regex = Regex.compile!(pattern)

    case field do
      "title" -> {Regex.replace(regex, title, replacement), body, url}
      "body" -> {title, Regex.replace(regex, body, replacement), url}
      "url" -> {title, body, Regex.replace(regex, url, replacement)}
    end
  end
end
