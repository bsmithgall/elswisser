defmodule MaxWeightMatching.Viz.HowItWorks do
  @moduledoc """
  Static component that renders the "How it works" modal body for the
  matching visualizer, explaining the blossom algorithm at a conceptual level.
  """

  use Phoenix.Component

  def how_it_works(assigns) do
    ~H"""
    <div class="space-y-4 text-sm text-zinc-700 leading-relaxed">
      <h2 class="text-lg font-bold text-zinc-900">How the Blossom Algorithm Works</h2>

      <p>
        This visualizer steps through <a
          href="https://en.wikipedia.org/wiki/Blossom_algorithm"
          class="text-blue-600 underline"
          target="_blank"
        >Edmonds' blossom algorithm</a>, which finds a <strong>maximum weight matching</strong>
        in a graph: a set of edges (pairs of vertices)
        where no vertex appears twice and the total weight is as large as possible.
      </p>

      <h3 class="font-semibold text-zinc-800">Stages and substages</h3>
      <p>
        The algorithm works in <strong>stages</strong>. Each stage searches for one <strong>augmenting path</strong>: a chain of edges alternating between matched and
        unmatched, connecting two unmatched vertices. Flipping matched ↔ unmatched along this
        chain gains exactly one matched edge. After at most <em>n</em>/2 stages, no more
        improvement is possible.
      </p>
      <p>
        Within each stage, <strong>scan</strong> and <strong>delta</strong> steps alternate
        repeatedly — this is the inner loop. A scan drains the queue of S-vertices; if the
        queue empties without finding a path, a delta step adjusts budgets to create a new
        tight edge, which re-fills the queue. This scan → delta → scan cycle repeats until
        either an augmenting path is found (Δ₂ or Δ₃) or no further progress is possible (Δ₁).
      </p>

      <h3 class="font-semibold text-zinc-800">Budgets, slack, and tight edges</h3>
      <p>
        Every vertex has a <strong>budget</strong>
        (dual variable), which starts as half of the maximum input edge weight. Each edge has a <strong>slack</strong>, which is calculated as <code>budget[x] + budget[y] − weight</code>. An edge is
        "tight" when its slack is zero.
      </p>
      <p class="text-xs text-zinc-500">
        NOTE: All values are stored at 2× scale to avoid floating point division. The slack formula
        in this visualization reflects these 2× values.
      </p>

      <h3 class="font-semibold text-zinc-800">The search: S and T labels</h3>
      <p>
        The algorithm builds alternating trees outward from each unmatched vertex. Vertices
        are labeled S or T to track their depth:
      </p>
      <ul class="list-disc ml-5 space-y-1">
        <li>
          <strong class="text-blue-600">S</strong>
          — at even depth from an unmatched root.
          Active searchers: one S-vertex is dequeued at a time and each of its edges is
          classified:
          <ul class="list-disc ml-5 mt-1 space-y-0.5">
            <li>
              <strong>Tight → unlabeled:</strong>
              grow the tree — neighbor becomes T, its matched partner becomes S and is queued
            </li>
            <li>
              <strong>Tight → S:</strong> augmenting path (different trees) or new blossom (same tree)
            </li>
            <li><strong>Tight → T:</strong> already in the tree, skip</li>
            <li><strong>Not tight:</strong> recorded as a candidate for the next delta step</li>
          </ul>
        </li>
        <li>
          <strong class="text-red-500">T</strong> — at odd depth. Reached via a tight edge
          from an S-vertex; never queued directly. Their matched partner immediately becomes S.
          Trees grow two levels at a time: T then S.
        </li>
        <li>
          <strong class="text-zinc-400">Unlabeled</strong> — not yet reached by the search.
        </li>
      </ul>

      <h3 class="font-semibold text-zinc-800">Delta steps: spending budgets</h3>
      <p>
        When the scan queue empties without finding a path, the algorithm adjusts budgets by some value δ to
        make a new edge tight. S-vertex budgets decrease by δ and T-vertex budgets increase by δ.
      </p>
      <p>The size of δ is the <strong>minimum</strong> of four candidates:</p>
      <table class="w-full text-xs border border-zinc-200 rounded overflow-hidden">
        <thead class="bg-zinc-100 text-left">
          <tr>
            <th class="px-2 py-1 font-semibold">Delta</th>
            <th class="px-2 py-1 font-semibold">What limits it</th>
            <th class="px-2 py-1 font-semibold">What happens when it wins</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-zinc-100">
          <tr>
            <td class="px-2 py-1 font-mono">Δ₁</td>
            <td class="px-2 py-1">Smallest S-vertex budget</td>
            <td class="px-2 py-1">All unmatched budgets hit 0 → matching is optimal</td>
          </tr>
          <tr>
            <td class="px-2 py-1 font-mono">Δ₂</td>
            <td class="px-2 py-1">Min slack, S → unlabeled edge</td>
            <td class="px-2 py-1">Edge becomes tight → tree grows, scan resumes</td>
          </tr>
          <tr>
            <td class="px-2 py-1 font-mono">Δ₃</td>
            <td class="px-2 py-1">½ × min slack, S → S edge</td>
            <td class="px-2 py-1">Edge becomes tight → augmenting path or blossom</td>
          </tr>
          <tr>
            <td class="px-2 py-1 font-mono">Δ₄</td>
            <td class="px-2 py-1">Min T-blossom budget</td>
            <td class="px-2 py-1">Blossom budget hits 0 → expand it, scan resumes</td>
          </tr>
        </tbody>
      </table>
      <p class="text-xs text-zinc-500">
        NOTE: Δ₃ uses half the slack because both S-endpoints spend budget simultaneously, so slack
        shrinks at 2× rate.
      </p>

      <h3 class="font-semibold text-zinc-800">Blossoms: handling odd cycles</h3>
      <p>
        When a tight edge connects two S-vertices in the same
        tree, it forms an odd
        cycle. The algorithm contracts this cycle into a single super-vertex called a
        <strong>blossom</strong>
        (shown as a dashed purple group). This is necessary because
        odd cycles break the alternating-path logic.
      </p>
      <p>
        Former T-vertices inside a blossom become S, unlocking their edges for scanning.
        Blossoms can be nested (a blossom can contain other blossoms). When a T-blossom's
        budget reaches zero (Δ₄), it is expanded back into its sub-blossoms and scanning
        continues from the newly exposed S-vertices.
      </p>
    </div>
    """
  end
end
