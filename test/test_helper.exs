ExUnit.start(exclude: [:perft, :slow])
Ecto.Adapters.SQL.Sandbox.mode(Elswisser.Repo, :manual)

defmodule TestHelper do
  defmacro assert_list_eq_any_order(left, right) do
    quote do
      assert Enum.sort(unquote(left)) == Enum.sort(unquote(right))
    end
  end
end
