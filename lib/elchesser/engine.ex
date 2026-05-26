defmodule Elchesser.Engine do
  alias Elchesser.{Move, Game}

  @callback name() :: String.t()
  @callback evaluate(Game.t()) :: number()
  @callback move(Game.t()) :: Move.t()

  # default move implementation: evaluate all legal moves and pick the best one
  defmacro __using__(_opts) do
    quote do
      @behaviour Elchesser.Engine
      def name() do
        __MODULE__
        |> Module.split()
        |> List.last()
        |> Macro.underscore()
        |> String.replace("_", " ")
        |> String.capitalize()
      end

      def move(game) do
        game
        |> Game.all_legal_moves()
        |> Enum.max_by(fn move ->
          {:ok, new_game} = Game.make_move(game, move)
          -evaluate(new_game)
        end)
      end

      defoverridable name: 0
      defoverridable move: 1
    end
  end

  def all() do
    {:ok, modules} = :application.get_key(:elswisser, :modules)

    modules
    |> Enum.filter(fn mod ->
      mod.module_info(:attributes)
      |> Keyword.get_values(:behaviour)
      |> List.flatten()
      |> Enum.member?(__MODULE__)
    end)
  end

  def from_string(str) do
    all() |> Enum.find(&(str == to_string(&1)))
  end
end
