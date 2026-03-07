defmodule MaxWeightMatching.Stepper.Step do
  @moduledoc """
  A single step in the blossom algorithm visualization.

  Each step captures the algorithm's displayable state (`snapshot`) after an
  operation, plus metadata about what operation was performed (`type`, `detail`).

  Consumers (LiveView, text formatter, JSON API) can diff consecutive snapshots
  to determine what changed — new labels, new matched edges, new blossoms, etc.

  ## Step Types

  | Type | When |
  |------|------|
  | `:init` | After graph + context creation, before first stage |
  | `:stage_start` | After labeling unmatched vertices as S |
  | `:scan_step` | After processing one dequeued S-vertex's edges |
  | `:delta_step` | After computing and applying a dual variable delta |
  | `:augment` | After augmenting the matching along a path |
  | `:stage_end` | After a stage completes (augmented or not) |
  """

  @type event_type :: :init | :stage_start | :scan_step | :delta_step | :augment | :stage_end

  @type blossom_group :: %{
          vertices: [non_neg_integer()],
          base: non_neg_integer(),
          dual: number()
        }

  @type snapshot :: %{
          vertex_labels: %{non_neg_integer() => :s | :t | :none},
          vertex_duals: %{non_neg_integer() => number()},
          matched_edges: [{non_neg_integer(), non_neg_integer()}],
          blossoms: [blossom_group()],
          edges: %{non_neg_integer() => {non_neg_integer(), non_neg_integer(), number()}}
        }

  @type t :: %__MODULE__{
          type: event_type(),
          detail: map(),
          snapshot: snapshot()
        }

  defstruct [:type, :detail, :snapshot]

  defimpl Inspect do
    def inspect(%{type: type, detail: detail, snapshot: snap}, _opts) do
      labels_by_type = Enum.group_by(snap.vertex_labels, &elem(&1, 1), &elem(&1, 0))
      s_verts = Map.get(labels_by_type, :s, []) |> Enum.sort()
      t_verts = Map.get(labels_by_type, :t, []) |> Enum.sort()

      matched =
        snap.matched_edges
        |> Enum.map(fn {x, y} -> "#{x}-#{y}" end)
        |> Enum.join(", ")

      blossoms =
        snap.blossoms
        |> Enum.map(fn b -> "{#{Enum.join(b.vertices, ",")}}" end)
        |> Enum.join(", ")

      detail_str =
        detail
        |> Enum.map(fn {k, v} -> "#{k}: #{Kernel.inspect(v)}" end)
        |> Enum.join(", ")

      "#Step<:#{type}" <>
        if(detail_str != "", do: " #{detail_str}", else: "") <>
        " | S:#{Kernel.inspect(s_verts)} T:#{Kernel.inspect(t_verts)}" <>
        " | matched:[#{matched}]" <>
        if(blossoms != "", do: " | blossoms:[#{blossoms}]", else: "") <>
        ">"
    end
  end
end
