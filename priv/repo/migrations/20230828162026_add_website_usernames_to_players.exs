defmodule Elswisser.Repo.Migrations.AddWebsiteUsernamesToPlayers do
  use Ecto.Migration

  def change do
    alter table("players") do
      add :chesscom, :string
      add :lichess, :string
    end
  end
end
