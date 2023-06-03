defmodule Elswisser.Repo.Migrations.AddRoundStatus do
  use Ecto.Migration

  def change do
    alter table("rounds") do
      add :status, :string
    end
  end
end
