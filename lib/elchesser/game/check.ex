defmodule Elchesser.Game.Check do
  alias Elchesser.{Game, Board, Square, Move}

  def opponent_checking(%Game{} = game, %Move{} = move) do
    in_check? = opponent_in_check?(game)
    any_moves? = any_legal_moves?(game, move)

    cond do
      in_check? and any_moves? -> :check
      in_check? and not any_moves? -> :checkmate
      not in_check? and not any_moves? -> :stalemate
      true -> nil
    end
  end

  def check?(%Game{active: active} = game), do: check?(game, active)

  def opponent_in_check?(%Game{active: :w} = game), do: check?(game, :b)
  def opponent_in_check?(%Game{active: :b} = game), do: check?(game, :w)

  @spec check?(Game.t(), :b | :w) :: boolean()
  def check?(%Game{} = game, :w) do
    Board.find(game, :K) |> then(&Board.black_attacks_any?(game, &1))
  end

  def check?(%Game{} = game, :b) do
    Board.find(game, :k) |> then(&Board.white_attacks_any?(game, &1))
  end

  def any_legal_moves?(%Game{active: :w} = game, %Move{} = move) do
    check_legal_moves(Board.black_occupied(game), game, move)
  end

  def any_legal_moves?(%Game{active: :b} = game, %Move{} = move) do
    check_legal_moves(Board.white_occupied(game), game, move)
  end

  defp check_legal_moves(squares, game, move) do
    game =
      game |> Game.flip_color() |> Game.set_en_passant(move) |> Game.set_castling_rights(move)

    Enum.any?(squares, &(length(Square.legal_moves(&1, game)) > 0))
  end
end
