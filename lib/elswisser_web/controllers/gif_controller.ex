defmodule ElswisserWeb.GifController do
  use ElswisserWeb, :controller

  require Logger

  alias Elswisser.Games
  alias Elswisser.Games.{GameGif, PgnProvider}

  def show(conn, %{"url" => url}) do
    with {:ok, provider} <- PgnProvider.find_provider(url),
         {:ok, pgn} <- provider.fetch_pgn(url) do
      send_gif(conn, pgn)
    else
      {:error, reason} when is_binary(reason) -> send_resp(conn, 422, reason)
      {:error, reason} -> send_resp(conn, 422, inspect(reason))
    end
  end

  def game(conn, %{"id" => id}) do
    case Games.get_game(id) do
      nil -> send_resp(conn, 404, "Game not found")
      %{pgn: nil} -> send_resp(conn, 422, "No PGN available")
      game -> send_gif(conn, game.pgn)
    end
  end

  defp send_gif(conn, pgn) when is_binary(pgn) do
    with {:ok, game, parse_ms} <- timed(fn -> Elchesser.Pgn.parse(pgn) end),
         {:ok, gif, encode_ms} <- timed(fn -> GameGif.encode(game.fens, 70) end) do
      Logger.info(
        "GIF generated " <>
          "frames=#{length(game.fens)} " <>
          "size=#{Float.round(byte_size(gif) / 1024, 1)}kB " <>
          "parse=#{parse_ms}ms " <>
          "encode=#{encode_ms}ms"
      )

      :telemetry.execute(
        [:elswisser, :gif, :encode],
        %{duration: encode_ms * 1000, size: byte_size(gif), frames: length(game.fens)}
      )

      conn
      |> put_resp_content_type("image/gif")
      |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
      |> send_resp(200, gif)
    else
      {:error, reason} when is_binary(reason) ->
        Logger.error("GIF generation failed: #{reason}")
        send_resp(conn, 422, reason)

      {:error, reason} ->
        Logger.error("GIF generation failed: #{inspect(reason)}")
        send_resp(conn, 422, "GIF generation failed")
    end
  end

  defp timed(fun) do
    {us, result} = :timer.tc(fun)

    case result do
      {:ok, val} -> {:ok, val, div(us, 1000)}
      {:error, _} = err -> err
    end
  end
end
