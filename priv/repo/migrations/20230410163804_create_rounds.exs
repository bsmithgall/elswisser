defmodule Elswisser.Repo.Migrations.CreateRounds do
  use Ecto.Migration

  def change do
    create table(:rounds) do
      add :number, :integer, null: false
      add :tournament_id, references(:tournaments, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:rounds, [:tournament_id])
    create unique_index(:rounds, [:number, :tournament_id])
  end
end
