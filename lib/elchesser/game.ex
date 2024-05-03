defmodule Elchesser.Game do
  defstruct board: %{},
            active: :w,
            castling: MapSet.new([:K, :Q, :k, :q]),
            en_passant: nil,
            half_clock: 0,
            full_moves: 1

  alias __MODULE__

  @type t :: %Game{}

  @spec empty() :: Elchesser.Game.t()
  def empty() do
    board =
      for file <- Elchesser.files(), rank <- Elchesser.ranks(), reduce: %{} do
        acc -> Map.put(acc, {file, rank}, nil)
      end

    %Game{board: board}
  end

  def get_square(%Game{board: board}, {file, rank}), do: Map.get(board, {file, rank})
end
