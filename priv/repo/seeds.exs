# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Elswisser.Repo.insert!(%Elswisser.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query
alias Elswisser.Repo
alias Elswisser.Players
alias Elswisser.Tournaments
alias Elswisser.Rounds
alias Elswisser.Players.Player

# Generate twelve players
for name <- [
      "Luke Skywalker",
      "Han Solo",
      "Leia Skywalker",
      "Darth Vader",
      "C3PO",
      "R2D2",
      "Chewbacca",
      "Yoda",
      "Emporer Palpatine",
      "Jabba the Hut",
      "Bobba Fett",
      "Obi-Wan Kenobi"
    ] do
  Players.create_player(%{name: name, rating: Enum.random(800..2200)})
end

# Generate two tournaments with all the players
for name <- ["Now THIS is Podracing", "Mos Eisley Cantina Championship 2023"] do
  player_ids = Repo.all(from p in Player, select: p.id)

  Tournaments.create_tournament(%{name: name, player_ids: player_ids})
end

# Fill in tournament number one with games

# Fill in tournament two with one round of games
