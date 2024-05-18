defmodule ElswisserWeb.Tournaments.RosterHTML do
  use ElswisserWeb, :html
  import ElswisserWeb.PlayerHTML, only: [player_form: 1]

  embed_templates "roster_html/*"
end
