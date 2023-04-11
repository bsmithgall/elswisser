defmodule Elswisser.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :white, references(:players)
      add :black, references(:players)
      add :result, :integer
      add :round_id, references(:rounds, on_delete: :delete_all), null: false
      add :game_link, :string

      timestamps()
    end

    create index(:games, [:round_id])
  end
end
