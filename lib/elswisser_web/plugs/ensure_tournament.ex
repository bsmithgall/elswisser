defmodule ElswisserWeb.Plugs.EnsureTournament do
  import Plug.Conn

  alias Elswisser.Tournaments

  @needs ["all", "rounds"]

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

  defp fetch_tournament(conn, needs) do
    case needs do
      "rounds" -> fetch_with_rounds(conn)
      _ -> fetch_with_all(conn)
    end
  end

  defp fetch_with_all(conn) do
    case Tournaments.get_tournament_with_all(conn.assigns[:tournament_id]) do
      nil -> not_found(conn)
      tournament -> assign(conn, :tournament, tournament)
    end
  end

  defp fetch_with_rounds(conn) do
    case Tournaments.get_tournament_with_rounds(conn.assigns[:tournament_id]) do
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
