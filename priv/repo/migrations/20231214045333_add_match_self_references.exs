defmodule Elswisser.Repo.Migrations.AddMatchSelfReferences do
  use Ecto.Migration

  def change do
    alter table(:matches) do
      add :winner_id, references(:players)

      add :winner_to_id, references(:matches)
      add :loser_to_id, references(:matches)
    end
  end
end
