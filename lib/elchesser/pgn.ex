defmodule Elchesser.Pgn do
  alias Elchesser.Game

  import NimbleParsec
  import Elchesser.Pgn.ParserHelpers

  defparsec(:single_move, move())
  defparsec(:pgn_tags, tag_pairs())
  defparsec(:pgn_moves, moves())
  defparsec(:pgn_result, result())

  def parse(str) when is_binary(str) do
    with {:ok, tags, left, _, _, _} <- pgn_tags(str),
         {:ok, moves, _, _, _, _} <- pgn_moves(left),
         {:ok, [result], _, _, _, _} <- pgn_result(left) do
      tags = tags |> Enum.map(&List.to_tuple/1) |> Enum.into(%{})
      game = Game.new() |> Game.with_tags(tags)

      game =
        moves
        |> Enum.reduce(game, fn move, acc ->
          {:ok, acc} = Game.move(acc, move)
          acc
        end)

      {:ok, Game.with_result(game, result)}
    else
      {:error, reason, _, _, _, _} -> {:error, reason}
    end
  end

  @doc """
  Generate a PGN move list from a given game
  """
  def to_move_list(%Elchesser.Game{moves: moves}) do
    moves
    |> Enum.map(&Elchesser.Move.san/1)
    |> Enum.chunk_every(2)
    |> Enum.with_index(1)
    |> Enum.map(fn {[w, b], idx} -> "#{idx}. #{w} #{b}" end)
    |> Enum.join(" ")
  end
end
