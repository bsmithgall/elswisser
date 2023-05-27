defmodule Elswisser.Games.Chesscom do
  @doc """
  For some reason Chess.com doesn't expose a public API endpoint that contains
  the PGN for an individual game. Instead you have to back into it from the list
  of games for a given player in a given month, which you have to reverse
  engineer by going to an undocumented endpoint.

  Glad that this is the biggest chess website!
  """
  def fetch_pgn(game_link) do
    captures = Regex.named_captures(link_regexp(), game_link)
    game_id = captures["id"]

    if is_nil(game_id) do
      {:error, "Could not find extract game ID from game link!"}
    else
      case extract_date(game_id) do
        {:ok, extract} ->
          case extract_archive(extract[:username], extract[:archive_month]) do
            {:ok, games} ->
              extract_pgn(games, game_id)

            {:error, msg} ->
              {:error, msg}
          end

        {:error, msg} ->
          {:error, msg}
      end
    end
  end

  def extract_date(game_id) do
    case HTTPoison.get("https://www.chess.com/callback/live/game/#{game_id}") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, parsed} ->
            dt = parsed["game"]["pgnHeaders"]["Date"]

            {:ok,
             username: parsed["players"]["top"]["username"],
             archive_month:
               Calendar.strftime(Date.from_iso8601!(String.replace(dt, ".", "-")), "%Y/%m")}

          _ ->
            {:error, "Could not decode Chess.com JSON response"}
        end

      _ ->
        {:error, "Something bad happened requesting callback from chesscom"}
    end
  end

  def extract_archive(username, archive_month) do
    case HTTPoison.get(
           "https://api.chess.com/pub/player/#{username}/games/#{archive_month}",
           [],
           follow_redirect: true
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, parsed} ->
            {:ok, parsed["games"]}

          _ ->
            {:error, "Could not decode Chess.com JSON response"}
        end

      _ ->
        {:error, "Something bad happened requesting callback from chesscom"}
    end
  end

  def extract_pgn(games, game_id) do
    game_link = "https://www.chess.com/game/live/#{game_id}"

    case Enum.find(games, fn g -> g["url"] == game_link end) do
      nil -> {:error, "Could not find PGN for game"}
      game -> {:ok, game["pgn"]}
    end
  end

  defp link_regexp do
    ~r/chess\.com\/game\/live\/(?<id>\d+)/
  end
end
