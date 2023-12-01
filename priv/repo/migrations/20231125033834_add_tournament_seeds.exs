defmodule Elswisser.Repo.Migrations.AddTournamentSeeds do
  use Ecto.Migration

  def up do
    # sqlite doesn't support altering a table and adding a primary key
    # see: https://www.sqlite.org/lang_altertable.html#otheralter

    # so instead we are making a secondary table, copying data over, and
    # dropping the original
    create table(:tournament_players_v2) do
      add :seed, :integer

      add :player_id, references(:players, on_delete: :delete_all)
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
    end

    execute """
    INSERT INTO tournament_players_v2 (player_id, tournament_id)
    SELECT player_id, tournament_id FROM tournament_players;

    DROP TABLE tournament_players;
    """

    flush()
  end
end
