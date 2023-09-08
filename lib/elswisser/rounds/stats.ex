defmodule Elswisser.Rounds.Stats do
  use Ecto.Schema
  import Ecto.Query, warn: false

  alias Elswisser.Rounds.Round
  alias __MODULE__

  @primary_key false
  embedded_schema do
    field :white_wins, :integer, default: 0
    field :black_wins, :integer, default: 0
    field :draws, :integer, default: 0
    field :upsets, :integer, default: 0
    field :total, :integer, default: 0

    embeds_one :round, Round
  end

  def compute(query) do
    from([game: g, round: r, white: w, black: b] in query,
      group_by: r.id,
      select: %Stats{
        round: r,
        white_wins: sum(fragment("CASE WHEN result = 1 THEN 1 ELSE 0 END")),
        black_wins: sum(fragment("CASE WHEN result = -1 THEN 1 ELSE 0 END")),
        draws: sum(fragment("CASE WHEN result = 0 THEN 1 ELSE 0 END")),
        upsets:
          sum(
            fragment(
              """
                CASE WHEN (result = 1 AND ?) OR (result = -1 AND ?) THEN 1 ELSE 0 END
              """,
              b.rating > w.rating,
              w.rating > b.rating
            )
          ),
        total: count(1)
      }
    )
  end

  def combine(%Stats{} = l, %Stats{} = r) do
    Stats.__schema__(:fields)
    |> Enum.filter(fn f -> Stats.__schema__(:type, f) == :integer end)
    |> Enum.reduce(%Stats{}, fn f, acc ->
      Map.put(acc, f, Map.get(l, f) + Map.get(r, f))
    end)
  end
end
