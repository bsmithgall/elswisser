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

  defp square_moves(%Square{piece: p} = square, %Game{} = game) when p == :r or p == :R do
    for d <- [:up, :down, :left, :right], reduce: [] do
      acc -> [move_range(square, game, d) | acc]
    end
    |> List.flatten()
  end

  defp square_moves(%Square{piece: p} = square, %Game{} = game) when p == :b or p == :B do
    for d <- [:up_right, :up_left, :down_left, :down_right], reduce: [] do
      acc -> [move_range(square, game, d) | acc]
    end
    |> List.flatten()
  end

  defp square_moves(%Square{piece: p} = square, %Game{} = game) when p == :q or p == :Q do
    for d <- [:up, :down, :left, :right, :up_right, :up_left, :down_left, :down_right],
        reduce: [] do
      acc -> [move_range(square, game, d) | acc]
    end
    |> List.flatten()
  end

  defp square_moves(_, _), do: []

  @spec move_range(%Square{}, %Game{}, Square.Sees.t()) :: [{%Square{}, boolean()}]
  defp move_range(%Square{} = square, %Game{} = game, direction) do
    square.sees[direction]
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
end
