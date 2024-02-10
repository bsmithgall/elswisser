defmodule Elswisser.Tournaments.Stats do
  use Ecto.Schema
  import Ecto.Query, warn: false

  alias __MODULE__

  @primary_key false
  embedded_schema do
    field :opening_name, :string
    field :eco, :string
    field :count, :integer
  end

  def top_openings(query, tournament_id), do: top_openings(query, tournament_id, 5)

  def top_openings(query, tournament_id, limit) do
    from([game: g] in query,
      group_by: g.opening_name,
      where: g.tournament_id == ^tournament_id and not is_nil(g.opening_name),
      select: %Stats{
        opening_name: g.opening_name,
        eco: g.eco,
        count: fragment("count(1) AS count")
      },
      order_by: [desc: fragment("count")],
      limit: ^limit
    )
  end
end
