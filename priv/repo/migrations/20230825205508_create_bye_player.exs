defmodule Elswisser.Repo.Migrations.CreateByePlayer do
  use Ecto.Migration

  def up do
    now = DateTime.utc_now()

    execute """
    INSERT INTO players (id, name, rating, inserted_at, updated_at)
    VALUES (-1, '-- BYE --', -1, '#{now}', '#{now}')
    """
  end

  def down do
    execute """
    DELETE FROM games WHERE white_id = -1 OR black_id = -1;
    """

    execute """
    DELETE FROM players WHERE id = -1;
    """
  end
end
