defimpl Inspect, for: Elchesser.Game do
  @middle "\n  ├───┼───┼───┼───┼───┼───┼───┼───┤\n"

  @spec inspect(Elchesser.Game.t(), Inspect.Opts.t()) :: Inspect.Algebra.t()
  def inspect(%Elchesser.Game{} = game, _opts) do
    for rank <- Elchesser.ranks(), file <- Elchesser.files() do
      Map.get(game.board, {file, rank}) |> Elchesser.Square.piece_display() |> then(&"│ #{&1} ")
    end
    |> Enum.chunk_every(8)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(&draw(&1))
    |> Enum.concat(["    a   b   c   d   e   f   g   h"])
    |> Inspect.Algebra.concat()
  end

  @spec draw({String.t(), number()}) :: Inspect.Algebra.t()
  defp draw({row, 0}) do
    Inspect.Algebra.concat([
      "  ┌───┬───┬───┬───┬───┬───┬───┬───┐\n",
      draw_rank({row, 0}),
      @middle
    ])
  end

  defp draw({row, 7}) do
    Inspect.Algebra.concat(draw_rank({row, 7}), "\n  └───┴───┴───┴───┴───┴───┴───┴───┘\n")
  end

  defp draw({row, rankIdx}) do
    Inspect.Algebra.concat(draw_rank({row, rankIdx}), @middle)
  end

  defp draw_rank({row, rankIdx}),
    do: ["#{8 - rankIdx} " | row] |> Enum.join("") |> then(&"#{&1}│")
end
