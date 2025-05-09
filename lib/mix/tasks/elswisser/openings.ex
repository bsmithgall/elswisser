defmodule Mix.Tasks.Elswisser.Openings do
  @moduledoc """
  Download and store lichess openings in a sqlite database. Does this by paging
  through the public record TSV files from github and storing them in a database
  (openings.sql).

  The database (which will be completely truncated and rebuilt from scratch on
  each run), will contain a single table `openings`, which will have columns
  `eco`, `name`, and `pgn`. An index will be added on PGN to allow for faster
  searching when back-matching existing games.
  """
  @shortdoc "Download and store opening names from lichess"

  use Mix.Task

  @requirements ["app.start"]

  alias Elswisser.Openings.Opening
  import Ecto.Query

  @impl Mix.Task
  def run(_args), do: run()

  def run() do
    {:ok, _} = Application.ensure_all_started(:req)

    ~w[a b c d e]
    |> Enum.map(&url/1)
    |> Enum.map(fn url ->
      IO.puts("Downloading table from #{url}")
      Req.get!(url).body
    end)
    |> Enum.flat_map(fn body ->
      [_ | data] = String.split(body, "\n")

      data
      |> Enum.filter(&(&1 != ""))
      |> Enum.map(&String.split(&1, "\t"))
    end)
    |> Enum.map(&List.to_tuple/1)
    |> Enum.reduce(Ecto.Multi.new(), fn {eco, name, pgn}, multi ->
      Ecto.Multi.insert(
        multi,
        %{eco: eco, name: name, pgn: pgn},
        Opening.changeset(%Opening{}, %{eco: eco, name: name, pgn: pgn}),
        on_conflict: :nothing
      )
    end)
    |> Elswisser.Repo.transaction()

    IO.puts("Openings loaded, attaching to current games!")

    from(g in Elswisser.Games.Game, where: not is_nil(g.pgn) and is_nil(g.opening_id))
    |> Elswisser.Repo.all()
    |> Enum.reduce(Ecto.Multi.new(), fn %Elswisser.Games.Game{} = game, multi ->
      try do
        {:ok, opening} = Elswisser.Openings.find_from_game(game)

        Ecto.Multi.update(
          multi,
          game.id,
          Elswisser.Games.Game.changeset(game, %{opening_id: opening.id})
        )
      rescue
        _ ->
          IO.puts("Bad game: #{game.id}")
          multi
      end
    end)
    |> Elswisser.Repo.transaction()
  end

  defp url(l) do
    "https://raw.githubusercontent.com/lichess-org/chess-openings/refs/heads/master/#{l}.tsv"
  end
end
