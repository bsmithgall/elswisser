defmodule Elswisser.Repo.Migrations.AddGamePlayerSeeds do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:white_seed, :integer)
      add(:black_seed, :intger)
    end
  end
end
