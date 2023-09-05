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

alias Elswisser.Repo
alias Elswisser.Players
alias Elswisser.Tournaments
alias Elswisser.Tournaments.Tournament
alias Elswisser.Rounds
require Logger

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
      "Emperor Palpatine",
      "Jabba the Hut",
      "Bobba Fett",
      "Obi-Wan Kenobi"
    ] do
  Players.create_player(%{name: name, rating: Enum.random(800..2200)})
end

players = Players.list_players()

# Generate two tournaments with all the players
for name <- ["Now THIS is Podracing", "Mos Eisley Cantina Championship 2023"] do
  player_ids = for p <- players, do: p.id
  Tournaments.create_tournament(%{name: name, player_ids: player_ids})
end

for tourn <- Repo.all(Tournament) do
  len =
    case tourn.name do
      "Now THIS is Podracing" -> tourn.length
      _ -> 1
    end

  for number <- 0..(len - 1) do
    case Rounds.create_round(%{tournament_id: tourn.id, number: number + 1, status: :complete}) do
      {:ok, rnd} ->
        for pair <- Enum.shuffle(players) |> Enum.chunk_every(2) do
          [white, black] = pair

          game = %{
            white_id: white.id,
            black_id: black.id,
            result: Enum.random([-1, 0, 1]),
            tournament_id: tourn.id,
            round_id: rnd.id
          }

          Rounds.add_game(rnd, game)
        end

      {:error, changeset} ->
        Logger.error("Failed to create a round! #{changeset}")
        exit(:shutdown)
    end
  end
end

Logger.info("Done!")
