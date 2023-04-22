defmodule ElswisserWeb.PlayerController do
  use ElswisserWeb, :controller

  alias Elswisser.Players
  alias Elswisser.Players.Player

  def index(conn, _params) do
    players = Players.list_players()
    render(conn, :index, players: players)
  end

  def new(conn, _params) do
    changeset = Players.change_player(%Player{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"player" => player_params}) do
    case Players.create_player(player_params) do
      {:ok, _player} ->
        conn
        |> put_flash(:info, "Player created successfully.")
        |> redirect(to: ~p"/players")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    player = Players.get_player!(id)
    render(conn, :show, player: player)
  end

  def edit(conn, %{"id" => id}) do
    player = Players.get_player!(id)
    changeset = Players.change_player(player)
    render(conn, :edit, player: player, changeset: changeset)
  end

  def update(conn, %{"id" => id, "player" => player_params}) do
    player = Players.get_player!(id)

    case Players.update_player(player, player_params) do
      {:ok, _player} ->
        conn
        |> put_flash(:info, "Player updated successfully.")
        |> redirect(to: ~p"/players")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, player: player, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    player = Players.get_player!(id)
    {:ok, _player} = Players.delete_player(player)

    conn
    |> put_flash(:info, "Player deleted successfully.")
    |> redirect(to: ~p"/players")
  end
end
