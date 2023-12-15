defmodule Elswisser.Repo.Migrations.AddRoundTypes do
  use Ecto.Migration

  def up do
    alter table(:rounds) do
      add :type, :string, default: "none"
      add :display_name, :string
    end

    execute """
    UPDATE rounds SET display_name = (SELECT 'ROUND ' || number FROM rounds)
    """
  end

  def down do
    alter table(:rounds) do
      remove :type
      remove :display_name
    end
  end
end
