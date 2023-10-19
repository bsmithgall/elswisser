defmodule Elswisser.Games.Chesscom do
  @doc """
  For some reason Chess.com doesn't expose a public API endpoint that contains
  the PGN for an individual game. Instead you have to back into it from the list
  of games for a given player in a given month, which you have to reverse
  engineer by going to an undocumented endpoint.

  Glad that this is the biggest chess website!
  """
  def fetch_pgn(game_link) do
    with {:ok, game_id} <- extract_id(game_link),
         {:ok, httpbody} <- fetch_callback_info(game_id),
         {:ok, username, archive_month} <- parse_callback_info(httpbody),
         {:ok, archive_body} <- fetch_archive(username, archive_month),
         {:ok, archive} <- parse_archive(archive_body),
         {:ok, games} <- extract_pgn(archive, game_id) do
      {:ok, games}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def extract_id(game_link) do
    case Regex.named_captures(~r/chess\.com\/\w+\/\w+\/(\w+\/)?(?<id>\d+)/, game_link) do
      %{"id" => game_id} when not is_nil(game_id) -> {:ok, game_id}
      _ -> {:error, "Could not find game ID in game link!"}
    end
  end

  def fetch_callback_info(game_id) do
    case HTTPoison.get("https://www.chess.com/callback/live/game/#{game_id}") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:ok, body}
      _ -> {:error, "Something bad happened requesting callback from chesscom"}
    end
  end

  def parse_callback_info(httpbody) do
    case Jason.decode(httpbody) do
      {:ok, parsed} ->
        {:ok, parsed["players"]["top"]["username"],
         Calendar.strftime(
           Date.from_iso8601!(String.replace(parsed["game"]["pgnHeaders"]["Date"], ".", "-")),
           "%Y/%m"
         )}

      _ ->
        {:error, "Could not decode Chess.com JSON response"}
    end
  end

  def fetch_archive(username, archive_month) do
    case HTTPoison.get(
           "https://api.chess.com/pub/player/#{username}/games/#{archive_month}",
           [],
           follow_redirect: true
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:ok, body}
      _ -> {:error, "Error fetching game archive from chesscom"}
    end
  end

  def parse_archive(httpbody) do
    case Jason.decode(httpbody) do
      {:ok, parsed} -> {:ok, parsed["games"]}
      _ -> {:error, "Could not decode Chess.com JSON response"}
    end
  end

  def extract_pgn(games, game_id) do
    game_link = "https://www.chess.com/game/live/#{game_id}"

    case Enum.find(games, fn g -> g["url"] == game_link end) do
      nil -> {:error, "Could not find PGN for game (id: #{game_id}, link: #{game_link})"}
      game -> {:ok, game["pgn"]}
    end
  end
end
