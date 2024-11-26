defmodule Elswisser.Games.OpeningNameParser do
  @moduledoc """
  Given a PGN, walk backwards through the moves to find a matching opening. If
  no opening can be found after exhausting all moves, default to the ECO-code
  based matching found in the PgnTagProvider.
  """
  alias Elswisser.Games.PgnTagParser

  @spec get_name(Elswisser.Games.t(), MapSet.t(binary())) :: binary()
  def get_name(game, names) do
    ""
  end

  defp get_name(%Elchesser.Game{moves: []}, %Elswisser.Games.Game{pgn: pgn}, _) do
    PgnTagParser.parse_eco(pgn)
  end

  defp get_name(%Elchesser.Game{moves: moves}, _, %MapSet{} = names) do
  end

  defp to_move_list(%Elchesser.Game{moves: moves}) do
    moves |> Enum.map(&Elchesser.Move.san/1)
  end
end
