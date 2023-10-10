defmodule ElswisserWeb.Plugs.EnsureTournament do
  import Plug.Conn

  alias Elswisser.Tournaments

  @needs ["all", "rounds", "rounds_players", "none"]

  def init(needs) when needs in @needs, do: needs

  def call(%Plug.Conn{} = conn, needs) do
    conn |> normalize_id() |> fetch_tournament(needs) |> get_current_round()
  end

  defp normalize_id(conn) do
    case is_nil(conn.params["tournament_id"]) do
      true -> assign(conn, :tournament_id, conn.params["id"])
      false -> assign(conn, :tournament_id, conn.params["tournament_id"])
    end
  end

  defp fetch_tournament(conn, "none") do
    case Tournaments.get_tournament(conn.assigns[:tournament_id]) do
      nil -> not_found(conn)
      tournament -> assign(conn, :tournament, tournament)
    end
  end

  defp fetch_tournament(conn, "rounds") do
    case Tournaments.get_tournament_with_rounds(conn.assigns[:tournament_id]) do
      nil -> not_found(conn)
      tournament -> assign(conn, :tournament, tournament)
    end
  end

  defp fetch_tournament(conn, "rounds_players") do
    case Tournaments.get_tournament_with_rounds_and_players(conn.assigns[:tournament_id]) do
      nil -> not_found(conn)
      tournament -> assign(conn, :tournament, tournament)
    end
  end

  defp fetch_tournament(conn, "all") do
    case Tournaments.get_tournament_with_all(conn.assigns[:tournament_id]) do
      nil -> not_found(conn)
      tournament -> assign(conn, :tournament, tournament)
    end
  end

  defp get_current_round(conn) do
    current_round = Tournaments.current_round(conn.assigns[:tournament])
    assign(conn, :current_round, current_round)
  end

  defp not_found(conn) do
    conn
    |> put_status(404)
    |> Phoenix.Controller.put_view(ElswisserWeb.ErrorHTML)
    |> Phoenix.Controller.render("404.html")
    |> halt()
  end
end
