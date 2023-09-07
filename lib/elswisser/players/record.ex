defmodule Elswisser.Players.Record do
  use Ecto.Schema
  import Ecto.Query, warn: false

  @primary_key false
  embedded_schema do
    field :wins, :integer, default: 0
    field :draws, :integer, default: 0
    field :losses, :integer, default: 0
  end

  def calculate_record(query, player_id) do
    from([game: g] in query,
      select: %Elswisser.Players.Record{
        draws: fragment("SUM(CASE WHEN result = 0 THEN 1 ELSE 0 END)"),
        wins:
          fragment(
            "SUM(CASE WHEN white_id = ? AND result = 1 OR black_id = ? AND result = -1 THEN 1 ELSE 0 END)",
            ^player_id,
            ^player_id
          ),
        losses:
          fragment(
            "SUM(CASE WHEN white_id = ? AND result = -1 OR black_id = ? AND result = 1 THEN 1 ELSE 0 END)",
            ^player_id,
            ^player_id
          )
      }
    )
  end
end
