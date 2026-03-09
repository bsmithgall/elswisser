defmodule MaxWeightMatching.Viz.StepText do
  @moduledoc """
  Per-step narration for the matching visualizer.

  Each step type renders as a single coherent block: a header sentence,
  a table that IS the narration (edge classification table for scans,
  delta candidates table for deltas, path table for augments), and
  optional footer context.
  """

  use Phoenix.Component

  alias MaxWeightMatching.Viz.Util

  def explanation(step, labels \\ %{})

  def explanation(%{type: :init}, _labels) do
    assigns = %{}

    ~H"""
    <p>
      Every vertex starts with the same budget: half the maximum edge
      weight. Internally, we double all budgets to ensure things stay integers, and that doubling is shown in the visualization as well.
    </p>
    <p class="mt-1.5">
      An edge is "tight" when its endpoints' budgets sum to exactly
      2× the edge weight. The highest-weight edges are tight
      from the start; lower-weight edges become tight as <Util.s />-vertex
      budgets are spent during delta steps.
    </p>
    """
  end

  def explanation(%{type: :stage_start, detail: d} = step, labels) do
    n = length(d.s_vertices)
    queue = step.snapshot.queue

    assigns = %{
      n: n,
      verb: if(n == 1, do: "vertex is", else: "vertices are"),
      queue: queue,
      labels: labels
    }

    ~H"""
    <p>
      {@n} currently unmatched {@verb} labeled <Util.s /> and queued for scanning.
    </p>
    <.queue_display queue={@queue} labels={@labels} />
    <p class="mt-1.5">
      The search pulls one <Util.s />-vertex off the queue at a time and checks each
      of its edges. Tight edges (slack = 0) to unlabeled vertices grow the
      search tree; tight edges to other <Util.s />-vertices find augmenting paths or
      blossoms. Non-tight edges are tracked as delta candidates. When the
      queue empties without finding a path, a delta step adjusts budgets to
      make a new edge tight.
    </p>
    """
  end

  # --- Scan steps: edge classification table is the narration ---

  def explanation(%{type: :scan_step, detail: %{result: :augmenting_path} = d} = step, labels) do
    v = d.vertex
    edge_rows = build_edge_rows(d[:neighbor_edges] || [], labels)
    delta_items = build_delta_summary(d)
    queue = step.snapshot.queue

    assigns = %{
      v_name: vertex_name(v, labels),
      edge_rows: edge_rows,
      delta_items: delta_items,
      has_deltas: delta_items != [],
      queue: queue,
      labels: labels
    }

    ~H"""
    <p>
      <strong>Scanning {@v_name}</strong> — augmenting path found!
      A tight <Util.s />–<Util.s /> edge connects two different trees. The next step flips
      edges along this path to grow the matching by one.
    </p>
    <.scan_edge_table rows={@edge_rows} />
    <.delta_summary :if={@has_deltas} items={@delta_items} />
    <.queue_display queue={@queue} labels={@labels} />
    """
  end

  def explanation(%{type: :scan_step, detail: %{result: :blossom} = d} = step, labels) do
    v = d.vertex
    edge_rows = build_edge_rows(d[:neighbor_edges] || [], labels)
    delta_items = build_delta_summary(d)
    queue = step.snapshot.queue

    assigns = %{
      v_name: vertex_name(v, labels),
      edge_rows: edge_rows,
      delta_items: delta_items,
      has_deltas: delta_items != [],
      queue: queue,
      labels: labels
    }

    ~H"""
    <p>
      <strong>Scanning {@v_name}</strong> — blossom detected!
      A tight <Util.s />–<Util.s /> edge within the same tree forms an odd cycle. Contract
      into a super-vertex. Former <Util.t />-vertices inside become <Util.s />.
    </p>
    <.scan_edge_table rows={@edge_rows} />
    <.delta_summary :if={@has_deltas} items={@delta_items} />
    <.queue_display queue={@queue} labels={@labels} />
    """
  end

  def explanation(%{type: :scan_step, detail: %{neighbor_edges: edges} = d} = step, labels)
      when is_list(edges) do
    v = d.vertex

    grew_into_blossom =
      Enum.any?(edges, fn ne -> ne.classification == :grow and ne[:neighbor_in_blossom] end)

    edge_rows = build_edge_rows(edges, labels)
    delta_items = build_delta_summary(d)
    queue = step.snapshot.queue

    assigns = %{
      v_name: vertex_name(v, labels),
      grew_into_blossom: grew_into_blossom,
      edge_rows: edge_rows,
      delta_items: delta_items,
      has_deltas: delta_items != [],
      queue: queue,
      labels: labels
    }

    ~H"""
    <p :if={@grew_into_blossom} class="mb-1.5">
      <strong>Blossom growth:</strong> The tight edge reaches a vertex inside
      a blossom. The entire blossom is labeled <Util.t /> and its matched
      partner becomes <Util.s /> and joins the queue.
    </p>
    <p><strong>Scanning {@v_name}.</strong></p>
    <.scan_edge_table rows={@edge_rows} />
    <.delta_summary :if={@has_deltas} items={@delta_items} />
    <.queue_display queue={@queue} labels={@labels} />
    """
  end

  def explanation(%{type: :scan_step}, _labels) do
    assigns = %{}

    ~H"""
    <p>
      Scanning vertex. Edge labels show slack: <code>budget[x] + budget[y] − 2×weight</code>.
    </p>
    """
  end

  # --- Delta steps: candidates table with outcome column ---

  def explanation(%{type: :delta_step, detail: %{delta_type: 1} = detail}, _labels) do
    outcome = "No further progress — matching is optimal"

    assigns = %{rows: delta_rows_with_outcome(detail, outcome)}

    ~H"""
    <p class="mb-1.5">
      Queue empty — no budget adjustment can help. The smallest <Util.s />-vertex
      budget is already zero.
    </p>
    <.delta_outcome_table rows={@rows} />
    <p class="mt-1.5">
      No augmenting path exists — the current matching is optimal.
    </p>
    """
  end

  def explanation(%{type: :delta_step, detail: %{delta_type: 2} = detail}, labels) do
    outcome = delta2_outcome(detail, labels)

    assigns = %{rows: delta_rows_with_outcome(detail, outcome)}

    ~H"""
    <p class="mb-1.5">
      Queue empty — adjusting budgets (<Util.s /> −δ, <Util.t /> +δ) to make a new edge tight.
    </p>
    <.delta_outcome_table rows={@rows} />
    """
  end

  def explanation(
        %{type: :delta_step, detail: %{delta_type: 3, result: :augmenting_path} = detail},
        _labels
      ) do
    outcome = "S–S edge tight across different trees → augmenting path found"

    assigns = %{rows: delta_rows_with_outcome(detail, outcome)}

    ~H"""
    <p class="mb-1.5">
      Queue empty — adjusting budgets (<Util.s /> −δ, <Util.t /> +δ).
      <Util.s />–<Util.s /> edges tighten at 2× rate (both endpoints spend), so Δ₃ = ½ × slack.
    </p>
    <.delta_outcome_table rows={@rows} />
    """
  end

  def explanation(
        %{type: :delta_step, detail: %{delta_type: 3, result: :blossom} = detail},
        _labels
      ) do
    outcome = "S–S edge tight in same tree → odd cycle → new blossom"

    assigns = %{rows: delta_rows_with_outcome(detail, outcome)}

    ~H"""
    <p class="mb-1.5">
      Queue empty — adjusting budgets (<Util.s /> −δ, <Util.t /> +δ).
      <Util.s />–<Util.s /> edges tighten at 2× rate (both endpoints spend), so Δ₃ = ½ × slack.
    </p>
    <.delta_outcome_table rows={@rows} />
    """
  end

  def explanation(%{type: :delta_step, detail: %{delta_type: 4} = detail}, _labels) do
    outcome = "T-blossom expanded, sub-blossoms relabeled, new S-vertices queued"

    assigns = %{rows: delta_rows_with_outcome(detail, outcome)}

    ~H"""
    <p class="mb-1.5">
      Queue empty — adjusting budgets (<Util.s /> −δ, <Util.t /> +δ).
    </p>
    <.delta_outcome_table rows={@rows} />
    """
  end

  # --- Augment ---

  def explanation(%{type: :augment, detail: %{path_edges: edges}} = step, labels) do
    prev_matched = step.detail[:prev_matched_edges] || []
    path_rows = build_path_rows(edges, prev_matched, step.snapshot.edges, labels)

    assigns = %{path_rows: path_rows, has_rows: path_rows != []}

    ~H"""
    <p>
      Flip edges along the augmenting path. One more unmatched than matched
      edge, so flipping gains exactly one matched edge.
    </p>
    <.path_table :if={@has_rows} rows={@path_rows} />
    """
  end

  def explanation(%{type: :augment}, _labels) do
    assigns = %{}

    ~H"""
    <p>
      Flip edges along the augmenting path: previously unmatched
      edges become matched, and previously matched edges become
      unmatched.
    </p>
    """
  end

  # --- Stage end ---

  def explanation(%{type: :stage_end, detail: %{augmented: true}} = step, labels) do
    matched = step.snapshot.matched_edges
    total_weight = compute_matching_weight(matched, step.snapshot.edges)
    unmatched = compute_unmatched_vertices(step.snapshot)

    assigns = %{
      matching_text: format_matching(matched, step.snapshot.edges, labels),
      total_weight: fmt_num(total_weight),
      unmatched_count: length(unmatched),
      unmatched_names: Enum.map(unmatched, &vertex_name(&1, labels)) |> Enum.join(", ")
    }

    ~H"""
    <p>
      Stage complete. Current matching: {@matching_text}.
      Total weight: {@total_weight}.
    </p>
    <p :if={@unmatched_count > 0} class="mt-1">
      {@unmatched_count} vertex(es) remain unmatched: {@unmatched_names}.
    </p>
    <p class="mt-1.5">
      All tree metadata is cleared. Budgets and matched edges carry
      over to the next stage.
    </p>
    """
  end

  def explanation(%{type: :stage_end, detail: %{augmented: false}} = step, labels) do
    matched = step.snapshot.matched_edges
    total_weight = compute_matching_weight(matched, step.snapshot.edges)
    unmatched = compute_unmatched_vertices(step.snapshot)

    assigns = %{
      matching_text: format_matching(matched, step.snapshot.edges, labels),
      total_weight: fmt_num(total_weight),
      unmatched_count: length(unmatched),
      unmatched_names: Enum.map(unmatched, &vertex_name(&1, labels)) |> Enum.join(", "),
      has_matching: matched != []
    }

    ~H"""
    <p>
      No augmenting path exists — the current matching is optimal.
    </p>
    <p :if={@has_matching} class="mt-1.5">
      Final matching: {@matching_text}. Total weight: {@total_weight}.
    </p>
    <p :if={@unmatched_count > 0} class="mt-1">
      {@unmatched_count} unmatched vertex(es): {@unmatched_names} (budget = 0, confirming optimality).
    </p>
    """
  end

  def explanation(_, _labels), do: ""

  # =====================================================================
  # Components
  # =====================================================================

  # --- Scan edge classification table ---
  # Color-coded left borders match the graph edge colors from the legend.

  attr :rows, :list, required: true

  defp scan_edge_table(assigns) do
    ~H"""
    <table class="w-full mt-1.5 text-[10px] border border-zinc-200 rounded overflow-hidden">
      <thead>
        <tr class="text-left text-zinc-500 uppercase tracking-wide text-[9px] border-b border-zinc-200 bg-zinc-50">
          <th class="pl-2.5 pr-1 py-0.5">Edge</th>
          <th class="px-1 py-0.5 text-right">Slack</th>
          <th class="pl-1 pr-2 py-0.5">Classification</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={row <- @rows} class={["border-t border-zinc-100 border-l-2", row.color_class]}>
          <td class="pl-2.5 pr-1 py-0.5 font-mono whitespace-nowrap">→ {row.neighbor}</td>
          <td class="px-1 py-0.5 font-mono text-right whitespace-nowrap">
            <span
              :if={row.tight}
              class="inline-block bg-green-100 text-green-700 font-semibold rounded px-1"
            >
              {row.slack}
            </span>
            <span :if={!row.tight}>{row.slack}</span>
          </td>
          <td class="pl-1 pr-2 py-0.5">
            <span class="font-medium">{row.type_label}</span>
            <span :if={row.action} class="text-zinc-500">— {row.action}</span>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  # --- Compact delta summary (one line, for scan steps) ---

  attr :items, :list, required: true

  defp delta_summary(assigns) do
    ~H"""
    <p class="mt-1 text-[10px] text-zinc-400 font-mono">
      <span :for={item <- @items} class="mr-2">
        <span class="font-semibold text-zinc-500">{item.label}</span>
        <span>=</span>
        <span :if={item.changed} class="text-zinc-400">{item.prev_value}→</span>
        <span>{item.value}</span>
      </span>
    </p>
    """
  end

  # --- Queue display (compact inline list) ---

  attr :queue, :list, required: true
  attr :labels, :map, default: %{}

  defp queue_display(assigns) do
    names = Enum.map(assigns.queue, &vertex_name(&1, assigns.labels))
    assigns = assign(assigns, names: names, count: length(names))

    ~H"""
    <p class="mt-1 text-[10px] text-zinc-400">
      <span class="font-semibold text-zinc-500">Queue</span>
      <span :if={@count == 0} class="text-amber-600 font-medium">(empty)</span>
      <span :if={@count > 0} class="font-mono">
        [{Enum.join(@names, " → ")}]
      </span>
    </p>
    """
  end

  # --- Delta outcome table (for delta steps) ---
  # The winner row's Outcome column shows what concretely happened.

  attr :rows, :list, required: true

  defp delta_outcome_table(assigns) do
    ~H"""
    <table class="w-full text-[10px] border border-amber-200 rounded overflow-hidden bg-amber-50">
      <thead>
        <tr class="text-left font-semibold text-amber-700 uppercase tracking-wide text-[9px] border-b border-amber-200">
          <th class="px-2 py-1">Δ</th>
          <th class="px-2 py-1">Source</th>
          <th class="px-2 py-1 text-right">Value</th>
          <th class="px-2 py-1">Outcome</th>
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
          <td class="px-2 py-1 font-mono whitespace-nowrap">
            {row.label}{if row.winner, do: " ★", else: ""}
          </td>
          <td class="px-2 py-1">{row.source}</td>
          <td class="px-2 py-1 text-right font-mono">{row.value}</td>
          <td class="px-2 py-1">
            <span :if={row.winner} class="text-amber-800">{row.outcome}</span>
            <span :if={!row.winner && row.present} class="text-zinc-400">{row.effect}</span>
          </td>
        </tr>
      </tbody>
    </table>
    <p class="mt-1 text-[10px] text-amber-600">
      ★ = smallest value wins. <Util.s />-budgets −δ, <Util.t />-budgets +δ.
    </p>
    """
  end

  # --- Augmenting path table ---

  attr :rows, :list, required: true

  defp path_table(assigns) do
    ~H"""
    <table class="w-full mt-1.5 text-[10px] border border-green-200 rounded overflow-hidden bg-green-50/50">
      <thead>
        <tr class="text-left text-green-700 uppercase tracking-wide text-[9px] font-semibold border-b border-green-200">
          <th class="px-2 py-0.5">Edge</th>
          <th class="px-2 py-0.5 text-right">Weight</th>
          <th class="px-2 py-0.5">Change</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={row <- @rows} class="border-t border-green-100">
          <td class="px-2 py-0.5 font-mono">{row.edge}</td>
          <td class="px-2 py-0.5 font-mono text-right">{row.weight}</td>
          <td class="px-2 py-0.5">{row.change}</td>
        </tr>
      </tbody>
    </table>
    """
  end

  # =====================================================================
  # Data builders
  # =====================================================================

  # --- Edge rows for scan table ---

  @classification_display %{
    grow: {"Grow", "border-l-green-500 bg-green-50/50"},
    s_to_s: {"S–S tight", "border-l-amber-500 bg-amber-50/50"},
    tight_t: {"Tight-T", "border-l-slate-400 bg-slate-50/50"},
    delta2: {"Δ₂ cand.", "border-l-violet-500 bg-violet-50/30"},
    delta3: {"Δ₃ cand.", "border-l-orange-500 bg-orange-50/30"}
  }

  defp build_edge_rows(edges, labels) do
    edges
    |> Enum.reject(&(&1.classification == :internal))
    |> Enum.map(fn ne ->
      {type_label, color_class} = Map.fetch!(@classification_display, ne.classification)

      tight = ne.classification in [:grow, :s_to_s, :tight_t]

      %{
        neighbor: vertex_name(ne.neighbor, labels),
        slack: if(ne[:slack_2x], do: fmt_num(ne.slack_2x), else: "—"),
        tight: tight,
        type_label: type_label,
        action: edge_action_text(ne, labels),
        color_class: color_class
      }
    end)
  end

  defp edge_action_text(ne, labels) do
    case ne.classification do
      :grow ->
        cond do
          ne[:neighbor_in_blossom] ->
            "blossom → T"

          ne[:mate] ->
            "#{vertex_name(ne.neighbor, labels)} → T, #{vertex_name(ne.mate, labels)} → S"

          true ->
            "#{vertex_name(ne.neighbor, labels)} → T"
        end

      :s_to_s ->
        "augmenting path or blossom"

      :tight_t ->
        "skip (already in tree)"

      :delta2 ->
        "S → unlabeled, not tight"

      :delta3 ->
        "S → S, not tight"
    end
  end

  # --- Compact delta summary for scan steps ---

  @delta_labels [{1, "Δ₁"}, {2, "Δ₂"}, {3, "Δ₃"}, {4, "Δ₄"}]

  defp build_delta_summary(detail) do
    candidates = detail[:delta_candidates] || []
    prev_candidates = detail[:prev_delta_candidates] || []

    Enum.map(@delta_labels, fn {type, label} ->
      candidate = Enum.find(candidates, &(&1.delta_type == type))
      prev_candidate = Enum.find(prev_candidates, &(&1.delta_type == type))

      value = if candidate, do: fmt_num(candidate.value_2x), else: "—"
      prev_value = if prev_candidate, do: fmt_num(prev_candidate.value_2x), else: "—"

      %{label: label, value: value, prev_value: prev_value, changed: value != prev_value}
    end)
  end

  # --- Delta rows with outcome for delta steps ---

  @delta_row_meta [
    %{type: 1, label: "Δ₁", source: "min S-vertex budget", effect: "budget hits 0 → stage ends"},
    %{
      type: 2,
      label: "Δ₂",
      source: "min slack among S → unlabeled",
      effect: "edge tight → grow tree"
    },
    %{
      type: 3,
      label: "Δ₃",
      source: "½ min slack among S → S",
      effect: "edge tight → augment or blossom"
    },
    %{type: 4, label: "Δ₄", source: "min T-blossom budget", effect: "budget hits 0 → expand"}
  ]

  defp delta_rows_with_outcome(detail, outcome_text) do
    candidates = detail[:delta_candidates] || []
    winner = detail[:delta_type]

    Enum.map(@delta_row_meta, fn meta ->
      candidate = Enum.find(candidates, &(&1.delta_type == meta.type))
      value = if candidate, do: fmt_num(candidate.value_2x), else: "—"
      is_winner = winner != nil && meta.type == winner

      Map.merge(meta, %{
        value: value,
        winner: is_winner,
        present: candidate != nil,
        outcome: if(is_winner, do: outcome_text)
      })
    end)
  end

  defp delta2_outcome(detail, labels) do
    case {detail[:x], detail[:y]} do
      {x, y} when not is_nil(x) and not is_nil(y) ->
        "#{vertex_name(x, labels)}–#{vertex_name(y, labels)} tight → #{vertex_name(y, labels)} becomes T, mate becomes S"

      _ ->
        "S→unlabeled edge tight → tree grows"
    end
  end

  # --- Augmenting path rows ---

  defp build_path_rows(path_edges, prev_matched, edges_map, labels) do
    weight_lookup =
      Map.new(edges_map, fn {_idx, {p, q, w}} ->
        {{min(p, q), max(p, q)}, w}
      end)

    prev_matched_set =
      MapSet.new(prev_matched, fn {x, y} -> {min(x, y), max(x, y)} end)

    Enum.map(path_edges, fn {x, y} ->
      key = {min(x, y), max(x, y)}
      w = Map.get(weight_lookup, key, "?")
      was_matched = MapSet.member?(prev_matched_set, key)

      %{
        edge: "#{vertex_name(x, labels)}–#{vertex_name(y, labels)}",
        weight: w,
        change: if(was_matched, do: "matched → unmatched", else: "unmatched → matched")
      }
    end)
  end

  # =====================================================================
  # Shared helpers
  # =====================================================================

  defp compute_matching_weight(matched_edges, edges_map) do
    Enum.reduce(matched_edges, 0, fn {x, y}, acc ->
      weight =
        edges_map
        |> Map.values()
        |> Enum.find_value(0, fn {p, q, w} ->
          if (p == x and q == y) or (p == y and q == x), do: w
        end)

      acc + weight
    end)
  end

  defp compute_unmatched_vertices(snapshot) do
    matched_vertices =
      snapshot.matched_edges
      |> Enum.flat_map(fn {x, y} -> [x, y] end)
      |> MapSet.new()

    snapshot.vertex_labels
    |> Map.keys()
    |> Enum.reject(&MapSet.member?(matched_vertices, &1))
    |> Enum.sort()
  end

  defp format_matching(matched_edges, edges_map, labels) do
    matched_edges
    |> Enum.map(fn {x, y} ->
      weight =
        edges_map
        |> Map.values()
        |> Enum.find_value("?", fn {p, q, w} ->
          if (p == x and q == y) or (p == y and q == x), do: w
        end)

      "#{vertex_name(x, labels)}–#{vertex_name(y, labels)} (w=#{weight})"
    end)
    |> Enum.join(", ")
  end

  defp vertex_name(v, labels) do
    case Map.get(labels, v) do
      nil -> Integer.to_string(v)
      name -> "#{name} (#{v})"
    end
  end

  defp fmt_num(n) when is_float(n) do
    if n == Float.round(n),
      do: Integer.to_string(trunc(n)),
      else: :erlang.float_to_binary(n, decimals: 1)
  end

  defp fmt_num(n) when is_integer(n), do: Integer.to_string(n)
  defp fmt_num(n), do: to_string(n)
end
