defmodule Elswisser.Repo.Migrations.SeedAdminUser do
  use Ecto.Migration
  alias Application

  alias Elswisser.Accounts
  alias Elswisser.Accounts.User
  alias Elswisser.Repo

  def up do
    admin_user = Application.fetch_env!(:elswisser, :admin_user)

    Accounts.register_user(%{
      email: admin_user.email,
      password: admin_user.password
    })
  end

  def down do
    Repo.delete_all(User)
  end
end
