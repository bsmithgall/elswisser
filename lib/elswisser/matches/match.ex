defmodule Elswisser.Matches.Match do
  require Elswisser.Pairings.Bye
  alias Elswisser.Pairings.Bye
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  schema "matches" do
    field :board, :integer
    field :display_order, :integer

    belongs_to(:round, Elswisser.Rounds.Round)
    has_many(:games, Elswisser.Games.Game)

    timestamps()
  end

  @doc false
  def changeset(match, attrs) do
    match
    |> cast(attrs, [:board, :display_order, :round_id])
    |> validate_required([:board, :display_order, :round_id])
  end

  def from() do
    from(m in __MODULE__, as: :match)
  end

  def with_games(query) do
    from([match: m] in query, left_join: g in assoc(m, :games), as: :game)
  end

  def order_by_display_number(query) do
    from([match: m] in query, order_by: [asc: m.display_order])
  end

  def first_game_or_nil(nil), do: nil

  def first_game_or_nil(%__MODULE__{} = match) do
    Enum.at(match.games, 0)
  end

  def winner(%__MODULE__{} = match) do
    case match.games
         |> Enum.map(& &1.result)
         |> Enum.sum() do
      n when n > 0 ->
        {hd(match.games).white, hd(match.games).white_seed}

      n when n < 0 ->
        {hd(match.games).black, hd(match.games).black_seed}

      0 when Bye.bye_player?(hd(match.games).white) ->
        {hd(match.games).black, hd(match.games).black_seed}

      0 when Bye.bye_player?(hd(match.games).black) ->
        {hd(match.games).white, hd(match.games).white_seed}

      _ ->
        nil
    end
  end
end
