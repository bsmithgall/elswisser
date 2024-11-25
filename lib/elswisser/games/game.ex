defmodule Elswisser.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  require Elswisser.Pairings.Bye
  alias Elswisser.Pairings.Bye
  alias Elswisser.Games.PgnProvider
  alias Elswisser.Games.Game
  alias Elswisser.Players.Player

  schema "games" do
    field(:game_link, :string)
    field(:pgn, :string)
    field(:eco, :string)
    field(:opening_name, :string)
    field(:result, :integer)
    field(:finished_at, :utc_datetime)
    field(:white_rating, :integer, default: 0)
    field(:black_rating, :integer, default: 0)
    field(:white_rating_change, :integer, default: 0)
    field(:black_rating_change, :integer, default: 0)
    field(:white_seed, :integer)
    field(:black_seed, :integer)

    belongs_to(:round, Elswisser.Rounds.Round)
    belongs_to(:match, Elswisser.Matches.Match)
    belongs_to(:tournament, Elswisser.Tournaments.Tournament)
    belongs_to(:white, Elswisser.Players.Player)
    belongs_to(:black, Elswisser.Players.Player)

    timestamps()
  end

  @doc false
  def changeset(game, attrs \\ %{}) do
    game
    |> cast(attrs, [
      :black_id,
      :black_rating,
      :black_rating_change,
      :black_seed,
      :finished_at,
      :game_link,
      :match_id,
      :pgn,
      :eco,
      :opening_name,
      :result,
      :round_id,
      :tournament_id,
      :white_id,
      :white_rating,
      :white_rating_change,
      :white_seed
    ])
    |> validate_required([:round_id, :tournament_id, :match_id])
    |> validate_different_players()
    |> validate_game_link()
    |> unique_constraint(:unique_white_players, name: :games_white_id_round_id_unique_idx)
    |> unique_constraint(:unique_black_players, name: :games_black_id_round_id_unique_idx)
    |> prepare_changes(fn cs ->
      if get_change(cs, :white_id) == -1 or get_change(cs, :black_id) == -1 do
        put_change(cs, :result, 0)
      else
        cs
      end
    end)
  end

  def link_changeset(game, attrs \\ %{}) do
    game |> cast(attrs, [:game_link]) |> validate_game_link()
  end

  def from() do
    from(g in Game, as: :game)
  end

  def where_id(query, id) do
    from(g in query, where: g.id == ^id)
  end

  def where_tournament_id(query, tournament_id) do
    from([game: g] in query, where: g.tournament_id == ^tournament_id)
  end

  def where_round_id(query, round_id) do
    from(g in query, where: g.round_id == ^round_id)
  end

  def where_player_id(query, player_id) do
    from([game: g] in query, where: g.white_id == ^player_id or g.black_id == ^player_id)
  end

  def where_not_bye(query) do
    id = Bye.bye_player_id()

    from(
      [game: g] in query,
      where: g.white_id != ^id and g.black_id != ^id
    )
  end

  def where_unfinished(query) do
    from([game: g] in query, where: is_nil(g.result))
  end

  def where_finished(query) do
    from([game: g] in query, where: not is_nil(g.result))
  end

  def where_both_players(query) do
    from([game: g] in query, where: not is_nil(g.white_id) and not is_nil(g.black_id))
  end

  def with_both_players(query) do
    query |> with_white_player() |> with_black_player()
  end

  def with_white_player(query) do
    from([game: g] in query,
      left_join: w in assoc(g, :white),
      as: :white
    )
  end

  def with_black_player(query) do
    from([game: g] in query,
      left_join: b in assoc(g, :black),
      as: :black
    )
  end

  def preload_players(query) do
    from([game: g, white: w, black: b] in query, preload: [white: w, black: b])
  end

  def count(query) do
    from(query, select: count())
  end

  def select_white_id(query) do
    from([game: g] in query, select: g.white_id)
  end

  def select_black_id(query) do
    from([game: g] in query, select: g.black_id)
  end

  def count_white_games(query, player_ids) do
    from([game: g] in query,
      where: g.white_id in ^player_ids,
      group_by: g.white_id,
      select: %{id: g.white_id, ct: count(g.id)}
    )
  end

  def count_black_games(query, player_ids) do
    from([game: g] in query,
      where: g.black_id in ^player_ids,
      group_by: g.black_id,
      select: %{id: g.black_id, ct: count(g.id)}
    )
  end

  def most_recent_first(query) do
    from([game: g] in query, order_by: [desc_nulls_last: g.finished_at])
  end

  @doc """
  Given a game and an existing roster, load a :white and :black player. We do it
  this way because we don't really have an easy way of doing this with a
  preloads from a query unfortunately; since we have multiple :belongs_to, there
  isn't really a clean way of dealing with it.
  """
  def load_players_from_roster(%Game{} = game, roster) when is_list(roster) do
    from_roster =
      Enum.reduce(roster, %{}, fn
        white, acc when white.id == game.white_id -> Map.put(acc, :white, white)
        black, acc when black.id == game.black_id -> Map.put(acc, :black, black)
        _, acc -> acc
      end)

    Map.merge(game, from_roster)
  end

  def white_score(%Game{} = game) do
    case game.result do
      -1 -> 0
      0 -> 0.5
      1 -> 1
      nil -> 0
    end
  end

  def white_result(%Game{} = game) do
    if complete?(game), do: white_score(game), else: nil
  end

  def black_score(%Game{} = game) do
    case game.result do
      -1 -> 1
      0 -> 0.5
      1 -> 0
      nil -> 0
    end
  end

  def black_result(%Game{} = game) do
    if complete?(game), do: black_score(game), else: nil
  end

  def complete?(%Game{} = game) do
    !(is_nil(game.result) and is_nil(game.finished_at))
  end

  def take_seat(%Game{white_id: nil, black_id: nil}, %Player{} = player, player_seed) do
    case Enum.random(0..1) do
      0 ->
        %{black_id: player.id, black_rating: player.rating, black_seed: player_seed}

      1 ->
        %{white_id: player.id, white_rating: player.rating, white_seed: player_seed}
    end
  end

  def take_seat(%Game{black_id: nil, white_id: _}, %Player{} = player, player_seed) do
    %{black_id: player.id, black_rating: player.rating, black_seed: player_seed}
  end

  def take_seat(%Game{white_id: nil, black_id: _}, %Player{} = player, player_seed) do
    %{white_id: player.id, white_rating: player.rating, white_seed: player_seed}
  end

  def take_seat(
        %Player{} = player_one,
        player_one_seed,
        %Player{} = player_two,
        player_two_seed
      ) do
    %{
      black_id: player_one.id,
      black_rating: player_one.rating,
      black_seed: player_one_seed,
      white_id: player_two.id,
      white_rating: player_two.rating,
      white_seed: player_two_seed
    }
  end

  def bye?(%Game{white: nil}), do: false
  def bye?(%Game{black: nil}), do: false

  def bye?(%Game{} = game) do
    Bye.bye_player?(game.white) or Bye.bye_player?(game.black)
  end

  def playable?(%Game{} = game) do
    not is_nil(game.white_id) and not is_nil(game.black_id)
  end

  def validate_game_link(changeset) do
    validate_change(changeset, :game_link, fn
      :game_link, nil ->
        []

      :game_link, game_link ->
        with {:ok, provider} <- PgnProvider.find_provider(game_link),
             {:ok, _link} <- provider.extract_id(game_link) do
          []
        else
          {:error, _} -> [game_link: "Invalid game link"]
        end
    end)
  end

  defp validate_different_players(changeset) do
    white_id = get_field(changeset, :white_id)
    black_id = get_field(changeset, :black_id)

    cond do
      is_nil(white_id) or is_nil(black_id) -> changeset
      white_id == black_id -> add_error(changeset, :white_id, "A player cannot play themselves!")
      true -> changeset
    end
  end
end
