defmodule Elswisser.Repo.Migrations.AddPlayerSlackId do
  use Ecto.Migration

  def change do
    alter table(:players) do
      add :slack_id, :string
    end
  end
end
