defmodule Elswisser.Openings do
  alias Elswisser.Openings.Opening
  alias Elswisser.Repo

  def get_by_pgn(pgn) do
    Opening.from()
    |> Opening.where_pgn(pgn)
    |> Repo.one()
  end

  @doc """
  Given a PGN or Elchesser.Game, find a loaded opening from the `openings`
  table. A few notes:
  - The longest known opening is 18 moves (36 half-moves), so we can start by
    pruning the game down to there
  - The "correct" way of doing this according to lichess is to walk backwards
    through the PGN and find the longest matching sub-string. This uses
    Enum.drop/2, which isn't the most efficient, but the lists are so short it
    shouldn't matter (we also won't call this operation so frequently)
  """
  def find_from_game(%Elswisser.Games.Game{pgn: pgn}), do: find_from_game(pgn)

  def find_from_game(pgn) when is_binary(pgn) do
    case Elchesser.Pgn.parse(pgn) do
      {:ok, game} -> find_from_game(game)
      {:error, _} -> {:ok, nil}
    end
  end

  def find_from_game(%Elchesser.Game{moves: []}), do: {:ok, nil}

  def find_from_game(%Elchesser.Game{moves: moves} = game) when length(moves) > 36 do
    find_from_game(%Elchesser.Game{game | moves: Enum.slice(moves, 0, 36)})
  end

  def find_from_game(%Elchesser.Game{moves: moves} = game) do
    opening_pgn = Elchesser.Pgn.to_move_list(game)

    case get_by_pgn(opening_pgn) do
      nil -> find_from_game(%Elchesser.Game{game | moves: Enum.drop(moves, -1)})
      %Opening{} = opening -> {:ok, opening}
    end
  end
end
