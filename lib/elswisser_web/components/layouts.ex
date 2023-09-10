defmodule ElswisserWeb.Layouts do
  use ElswisserWeb, :html

  import ElswisserWeb.Topnav, only: [nav: 1]

  embed_templates "layouts/*"
end
