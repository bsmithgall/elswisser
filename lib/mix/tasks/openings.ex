defmodule Mix.Tasks.Openings do
  @moduledoc """
  Download and store lichess openings in a sqlite database. Does this by paging
  through the public record TSV files from github and storing them in a database
  (openings.sql).

  The database (which will be completely truncated and rebuilt from scratch on
  each run), will contain a single table `openings`, which will have columns
  `eco`, `name`, and `pgn`. An index will be added on PGN to allow for faster
  searching when back-matching existing games.
  """
  require IEx
  @shortdoc "Download and store opening names from lichess"

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:req)

    Mix.shell().info("Downloading!")
    {:ok, conn} = Exqlite.Sqlite3.open("openings.db")

    :ok =
      Exqlite.Sqlite3.execute(
        conn,
        "CREATE TABLE IF NOT EXISTS openings (fen text, name text, pgn, text)"
      )

    :ok =
      Exqlite.Sqlite3.execute(
        conn,
        "CREATE INDEX IF NOT EXISTS openings_pgn_idx ON openings (pgn)"
      )

    :ok = Exqlite.Sqlite3.execute(conn, "DELETE FROM openings")

    ~w[a b c d e]
    |> Enum.map(&url/1)
    |> Enum.map(fn url ->
      Mix.shell().info("Downloading table from #{url}")
      Req.get!(url).body
    end)
    |> Enum.flat_map(fn body ->
      [_ | data] = String.split(body, "\n")
      data |> Enum.filter(&(&1 != "")) |> Enum.map(&String.split(&1, "\t"))
    end)
    |> Enum.each(fn [fen, name, pgn] ->
      {:ok, statement} =
        Exqlite.Sqlite3.prepare(
          conn,
          "INSERT INTO openings (fen, name, pgn) VALUES (?1, ?2, ?3)"
        )

      :ok = Exqlite.Sqlite3.bind(statement, [fen, name, pgn])
      :done = Exqlite.Sqlite3.step(conn, statement)
      :ok = Exqlite.Sqlite3.release(conn, statement)
      :ok
    end)
  end

  defp url(l) do
    "https://raw.githubusercontent.com/lichess-org/chess-openings/refs/heads/master/#{l}.tsv"
  end
end
