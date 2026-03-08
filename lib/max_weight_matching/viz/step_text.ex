defmodule MaxWeightMatching.Viz.StepText do
  @moduledoc """
  Per-step text for the matching visualizer: one-line descriptions for the
  monospace detail bar, and multi-paragraph HEEx explanations for the
  educational panel. Delta explanations embed the candidate table inline.
  """

  use Phoenix.Component

  def explanation(%{type: :init}) do
    assigns = %{}

    ~H"""
    <p>
      Every vertex starts with the same budget (dual variable): half the
      maximum edge weight. All values are stored at 2× scale to keep
      everything integer, so the initial budget shown is actually the
      max weight itself.
    </p>
    <p class="mt-1.5">
      An edge is "tight" when its endpoints' budgets sum to exactly
      2× the edge weight — meaning the slack is zero. High-weight edges
      are tight from the start; lower-weight edges become tight as
      S-vertex budgets are spent during delta steps.
    </p>
    """
  end

  def explanation(%{type: :stage_start, detail: d}) do
    n = length(d.s_vertices)
    assigns = %{n: n, verb: if(n == 1, do: "vertex is", else: "vertices are")}

    ~H"""
    <p>
      A stage is one complete search for an augmenting path: a chain of
      edges alternating between matched and unmatched, connecting two
      unmatched vertices. Finding and flipping such a path gains exactly
      one matched edge.
    </p>
    <p class="mt-1.5">
      {@n} currently unmatched {@verb} labeled S (blue) and queued for
      scanning. The search works outward from these roots, extending the
      alternating tree by scanning one S-vertex at a time.
    </p>
    """
  end

  def explanation(%{type: :scan_step, detail: %{result: :augmenting_path} = d}) do
    active_wins = Map.get(d, :active_delta_wins, [])
    contribs = vertex_delta_contributions(Map.get(d, :neighbor_edges, []))

    assigns = %{
      rows: delta_rows(d, active_wins, contribs),
      has_candidates: d[:delta_candidates] != nil
    }

    ~H"""
    <.delta_candidates_table :if={@has_candidates} rows={@rows} show_vertex />
    <p>
      Scanning found a tight edge to an S-vertex in a different alternating
      tree — that connects two unmatched roots, giving us an augmenting
      path. The next step will flip matched/unmatched edges along this
      path to grow the matching by one.
    </p>
    """
  end

  def explanation(%{type: :scan_step, detail: %{result: :blossom} = d}) do
    active_wins = Map.get(d, :active_delta_wins, [])
    contribs = vertex_delta_contributions(Map.get(d, :neighbor_edges, []))

    assigns = %{
      rows: delta_rows(d, active_wins, contribs),
      has_candidates: d[:delta_candidates] != nil
    }

    ~H"""
    <.delta_candidates_table :if={@has_candidates} rows={@rows} show_vertex />
    <p>
      Scanning found a tight edge to an S-vertex in the same tree, forming
      an odd cycle. The algorithm contracts this into a blossom — a
      super-vertex that hides the cycle. Odd cycles break the
      alternating-path logic, so the cycle gets collapsed into a single node.
    </p>
    <p class="mt-1.5">
      Former T-vertices inside the blossom effectively become S,
      unlocking their edges for scanning.
    </p>
    """
  end

  def explanation(%{type: :scan_step, detail: %{neighbor_edges: edges} = d})
      when is_list(edges) do
    grew_into_blossom =
      Enum.any?(edges, fn ne -> ne.classification == :grow and ne[:neighbor_in_blossom] end)

    active_wins = Map.get(d, :active_delta_wins, [])
    contribs = vertex_delta_contributions(edges)

    assigns = %{
      grew_into_blossom: grew_into_blossom,
      rows: delta_rows(d, active_wins, contribs),
      has_candidates: d[:delta_candidates] != nil
    }

    ~H"""
    <.delta_candidates_table :if={@has_candidates} rows={@rows} show_vertex />
    <p :if={@grew_into_blossom}>
      <strong>Blossom growth:</strong> The tight edge reaches a vertex inside
      a blossom. Since a blossom acts as a single super-vertex, the entire
      blossom is labeled T at once.
    </p>
    <p class={if(@grew_into_blossom, do: "mt-1.5", else: "")}>
      Pulled an S-vertex off the queue and checked each of its edges.
      Edge labels show the slack: <code>budget[x] + budget[y] − 2×weight</code>.
      Zero means tight; tight edges drive tree growth or trigger a delta step.
    </p>
    """
  end

  def explanation(%{type: :scan_step}) do
    assigns = %{}

    ~H"""
    Pulled an S-vertex off the queue and checked each of its edges.
    The edge labels show the slack computation: budget[x] + budget[y] − 2×weight.
    <p class="mt-1.5">When slack = 0, the edge is tight and the algorithm can act on it:</p>
    <ul class="list-disc ml-5 mt-1 space-y-0.5">
      <li><strong>Tight → unlabeled:</strong> grow the tree (assign T, then its mate becomes S)</li>
      <li><strong>Tight → S-vertex:</strong> augmenting path or blossom</li>
      <li><strong>Tight → T-vertex:</strong> already in the tree, skip</li>
      <li><strong>Not tight:</strong> tracked as a candidate for future delta steps</li>
    </ul>
    """
  end

  def explanation(%{type: :delta_step, detail: %{delta_type: 1} = detail}) do
    assigns = %{rows: delta_rows(detail)}

    ~H"""
    <.delta_candidates_table rows={@rows} />
    <p>
      The scan queue is empty and no budget adjustment can help. The
      smallest S-vertex budget is already zero, so Δ₁ wins — any
      further decrease would push an S-budget negative.
    </p>
    <p class="mt-1.5">
      This means no augmenting path exists. The zero budgets on
      unmatched vertices serve as a certificate of optimality: the
      current matching is provably maximum weight.
    </p>
    """
  end

  def explanation(%{type: :delta_step, detail: %{delta_type: 2} = detail}) do
    assigns = %{rows: delta_rows(detail)}

    ~H"""
    <.delta_candidates_table rows={@rows} />
    <p>
      The scan queue emptied without finding a path. The algorithm
      adjusts all budgets by the smallest delta candidate to make a
      new edge tight: S-vertex budgets decrease by δ, T-vertex budgets
      increase by δ. The opposing signs keep every existing S–T tree
      edge tight (the +δ and −δ cancel exactly).
    </p>
    <p class="mt-1.5">
      Δ₂ won: an edge from an S-vertex to an unlabeled vertex just
      became tight. The unlabeled vertex is assigned T, and its matched
      partner becomes S and joins the scan queue.
    </p>
    """
  end

  def explanation(%{
        type: :delta_step,
        detail: %{delta_type: 3, result: :augmenting_path} = detail
      }) do
    assigns = %{rows: delta_rows(detail)}

    ~H"""
    <.delta_candidates_table rows={@rows} />
    <p>
      Δ₃ won: an edge between two S-vertices became tight. Since
      they are in different trees, this gives an augmenting path
      between two unmatched roots.
    </p>
    <p class="mt-1.5">
      S–S edges get tight twice as fast as S–unlabeled edges because
      both endpoints' budgets are decreasing simultaneously — that's
      why Δ₃ = ½ × slack rather than the full slack.
    </p>
    """
  end

  def explanation(%{type: :delta_step, detail: %{delta_type: 3, result: :blossom} = detail}) do
    assigns = %{rows: delta_rows(detail)}

    ~H"""
    <.delta_candidates_table rows={@rows} />
    <p>
      Δ₃ won: an edge between two S-vertices became tight. Since
      they are in the same tree, this forms an odd cycle — a new
      blossom. The cycle is contracted into a super-vertex.
    </p>
    <p class="mt-1.5">
      Former T-sub-blossoms inside it effectively become S, unlocking
      their edges for scanning. S–S edges get tight twice as fast
      because both endpoints spend budget simultaneously (Δ₃ = ½ × slack).
    </p>
    """
  end

  def explanation(%{type: :delta_step, detail: %{delta_type: 4} = detail}) do
    assigns = %{rows: delta_rows(detail)}

    ~H"""
    <.delta_candidates_table rows={@rows} />
    <p>
      Δ₄ won: a T-blossom's budget has reached zero. It must be
      expanded back into its sub-blossoms since further budget decreases
      would make it negative.
    </p>
    <p class="mt-1.5">
      The alternating tree path through the former blossom is
      reconstructed: sub-blossoms along it alternate S/T labels,
      and new S-vertices are queued for scanning.
    </p>
    """
  end

  def explanation(%{type: :augment}) do
    assigns = %{}

    ~H"""
    <p>
      Flip edges along the augmenting path: previously unmatched
      edges become matched, and previously matched edges become
      unmatched. The path always has one more unmatched than matched
      edge, so flipping gains exactly one matched edge.
    </p>
    <p class="mt-1.5">
      If the path passes through a blossom, its internal edges are
      re-routed to maintain the alternating structure.
    </p>
    """
  end

  def explanation(%{type: :stage_end, detail: %{augmented: true}}) do
    assigns = %{}

    ~H"""
    <p>
      This stage found and used an augmenting path, adding one matched
      edge. All tree metadata (S/T labels, queue, best-edge tracking)
      is now cleared. Budgets and matched edges carry over to the
      next stage, which searches from scratch.
    </p>
    <p class="mt-1.5">
      The algorithm continues until no more augmenting paths can be found.
    </p>
    """
  end

  def explanation(%{type: :stage_end, detail: %{augmented: false}}) do
    assigns = %{}

    ~H"""
    <p>
      No augmenting path exists. Every unmatched vertex's budget is
      zero, satisfying the LP optimality conditions. The algorithm
      terminates — the current matching is provably maximum weight.
    </p>
    """
  end

  def explanation(_), do: ""

  # --- Delta candidates table ---

  @delta_row_meta [
    %{type: 1, label: "Δ₁", source: "min S-vertex budget", effect: "stage ends — optimal"},
    %{type: 2, label: "Δ₂", source: "min slack, S → unlabeled", effect: "edge tight → grow tree"},
    %{
      type: 3,
      label: "Δ₃",
      source: "½ × min slack, S → S",
      effect: "edge tight → augment or blossom"
    },
    %{type: 4, label: "Δ₄", source: "min T-blossom budget", effect: "blossom dual → 0 → expand"}
  ]

  attr :rows, :list, required: true
  attr :show_vertex, :boolean, default: false

  defp delta_candidates_table(assigns) do
    ~H"""
    <table class="w-full mt-2 text-[10px] border border-amber-200 rounded overflow-hidden bg-amber-50">
      <thead>
        <tr class="text-left font-semibold text-amber-700 uppercase tracking-wide border-b border-amber-200">
          <th class="px-2 py-1">Delta</th>
          <th class="px-2 py-1">Computed from</th>
          <th class="px-2 py-1">Effect</th>
          <th class="px-2 py-1 text-right">Value</th>
        </tr>
      </thead>
      <tbody>
        <tr
          :for={row <- @rows}
          class={[
            "border-t border-amber-100",
            row.winner && "bg-amber-100 font-semibold",
            !row.present && "text-zinc-400"
          ]}
        >
          <td class="px-2 py-1 font-mono">{row.label}{if row.winner, do: " ★", else: ""}</td>
          <td class="px-2 py-1">{row.source}</td>
          <td class="px-2 py-1">{row.effect}</td>
          <td class="px-2 py-1 text-right font-mono whitespace-nowrap">
            <span :if={@show_vertex && row.value_changed} class="text-zinc-400 mr-0.5">
              {row.prev_value} →
            </span>
            <span class={[
              @show_vertex && row.vertex_wins && "bg-green-200 rounded px-0.5",
              @show_vertex && row.vertex_contributes && "bg-red-100 rounded px-0.5"
            ]}>
              {row.value}
            </span>
          </td>
        </tr>
      </tbody>
    </table>
    <p class="mt-1 text-[10px] text-amber-700">
      ★ wins (smallest value). S-budgets −δ, T-budgets +δ
    </p>
    """
  end

  defp delta_rows(detail, active_wins \\ [], contribs \\ []) do
    candidates = detail[:delta_candidates] || []
    prev_candidates = detail[:prev_delta_candidates] || []
    winner = detail[:delta_type]

    Enum.map(@delta_row_meta, fn meta ->
      candidate = Enum.find(candidates, &(&1.delta_type == meta.type))
      prev_candidate = Enum.find(prev_candidates, &(&1.delta_type == meta.type))

      value = if candidate, do: fmt_num(candidate.value_2x), else: "—"
      prev_value = if prev_candidate, do: fmt_num(prev_candidate.value_2x), else: "—"

      Map.merge(meta, %{
        value: value,
        prev_value: prev_value,
        value_changed: value != prev_value,
        winner: winner != nil && meta.type == winner,
        present: candidate != nil,
        vertex_wins: meta.type in active_wins,
        vertex_contributes: meta.type in contribs and meta.type not in active_wins
      })
    end)
  end

  # Determine which delta types the currently scanned vertex has candidates for,
  # derived from the neighbor_edges classification already computed in the stepper.
  # x is always an S-vertex (just dequeued), so it always contributes to Δ₁.
  # Δ₂ candidates are non-tight edges to unlabeled neighbors.
  # Δ₃ candidates are non-tight edges to S-neighbors.
  # Δ₄ is never contributed by an S-vertex (it tracks T-blossom budgets).
  defp vertex_delta_contributions(edges) do
    has_delta2 =
      Enum.any?(edges, &(&1.classification == :delta2 and &1[:neighbor_label] == :none))

    has_delta3 = Enum.any?(edges, &(&1.classification == :delta3))

    if(has_delta2, do: [2], else: []) ++
      if(has_delta3, do: [3], else: [])
  end

  defp fmt_num(n) when is_float(n) do
    if n == Float.round(n),
      do: Integer.to_string(trunc(n)),
      else: :erlang.float_to_binary(n, decimals: 1)
  end

  defp fmt_num(n), do: Integer.to_string(n)
end
