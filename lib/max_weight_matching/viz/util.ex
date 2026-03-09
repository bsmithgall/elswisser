defmodule MaxWeightMatching.Viz.Util do
  use Phoenix.Component

  def t(assigns) do
    ~H"""
    <strong class="text-red-500">T</strong>
    """
  end

  def s(assigns) do
    ~H"""
    <strong class="text-blue-600">S</strong>
    """
  end
end
