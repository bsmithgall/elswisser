defmodule Elswisser.Matches.Match do
  require Elswisser.Pairings.Bye
  alias Elswisser.Pairings.Bye
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  schema "matches" do
    field :board, :integer
    field :display_order, :integer

    belongs_to(:winner_to, __MODULE__)
    belongs_to(:loser_to, __MODULE__)

    belongs_to(:winner, Elswisser.Players.Player)

    belongs_to(:round, Elswisser.Rounds.Round)
    has_many(:games, Elswisser.Games.Game)

    timestamps()
  end

  @doc false
  def changeset(match, attrs \\ %{}) do
    match
    |> cast(attrs, [:board, :display_order, :round_id, :loser_to_id, :winner_to_id])
    |> validate_required([:board, :display_order, :round_id])
  end

  def from() do
    from(m in __MODULE__, as: :match)
  end

  def where_id(query, ids) when is_list(ids) do
    from([match: m] in query, where: m.id in ^ids)
  end

  def where_tournament_id(query, tournament_id) do
    from([match: m] in query,
      join: r in assoc(m, :round),
      join: t in assoc(r, :tournament),
      where: t.id == ^tournament_id
    )
  end

  def with_round(query) do
    from([match: m] in query, join: r in assoc(m, :round), as: :round)
  end

  def with_games(query), do: with_games(query, false)

  def with_games(query, false) do
    from([match: m] in query, left_join: g in assoc(m, :games), as: :game)
  end

  def preload_games(query) do
    from([game: g] in query, preload: [games: g])
  end

  def preload_games_and_players(query) do
    from([game: g, white: w, black: b] in query, preload: [games: {g, black: b, white: w}])
  end

  def preload_round(query) do
    from([round: r] in query, preload: [round: r])
  end

  def order_by_display_number(query) do
    from([match: m] in query, order_by: [asc: m.display_order])
  end

  def first_game_or_nil(nil), do: nil

  def first_game_or_nil(%__MODULE__{} = match) do
    Enum.at(match.games, 0)
  end

  def result(%__MODULE__{} = match) do
    case match.games
         |> Enum.map(& &1.result)
         |> Enum.sum() do
      n when n > 0 ->
        {{hd(match.games).white, hd(match.games).white_seed},
         {hd(match.games).black, hd(match.games).black_seed}}

      n when n < 0 ->
        {{hd(match.games).black, hd(match.games).black_seed},
         {hd(match.games).white, hd(match.games).white_seed}}

      0 when Bye.bye_player?(hd(match.games).white) ->
        {{hd(match.games).black, hd(match.games).black_seed},
         {hd(match.games).white, hd(match.games).white_seed}}

      0 when Bye.bye_player?(hd(match.games).black) ->
        {{hd(match.games).white, hd(match.games).white_seed},
         {hd(match.games).black, hd(match.games).black_seed}}

      _ ->
        {nil, nil}
    end
  end

  def winner(%__MODULE__{} = match), do: result(match) |> elem(0)
  def loser(%__MODULE__{} = match), do: result(match) |> elem(1)

  defmodule Mini do
    @moduledoc """
    Mini projection of fields needed for displaying match pairings and generating alerts
    """
    use Ecto.Schema
    import Ecto.Query, warn: false

    alias Elswisser.Players.Player

    @primary_key false
    embedded_schema do
      field :id, :integer
      field :round_id, :integer
      field :round_display_name, :string
      embeds_one :white, Players.Mini
      embeds_one :black, Players.Mini
    end

    def select_into(query) do
      from([match: m, round: r, game: g, white: w, black: b] in query,
        select: %__MODULE__{
          id: m.id,
          round_id: r.id,
          round_display_name: r.display_name,
          white: %Player.Mini{
            name: w.name,
            rating: w.rating,
            chesscom: w.chesscom,
            lichess: w.lichess,
            slack_id: w.slack_id
          },
          black: %Player.Mini{
            name: b.name,
            rating: b.rating,
            chesscom: b.chesscom,
            lichess: b.lichess,
            slack_id: b.slack_id
          }
        }
      )
    end
  end
end
