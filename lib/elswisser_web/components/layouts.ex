defmodule ElswisserWeb.Layouts do
  use ElswisserWeb, :html

  embed_templates "layouts/*"

  attr(:current_user, :map, default: nil)

  def topnav(assigns)
end
