defmodule Elchesser.Board do
  alias Elchesser.{Game, Square, Piece, Move}

  def move(%Game{} = game, %Move{} = move) do
    with {:ok, {piece, game}} <- move_from(game, move.from),
         {:ok, {capture, game}} <- move_to(game, move.to, piece) do
      {:ok, {piece, capture, game}}
    end
  end

  @spec find(Game.t(), Piece.t()) :: [Square.t()]
  def find(%Game{board: board}, piece) do
    Enum.reduce(board, [], fn {_, %Square{} = square}, acc ->
      if square.piece == piece, do: [square | acc], else: acc
    end)
  end

  @spec color_at(Elchesser.Game.t(), Elchesser.Square.t()) :: :b | nil | :w
  def color_at(%Game{} = game, %Square{} = square) do
    p = Game.get_square(game, square).piece

    cond do
      is_nil(p) -> nil
      Piece.white?(p) -> :w
      Piece.black?(p) -> :b
    end
  end

  @spec white_attacks(Game.t()) :: [{number(), number()}]
  def white_attacks(%Game{} = game) do
    white_occupied(game)
    |> Enum.map(&Square.attacks(&1, game))
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map(& &1.to)
  end

  @spec black_attacks(Game.t()) :: [{number(), number()}]
  def black_attacks(%Game{} = game) do
    black_occupied(game)
    |> Enum.map(&Square.attacks(&1, game))
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map(& &1.to)
  end

  @spec white_attacks_any?(Game.t(), [Square.t()]) :: boolean()
  def white_attacks_any?(%Game{} = game, squares) do
    locs = Enum.map(squares, & &1.loc)
    white_attacks(game) |> Enum.any?(fn square -> square in locs end)
  end

  @spec black_attacks_any?(Game.t(), [Square.t()]) :: boolean()
  def black_attacks_any?(%Game{} = game, squares) do
    locs = Enum.map(squares, & &1.loc)
    black_attacks(game) |> Enum.any?(fn square -> square in locs end)
  end

  def white_occupied(%Game{board: board}) do
    Map.filter(board, fn {_, square} -> Square.white?(square) end)
    |> Map.values()
  end

  def black_occupied(%Game{board: board}) do
    Map.filter(board, fn {_, square} -> Square.black?(square) end)
    |> Map.values()
  end

  @spec move_from(Game.t(), {number(), number()}) ::
          {:error, :atom} | {:ok, {Piece.t(), Game.t()}}
  defp move_from(%Game{board: board} = game, loc) do
    case Map.get_and_update(board, loc, fn current ->
           {current, %Square{current | piece: nil}}
         end) do
      {%Square{piece: nil}, _} -> {:error, :empty_square}
      {%Square{piece: p}, board} -> {:ok, {p, %Game{game | board: board}}}
    end
  end

  defp move_to(%Game{board: board} = game, loc, piece) do
    {%Square{piece: capture}, board} =
      Map.get_and_update(board, loc, fn current ->
        {current, %Square{current | piece: piece}}
      end)

    cond do
      Piece.friendly?(piece, capture) -> {:error, :invalid_to_color}
      true -> {:ok, {capture, %Game{game | board: board}}}
    end
  end
end
