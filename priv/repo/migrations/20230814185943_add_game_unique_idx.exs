defmodule Elswisser.Repo.Migrations.AddGameUniqueIdx do
  use Ecto.Migration

  def change do
    create unique_index(:games, [:white_id, :round_id], name: :games_white_id_round_id_unique_idx)
    create unique_index(:games, [:black_id, :round_id], name: :games_black_id_round_id_unique_idx)
  end
end
