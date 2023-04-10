defmodule Elswisser.Repo.Migrations.CreateTournaments do
  use Ecto.Migration

  def change do
    create table(:tournaments) do
      add :name, :string, null: false

      timestamps()
    end
  end
end
