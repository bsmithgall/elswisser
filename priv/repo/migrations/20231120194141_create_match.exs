defmodule Elswisser.Repo.Migrations.CreateMatch do
  alias Elswisser.Matches.Match
  alias Elswisser.Repo
  use Ecto.Migration

  import Ecto.Query

  def up do
    create table(:matches) do
      add :board, :integer
      add :display_order, :integer

      add(:round_id, references(:rounds, on_delete: :delete_all))
      add(:winner_id, references(:players))
      add(:winner_to_id, references(:matches))
      add(:loser_to_id, references(:matches))

      timestamps()
    end

    flush()

    alter table(:games) do
      add :match_id, references(:matches, on_delete: :delete_all)
    end

    flush()

    # There's probably a less dumb way to do this but it's my app it can be bad
    # if I want

    # get all the tournaments
    tournaments = from(t in "tournaments", select: t.id, order_by: t.id) |> Repo.all()

    for t <- tournaments do
      # for each tournament, get all the rounds
      rnds = from(r in "rounds", where: r.tournament_id == ^t, select: r.id) |> Repo.all()

      for r <- rnds do
        # for each round, get all the games
        games =
          from(g in "games", where: g.tournament_id == ^t and g.round_id == ^r, select: g.id)
          |> Repo.all()

        # for each game, we need to create a match, and then link that match to
        # the game in question
        Enum.with_index(games)
        |> Enum.map(fn {g, idx} ->
          {
            Match.changeset(%Match{}, %{round_id: r, board: idx, display_order: idx}),
            g
          }
        end)
        |> Enum.map(fn {changeset, g} -> {Repo.insert!(changeset), g} end)
        |> Enum.map(fn {match, g} ->
          from(g in Elswisser.Games.Game, where: g.id == ^g, update: [set: [match_id: ^match.id]])
          |> Repo.update_all([])
        end)
      end
    end

    create index(:matches, [:round_id])
    create index(:games, [:match_id])
  end

  def down do
    drop index(:matches, [:round_id])
    drop index(:games, [:match_id])

    alter table(:games) do
      remove :match_id
    end

    drop table(:matches)
  end
end
