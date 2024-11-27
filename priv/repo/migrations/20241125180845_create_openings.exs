defmodule Elswisser.Repo.Migrations.CreateOpenings do
  use Ecto.Migration

  def change do
    create table(:openings) do
      add :eco, :string
      add :name, :string
      add :pgn, :string
    end

    create unique_index(:openings, [:eco, :name, :pgn])

    alter table(:games) do
      add :opening_id, references(:openings)
    end
  end
end
