defmodule Elswisser.Repo.Migrations.AddTournamentTypes do
  use Ecto.Migration

  def change do
    alter table("tournaments") do
      add :type, :string, null: false, default: "swiss"
    end
  end
end
