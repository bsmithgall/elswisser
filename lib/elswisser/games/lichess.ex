defmodule Elswisser.Games.Lichess do
  def fetch_pgn(game_link) do
    captures = Regex.named_captures(~r/lichess\.org\/(?<id>\w+)\.*?/, game_link)
    game_id = captures["id"]

    case HTTPoison.get("https://lichess.org/game/export/#{game_id}") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      _ ->
        {:error, "Could not get game from Lichess"}
    end
  end
end
