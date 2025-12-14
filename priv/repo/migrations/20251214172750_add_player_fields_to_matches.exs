defmodule Elswisser.Repo.Migrations.AddPlayerFieldsToMatches do
  use Ecto.Migration

  def up do
    alter table(:matches) do
      add :player_one_id, references(:players, on_delete: :nothing)
      add :player_two_id, references(:players, on_delete: :nothing)
      add :player_one_seed, :integer
      add :player_two_seed, :integer
    end

    create index(:matches, [:player_one_id])
    create index(:matches, [:player_two_id])

    # Backfill from first game of each match (ordered by id to get the first one)
    # Using SQLite-compatible syntax with subqueries
    execute """
    UPDATE matches SET
      player_one_id = (
        SELECT white_id FROM games
        WHERE games.match_id = matches.id
        ORDER BY games.id LIMIT 1
      ),
      player_two_id = (
        SELECT black_id FROM games
        WHERE games.match_id = matches.id
        ORDER BY games.id LIMIT 1
      ),
      player_one_seed = (
        SELECT white_seed FROM games
        WHERE games.match_id = matches.id
        ORDER BY games.id LIMIT 1
      ),
      player_two_seed = (
        SELECT black_seed FROM games
        WHERE games.match_id = matches.id
        ORDER BY games.id LIMIT 1
      )
    WHERE EXISTS (
      SELECT 1 FROM games WHERE games.match_id = matches.id
    )
    """
  end

  def down do
    drop index(:matches, [:player_one_id])
    drop index(:matches, [:player_two_id])

    alter table(:matches) do
      remove :player_one_id
      remove :player_two_id
      remove :player_one_seed
      remove :player_two_seed
    end
  end
end
