defmodule Elswisser.Repo.Migrations.TrackRatingChanges do
  use Ecto.Migration

  def change do
    alter table("games") do
      add :white_rating_change, :integer, default: 0
      add :black_rating_change, :integer, default: 0
    end
  end
end
