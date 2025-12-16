defmodule Elswisser.Repo.Migrations.AddTournamentMatchFormat do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      # enum: best_of or first_to
      add :match_format, :string, null: false, default: "best_of"
      add :points_to_win, :integer, null: false, default: 1
      add :allow_draws, :boolean, null: false, default: true
    end
  end
end
