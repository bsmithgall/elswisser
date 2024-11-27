defmodule Elswisser.Games.PgnProvider do
  @type t :: module()

  @callback provides_for :: Regex.t()

  @callback extract_id(binary()) :: {:ok | :error, String.t()}

  @callback fetch_pgn(String.t()) :: {:ok | :error, String.t()}

  @spec find_provider(String.t()) :: {:error, String.t()} | {:ok, t()}
  def find_provider(game_link), do: find_provider(pgn_providers(), game_link)

  @spec find_provider(list(t()), String.t()) :: {:error, String.t()} | {:ok, t()}
  def find_provider(providers, game_link) do
    if p = Enum.find(providers, fn p -> Regex.match?(p.provides_for(), game_link) end) do
      {:ok, p}
    else
      {:error, "Could not find PGN parser for game link"}
    end
  end

  @spec pgn_providers() :: [__MODULE__.t()]
  def pgn_providers(), do: [Elswisser.Games.Chesscom, Elswisser.Games.Lichess]
end
