defmodule Elswisser.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add(:white_id, references(:players))
      add(:black_id, references(:players))
      add(:result, :integer)
      add(:round_id, references(:rounds, on_delete: :delete_all), null: false)
      add(:tournament_id, references(:tournaments, on_delete: :delete_all), null: false)
      add(:game_link, :string)
      add(:pgn, :string)

      timestamps()
    end

    create(index(:games, [:round_id]))
  end
end
