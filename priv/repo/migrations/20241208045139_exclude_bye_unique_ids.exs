defmodule Elswisser.Repo.Migrations.ExcludeByeUniqueIds do
  use Ecto.Migration

  def up do
    drop unique_index(:games, [:white_id, :round_id], name: :games_white_id_round_id_unique_idx)

    create unique_index(:games, [:white_id, :round_id],
             name: :games_white_id_round_id_unique_idx,
             where: "white_id != -1"
           )

    drop unique_index(:games, [:black_id, :round_id], name: :games_black_id_round_id_unique_idx)

    create unique_index(:games, [:black_id, :round_id],
             name: :games_black_id_round_id_unique_idx,
             where: "black_id != -1"
           )
  end

  def down do
    drop unique_index(:games, [:white_id, :round_id], name: :games_white_id_round_id_unique_idx)
    create unique_index(:games, [:white_id, :round_id], name: :games_white_id_round_id_unique_idx)
    drop unique_index(:games, [:black_id, :round_id], name: :games_black_id_round_id_unique_idx)
    create unique_index(:games, [:black_id, :round_id], name: :games_black_id_round_id_unique_idx)
  end
end
