defmodule MaxWeightMatching.Viz.Legend do
  @moduledoc """
  Static legend component for the matching visualizer, describing vertex
  labels, edge colours, scan-step edge classifications, and key concepts.
  """

  use Phoenix.Component

  def legend(assigns) do
    ~H"""
    <details class="text-xs text-zinc-600">
      <summary class="font-semibold text-zinc-700 cursor-pointer select-none">Legend</summary>
      <div class="mt-2 space-y-2">
        <%!-- Vertices --%>
        <div class="space-y-1">
          <p class="text-[10px] font-semibold text-zinc-400 uppercase tracking-wide">Vertices</p>
          <div class="flex items-start gap-2">
            <span class="inline-block w-3 h-3 mt-0.5 rounded-full bg-blue-500 shrink-0"></span>
            <span>
              <strong>S</strong> — active searchers, queued for scanning.
              Unmatched vertices start as S; matched vertices become S when
              their partner becomes T.
            </span>
          </div>
          <div class="flex items-start gap-2">
            <span class="inline-block w-3 h-3 mt-0.5 rounded-full bg-red-500 shrink-0"></span>
            <span>
              <strong>T</strong> — reached via a tight edge from an S-vertex.
              Never queued directly; their matched partner immediately
              becomes S and joins the queue.
            </span>
          </div>
          <div class="flex items-start gap-2">
            <span class="inline-block w-3 h-3 mt-0.5 rounded-full bg-gray-400 shrink-0"></span>
            <span>
              <strong>Unlabeled</strong> — not yet reached by the search in this stage.
            </span>
          </div>
          <div class="flex items-start gap-2">
            <span class="inline-block w-3 h-3 mt-0.5 rounded border-2 border-yellow-400 bg-transparent shrink-0">
            </span>
            <span>
              <strong>Active</strong> — the vertex currently being operated on this step.
            </span>
          </div>
        </div>

        <%!-- Edges --%>
        <div class="space-y-1">
          <p class="text-[10px] font-semibold text-zinc-400 uppercase tracking-wide">Edges</p>
          <div class="flex items-start gap-2">
            <span class="inline-block w-4 h-0.5 mt-1.5 bg-green-500 shrink-0 rounded"></span>
            <span>
              <strong>Matched</strong> — in the current matching. The
              algorithm maximizes total weight of these edges.
            </span>
          </div>
          <div class="flex items-start gap-2">
            <span class="inline-block w-4 h-0.5 mt-1.5 bg-zinc-300 shrink-0 rounded"></span>
            <span>
              <strong>Unmatched</strong> — available but not currently in the matching.
            </span>
          </div>
          <div class="flex items-start gap-2">
            <span class="inline-block w-4 h-0.5 mt-1.5 bg-yellow-400 shrink-0 rounded"></span>
            <span>
              <strong>Active</strong> — involved in the current operation.
            </span>
          </div>
        </div>

        <%!-- Scan edge classifications --%>
        <div class="space-y-1">
          <p class="text-[10px] font-semibold text-zinc-400 uppercase tracking-wide">
            During Scan Steps
          </p>
          <p class="text-zinc-500 mb-1">
            Each edge from the scanned S-vertex is classified by its slack
            and the neighbor's label:
          </p>
          <div class="flex items-start gap-2">
            <span class="inline-block w-4 h-0.5 mt-1.5 bg-green-500 shrink-0 rounded"></span>
            <span>
              <strong>Grow</strong> — tight (slack = 0) to an unlabeled vertex.
              Tree extends: neighbor becomes T, its matched partner becomes S.
            </span>
          </div>
          <div class="flex items-start gap-2">
            <span class="inline-block w-4 h-0.5 mt-1.5 bg-amber-500 shrink-0 rounded"></span>
            <span>
              <strong>S–S</strong> — tight to another S-vertex. Either an
              augmenting path (different trees) or a blossom (same tree).
            </span>
          </div>
          <div class="flex items-start gap-2">
            <span class="inline-block w-4 h-0.5 mt-1.5 bg-slate-400 shrink-0 rounded border-b border-dashed border-slate-400">
            </span>
            <span>
              <strong>Tight-T</strong> — tight to a T-vertex. Already in the tree; no action needed.
            </span>
          </div>
          <div class="flex items-start gap-2">
            <span class="inline-block w-4 h-0.5 mt-1.5 bg-violet-500 shrink-0 rounded border-b border-dashed border-violet-500">
            </span>
            <span>
              <strong>Δ₂ candidate</strong> — not tight, neighbor is unlabeled.
              Tracked for the next delta step.
            </span>
          </div>
          <div class="flex items-start gap-2">
            <span class="inline-block w-4 h-0.5 mt-1.5 bg-orange-500 shrink-0 rounded border-b border-dashed border-orange-500">
            </span>
            <span>
              <strong>Δ₃ candidate</strong> — not tight, neighbor is S.
              Tracked for the next delta step. Slack shrinks at 2× rate
              since both endpoints are S.
            </span>
          </div>
        </div>

        <%!-- Key concepts --%>
        <div class="border-t border-zinc-200 pt-2 space-y-1.5 text-zinc-500">
          <p>
            <strong class="text-zinc-600">Budget</strong>
            (the number below each vertex name)
            starts at half the max edge weight, shown at 2× scale to keep
            values integer. S-budgets decrease during delta steps;
            T-budgets increase.
          </p>
          <p>
            <strong class="text-zinc-600">Slack</strong> =
            budget[x] + budget[y] − 2×weight. Zero means the edge is
            <strong>tight</strong> and the algorithm can use it. During
            scans, each edge is annotated with this arithmetic.
          </p>
          <p>
            <strong class="text-zinc-600">Blossom</strong> (dashed purple group) — an odd cycle
            contracted into a single super-vertex. This is the key trick that makes matching work
            on non-bipartite graphs. Blossoms have their own budget that increases (if S) or
            decreases (if T) during delta steps.
          </p>
        </div>
      </div>
    </details>
    """
  end
end
