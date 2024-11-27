defmodule ElswisserWeb.GameController do
  use ElswisserWeb, :controller

  import Phoenix.Controller
  alias Elswisser.Games

  def show(conn, %{"id" => id}) do
    game = Games.get_game_with_players_and_opening!(id)

    render(conn, :show, game: game)
  end

  def edit(conn, %{"id" => id}) do
    game = Games.get_game_with_players!(id)
    changeset = Games.change_game(game)
    render(conn, :edit, game: game, changeset: changeset)
  end

  def update(conn, %{"tournament_id" => tournament_id, "id" => id, "game" => game_params}) do
    game = Games.get_game!(id)

    case Games.update_game(game, game_params) do
      {:ok, game} ->
        conn
        |> put_flash(:info, "Game updated successfully.")
        |> redirect(to: ~p"/tournaments/#{tournament_id}/games/#{game}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, game: game, changeset: changeset)
    end
  end
end
