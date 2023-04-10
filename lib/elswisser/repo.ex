defmodule Elswisser.Repo do
  use Ecto.Repo,
    otp_app: :elswisser,
    adapter: Ecto.Adapters.SQLite3
end
