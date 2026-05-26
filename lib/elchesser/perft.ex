defmodule Elchesser.Perft do
  alias Elchesser.{Game, Move}

  @spec perft(Game.t(), non_neg_integer()) :: non_neg_integer()
  def perft(_, 0), do: 1

  def perft(game, depth) do
    game
    |> Game.all_legal_moves()
    |> Enum.map(fn move ->
      {:ok, new_game} = Game.make_move(game, move)
      perft(new_game, depth - 1)
    end)
    |> Enum.sum()
  end

  @spec divide(Game.t(), non_neg_integer()) :: [{binary(), non_neg_integer()}]
  def divide(game, depth) do
    game
    |> Game.all_legal_moves()
    |> Enum.map(fn move ->
      {:ok, new_game} = Game.make_move(game, move)
      {Move.to_uci(move), perft(new_game, depth - 1)}
    end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.each(fn {uci, count} -> IO.puts("#{uci}: #{count}") end)
  end
end
