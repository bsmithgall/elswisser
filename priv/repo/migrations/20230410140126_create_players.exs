defmodule Elswisser.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :name, :string, null: false
      add :rating, :integer, null: false

      timestamps()
    end
  end
end
