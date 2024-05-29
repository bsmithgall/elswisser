defmodule Elchesser do
  def ranks, do: 1..8
  def ranks_c, do: ?1..?8
  def files, do: ?a..?h

  defguard in_ranks(c) when c in ?1..?8
  defguard in_files(c) when c in ?a..?h
end
