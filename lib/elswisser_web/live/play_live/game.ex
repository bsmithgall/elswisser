defmodule ElswisserWeb.PlayLive.Game do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :id, :string
    field :white, :string, default: nil
    field :black, :string, default: nil
    field :fen, :string, default: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    field :pgn, :string, default: ""
  end
end
