defmodule CustomToast do
  def toast_class_fn(assigns) do
    [
      # base classes using Bulma
      "notification is-light toast-notification",
      "[@media(scripting:enabled)]:opacity-0 [@media(scripting:enabled){[data-phx-main]_&}]:opacity-100",
      # used to hide the disconnected flashes
      if(assigns[:rest][:hidden] == true, do: "hidden", else: "flex"),
      # override styles per severity
      assigns[:kind] == :info && "is-info",
      assigns[:kind] == :error && "is-danger"
    ]
  end
end
