defmodule Elswisser.Repo.Migrations.RemoveGamePlayerRoundUniqueConstraints do
  use Ecto.Migration

  @moduledoc """
  Removes unique constraints on (player_id, round_id) to allow multi-game matches.

  The original constraints prevented the same player from appearing multiple times
  in a round, which made sense for single-game matches. With multi-game match support,
  we need players to be able to play multiple games within the same match in a round.

  Future work: Consider moving player tracking to the match level and adding a
  unique constraint on (player_pairing, round_id) at the match level instead.
  See GitHub issue #142.
  """

  def up do
    drop_if_exists unique_index(:games, [:white_id, :round_id],
                     name: :games_white_id_round_id_unique_idx
                   )

    drop_if_exists unique_index(:games, [:black_id, :round_id],
                     name: :games_black_id_round_id_unique_idx
                   )
  end

  def down do
    # Recreate the constraints with the bye player exclusion from the most recent version
    create unique_index(:games, [:white_id, :round_id],
             name: :games_white_id_round_id_unique_idx,
             where: "white_id != -1"
           )

    create unique_index(:games, [:black_id, :round_id],
             name: :games_black_id_round_id_unique_idx,
             where: "black_id != -1"
           )
  end
end
