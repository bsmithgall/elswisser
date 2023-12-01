defmodule Elswisser.Matches do
  alias Elswisser.Games.Game
  alias Elswisser.Repo
  alias Elswisser.Matches.Match

  def create_match(attrs \\ %{}) do
    %Match{}
    |> Match.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Given game attributes, create a match and a surrounding game for that match
  """
  def create_match_from_game(attrs, board) do
    {match_attrs, game_attrs} = parse_match_and_game(attrs, board)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:match, %Match{} |> Match.changeset(match_attrs))
    |> Ecto.Multi.merge(fn %{match: match} ->
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:game, Ecto.build_assoc(match, :games, game_attrs))
    end)
    |> Repo.transaction()
  end

  @doc """
  Given an array of game attributes, create matches with a single game inside
  each match.
  """
  def create_matches_from_games(games \\ []) do
    games
    |> Enum.with_index(1)
    |> Enum.reduce(Ecto.Multi.new(), fn {game, idx}, acc ->
      {match_attrs, game_attrs} = parse_match_and_game(game, idx)

      changeset = %Match{} |> Match.changeset(match_attrs)

      multi_id = String.to_atom("match-#{idx}")

      acc
      |> Ecto.Multi.append(
        Ecto.Multi.new()
        |> Ecto.Multi.insert(multi_id, changeset)
        |> Ecto.Multi.merge(fn %{^multi_id => match} ->
          Ecto.Multi.new()
          |> Ecto.Multi.insert({:game, idx}, Ecto.build_assoc(match, :games, game_attrs))
        end)
      )
    end)
    |> Repo.transaction()
  end

  def delete_from_game(%Game{} = game) do
    Repo.delete(%Match{id: game.match_id})
  end

  defp parse_match_and_game(attrs, board) do
    {display_order, game} = Map.pop(attrs, :display_order)
    display_order = if is_nil(display_order), do: board, else: display_order

    {
      %{display_order: display_order, board: board, round_id: game.round_id},
      attrs
    }
  end
end
