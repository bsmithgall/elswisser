defmodule Elswisser.Repo.Migrations.AddLengthToTournament do
  use Ecto.Migration

  def change do
    alter table("tournaments") do
      add :length, :integer
    end
  end
end
