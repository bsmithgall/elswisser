defmodule Elchesser.Board do
  alias Elchesser.{Game, Square, Piece, Move}

  @spec move(Elchesser.Game.t(), Elchesser.Move.t()) ::
          {:ok, {Piece.t(), Piece.t?(), Game.t()}} | {:error, atom()}
  def move(%Game{} = game, %Move{} = move) do
    with {:ok, {piece, game}} <- move_from(game, move.from),
         {:ok, {capture, game}} <- move_to(game, move.to, piece),
         {:ok, game} <- castle(game, move),
         {:ok, game} <- promote(game, move) do
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
          {:error, atom()} | {:ok, {Piece.t(), Game.t()}}
  defp move_from(%Game{board: board} = game, loc) do
    case Map.get_and_update(board, loc, fn current ->
           {current, %Square{current | piece: nil}}
         end) do
      {%Square{piece: nil}, _} -> {:error, :empty_square}
      {%Square{piece: p}, board} -> {:ok, {p, %Game{game | board: board}}}
    end
  end

  @spec move_to(Game.t(), {number(), number()}, Piece.t()) ::
          {:ok, {Piece.t?(), Game.t()}} | {:error, atom()}
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

  @spec castle(Game.t(), Move.t()) :: {:ok, Game.t()} | {:error, atom()}
  defp castle(game, %Move{castle: false}), do: {:ok, game}

  defp castle(%Game{} = game, %Move{to: to}) do
    move =
      case to do
        {?g, 1} -> Move.from({?h, 1}, {?f, 1})
        {?g, 8} -> Move.from({?h, 8}, {?f, 8})
        {?c, 1} -> Move.from({?a, 1}, {?d, 1})
        {?c, 8} -> Move.from({?a, 8}, {?d, 8})
      end

    with {:ok, {_, _, game}} <- move(game, move) do
      {:ok, game}
    end
  end

  @spec promote(Game.t(), Move.t()) :: {:ok, Game.t()} | {:error, atom()}
  defp promote(game, %Move{promotion: false}), do: {:ok, game}

  defp promote(%Game{board: board} = game, %Move{to: to, promotion: promotion}) do
    with {_, board} <-
           Map.get_and_update(board, to, fn current ->
             {current, %Square{current | piece: promotion}}
           end) do
      {:ok, %Game{game | board: board}}
    end
  end
end
