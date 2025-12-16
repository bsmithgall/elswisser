defmodule Elswisser.Repo.Migrations.RemoveSeedsFromGames do
  use Ecto.Migration

  def up do
    alter table(:games) do
      remove :white_seed
      remove :black_seed
    end
  end

  def down do
    alter table(:games) do
      add :white_seed, :integer
      add :black_seed, :integer
    end

    # Backfill from match player seeds
    execute """
    UPDATE games SET
      white_seed = (
        SELECT CASE
          WHEN games.white_id = matches.player_one_id THEN matches.player_one_seed
          WHEN games.white_id = matches.player_two_id THEN matches.player_two_seed
        END
        FROM matches WHERE matches.id = games.match_id
      ),
      black_seed = (
        SELECT CASE
          WHEN games.black_id = matches.player_one_id THEN matches.player_one_seed
          WHEN games.black_id = matches.player_two_id THEN matches.player_two_seed
        END
        FROM matches WHERE matches.id = games.match_id
      )
    WHERE EXISTS (SELECT 1 FROM matches WHERE matches.id = games.match_id)
    """
  end
end
