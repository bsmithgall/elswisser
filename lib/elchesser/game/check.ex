defmodule Elchesser.Game.Check do
  alias Elchesser.{Game, Board, Square, Move}
  alias Elchesser.Board.Attacks
  alias Elchesser.Game.Castling

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
  def check?(%Game{kings: {nil, _}}, :w), do: false

  def check?(%Game{kings: {w, _}} = game, :w) do
    Attacks.square_attacked_by?(game, w, :b)
  end

  def check?(%Game{kings: {_, nil}}, :b), do: false

  def check?(%Game{kings: {_, b}} = game, :b) do
    Attacks.square_attacked_by?(game, b, :w)
  end

  def any_legal_moves?(%Game{active: :w} = game, %Move{} = move) do
    check_legal_moves(Board.black_occupied(game), game, move)
  end

  def any_legal_moves?(%Game{active: :b} = game, %Move{} = move) do
    check_legal_moves(Board.white_occupied(game), game, move)
  end

  defp check_legal_moves(squares, game, move) do
    game =
      game |> Game.flip_color() |> Game.set_en_passant(move) |> Castling.set_castling_rights(move)

    Enum.any?(squares, &(length(Square.legal_moves(&1, game)) > 0))
  end
end
