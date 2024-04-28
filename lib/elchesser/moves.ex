defmodule Elchesser.Moves do
  alias Elchesser.{Game, Square, Piece}

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

  ## rooks ##

  defp square_moves(%Square{piece: p} = square, %Game{} = game) when p == :r or p == :R do
    for d <- [:up, :down, :left, :right], reduce: [] do
      acc -> [move_range(square, game, d) | acc]
    end
    |> List.flatten()
  end

  ## bishops ##

  defp square_moves(%Square{piece: p} = square, %Game{} = game) when p == :b or p == :B do
    for d <- [:up_right, :up_left, :down_left, :down_right], reduce: [] do
      acc -> [move_range(square, game, d) | acc]
    end
    |> List.flatten()
  end

  ## queens ##

  defp square_moves(%Square{piece: p} = square, %Game{} = game) when p == :q or p == :Q do
    for d <- [:up, :down, :left, :right, :up_right, :up_left, :down_left, :down_right],
        reduce: [] do
      acc -> [move_range(square, game, d) | acc]
    end
    |> List.flatten()
  end

  ## knights ##

  defp square_moves(%Square{piece: p} = square, %Game{} = game) when p == :n or p == :N do
    Enum.reduce(square.sees.knight, [], fn {file, rank}, acc ->
      s = Map.get(game.board, {file, rank})

      case Piece.friendly?(square.piece, s.piece) do
        true -> acc
        false -> [{{s.file, s.rank}, true} | acc]
        nil -> [{{s.file, s.rank}, false} | acc]
      end
    end)
    |> Enum.reverse()
  end

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

  @spec move_range(%Square{}, %Game{}, Square.Sees.t()) :: [{%Square{}, boolean()}]
  defp move_range(%Square{} = square, %Game{} = game, direction) do
    get_in(square.sees, [Access.key!(direction)])
    |> Enum.reduce_while([], fn {file, rank}, acc ->
      s = Map.get(game.board, {file, rank})

      case Piece.friendly?(square.piece, s.piece) do
        true -> {:halt, acc}
        false -> {:halt, [{{s.file, s.rank}, true} | acc]}
        nil -> {:cont, [{{s.file, s.rank}, false} | acc]}
      end
    end)
    |> Enum.reverse()
  end

  defp en_passant?(%Square{} = square, %Game{} = game) do
    Square.empty?(square) && Square.eq?(square, game.en_passant)
  end
end
