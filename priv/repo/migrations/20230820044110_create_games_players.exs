defmodule Elswisser.Repo.Migrations.CreateGamePlayer do
  use Ecto.Migration

  def change do
    create table(:game_players) do
      add(:color, :string, null: false)
      add(:game_id, references(:games, on_delete: :nothing), null: false)
      add(:player_id, references(:games, on_delete: :nothing), null: false)
    end

    create(unique_index(:game_players, [:game_id, :player_id]))

    execute("""
    INSERT INTO game_players (game_id, player_id, color)
    SELECT id, white_id, 'white' FROM games
    UNION
    SELECT id, black_id, 'black' FROM games
    """)
  end
end
