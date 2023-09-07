defmodule Elswisser.Repo.Migrations.AddGamesFinishedAt do
  use Ecto.Migration

  def change do
    alter table("games") do
      add :finished_at, :utc_datetime
    end

    execute """
    UPDATE games SET finished_at = updated_at
    """
  end
end
