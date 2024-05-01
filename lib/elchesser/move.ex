defmodule Elchesser.Move do
  defstruct file: ?a, rank: 1, capture: false, promotion: false

  @type t :: %__MODULE__{}
  @type type :: nil | :capture | :castle | :promotion

  alias Elchesser.{Game, Square, Piece}
  alias __MODULE__

  def from({file, rank}), do: %Move{file: file, rank: rank}

  def game_moves(%Game{} = game) do
    for file <- Elchesser.files(), rank <- Elchesser.ranks(), reduce: %{} do
      acc ->
        square = Map.get(game.board, {file, rank})
        Map.put(acc, {file, rank}, square_moves(square, game))
    end
  end

  def generate_move(%Game{} = game, {file, rank}) do
    Map.get(game.board, {file, rank}) |> square_moves(game)
  end

  @spec move_range(%Square{}, %Game{}, Square.Sees.t()) :: [t()]
  def move_range(%Square{} = square, %Game{} = game, direction) do
    get_in(square.sees, [Access.key!(direction)])
    |> Enum.reduce_while([], fn {file, rank}, acc ->
      s = Map.get(game.board, {file, rank})

      case Piece.friendly?(square.piece, s.piece) do
        true -> {:halt, acc}
        false -> {:halt, [%Move{file: s.file, rank: s.rank, capture: true} | acc]}
        nil -> {:cont, [%Move{file: s.file, rank: s.rank} | acc]}
      end
    end)
    |> Enum.reverse()
  end

  ## rooks ##

  ## white pawns

  defp square_moves(%Square{piece: :P, file: file, rank: rank}, %Game{} = game) do
    # cannot capture forward
    forward =
      if(rank == 2,
        do: [{{file, 3}, false}, {{file, 4}, false}],
        else: [{{file, rank + 1}, false}]
      )
      |> Enum.filter(fn {s, _} -> is_nil(Map.get(game.board, s).piece) end)

    captures =
      [{{file + 1, rank + 1}, true}, {{file - 1, rank + 1}, true}]
      |> Enum.filter(fn {s, _} -> Square.valid?(s) end)
      |> Enum.filter(fn {s, _} ->
        Map.get(game.board, s)
        |> then(&(Piece.enemy?(:P, &1.piece) || en_passant?(&1, game)))
      end)

    Enum.concat(forward, captures)
  end

  ## black pawns

  defp square_moves(%Square{piece: :p, file: file, rank: rank}, %Game{} = game) do
    # cannot capture forward
    forward =
      if(rank == 7,
        do: [{{file, 6}, false}, {{file, 5}, false}],
        else: [{{file, rank - 1}, false}]
      )
      |> Enum.filter(fn {s, _} -> is_nil(Map.get(game.board, s).piece) end)

    # can only move sideways if captured

    captures =
      [{{file + 1, rank - 1}, true}, {{file - 1, rank - 1}, true}]
      |> Enum.filter(fn {s, _} -> Square.valid?(s) end)
      |> Enum.filter(fn {s, _} ->
        Map.get(game.board, s)
        |> then(&(Piece.enemy?(:p, &1.piece) || en_passant?(&1, game)))
      end)

    Enum.concat(forward, captures)
  end

  ## empty squares

  defp square_moves(_, _), do: []

  defp en_passant?(%Square{} = square, %Game{} = game) do
    Square.empty?(square) && Square.eq?(square, game.en_passant)
  end
end
