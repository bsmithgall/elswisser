defmodule Elswisser.Games.Lichess do
  alias Elswisser.Games.PgnProvider

  @behaviour PgnProvider

  @impl PgnProvider
  def provides_for, do: ~r/lichess\.org\/(?<id>\w+)\.*?/

  @impl PgnProvider
  def extract_id(game_link) do
    case Regex.named_captures(provides_for(), game_link) do
      %{"id" => game_id} when not is_nil(game_id) -> {:ok, game_id}
      _ -> {:error, "Could not find game ID in game link!"}
    end
  end

  def extract_pgn(game_id) do
    case Req.get("https://lichess.org/game/export/#{game_id}") do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      _ ->
        {:error, "Could not get game from Lichess"}
    end
  end

  @impl PgnProvider
  def fetch_pgn(game_link) do
    with {:ok, game_id} <- extract_id(game_link),
         {:ok, pgn} <- extract_pgn(game_id) do
      {:ok, pgn}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
