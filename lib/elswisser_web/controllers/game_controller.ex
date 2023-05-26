defmodule ElswisserWeb.GameController do
  use ElswisserWeb, :controller

  import Phoenix.Controller

  def show(conn, %{"id" => id}) do
    game = Elswisser.Games.get_game_with_players!(id)

    render(conn, :show, game: game)
  end
end
