defmodule Elswisser.Repo.Migrations.CreateTournamentPlayers do
  use Ecto.Migration

  def change do
    create table(:tournament_players, primary_key: false) do
      add :player_id, references(:players, on_delete: :delete_all)
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
    end

    create index(:tournament_players, [:tournament_id])
    create unique_index(:tournament_players, [:player_id, :tournament_id])
  end
end
