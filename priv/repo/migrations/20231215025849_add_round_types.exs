defmodule Elswisser.Repo.Migrations.AddRoundTypes do
  use Ecto.Migration

  def up do
    alter table(:rounds) do
      add :type, :string, default: "none"
      add :display_name, :string
    end

    execute """
    UPDATE rounds SET display_name = r.val
    FROM (SELECT id, 'Round ' || number AS val FROM rounds) AS r
    WHERE rounds.id = r.id
    """
  end

  def down do
    alter table(:rounds) do
      remove :type
      remove :display_name
    end
  end
end
