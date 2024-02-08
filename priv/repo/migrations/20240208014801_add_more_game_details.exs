defmodule Elswisser.Repo.Migrations.AddMoreGameDetails do
  use Ecto.Migration

  alias Elswisser.Repo

  import Ecto.Query

  def change do
    alter table(:games) do
      add :eco, :string
      add :opening_name, :string
    end

    flush()

    games =
      from(g in "games", select: %{id: g.id, pgn: g.pgn}, where: not is_nil(g.pgn)) |> Repo.all()

    for g <- games do
      {eco, opening_name} = Elswisser.Games.PgnTagParser.parse_eco(g.pgn)

      from(g in "games",
        where: g.id == ^g.id,
        update: [set: [eco: ^eco, opening_name: ^opening_name]]
      )
      |> Repo.update_all([])
    end
  end
end
