defmodule MaxWeightMatching.Viz.HowItWorks do
  @moduledoc """
  Static component that renders the "How it works" modal body for the
  matching visualizer, explaining the blossom algorithm at a conceptual level.
  """

  use Phoenix.Component

  alias MaxWeightMatching.Viz.Util

  def how_it_works(assigns) do
    ~H"""
    <div class="space-y-4 text-sm text-zinc-700 leading-relaxed">
      <h2 class="text-lg font-bold text-zinc-900">Maximum weighted matching algorithm overview</h2>

      <p>
        This visualizer steps through an implementation of the <a
          href="https://en.wikipedia.org/wiki/Blossom_algorithm"
          class="text-blue-600 underline"
          target="_blank"
        >blossom algorithm</a>, which finds a maximum weight matching
        in a graph: a set of edges (pairs of vertices)
        where no vertex appears twice and the total weight is as large as possible. This is used internally by our chess tournament manager to pair players in a Swiss tournament. For each round in a Swiss tournament, each possible combination of players can be thought of as an edge on the graph whose weight corresponds to the pairing rules (have these two players played before, their score, etc). This algorithm gives us the "matching" (combination of matched players) that maximizes their weight (best possible pairing among all pairings).
      </p>

      <h3 class="font-semibold text-zinc-800">Stages and substages</h3>
      <p>
        The algorithm starts with no matches and then proceeds in stages. Each stage tries to increase the total number of matches by one. It does this by searching for an "augmenting path": a chain of edges that alternate between matched and unmatched. Once found, the algorithm flips the match status of those edges. Because the augmented path has one more unmatched edge than matched edge, this flipping increases the overall matching by one. If no augmenting path can be found, this means the optimal matching has been found and the matching cannot be improved.
      </p>
      <p>
        Inside each stage, the algorithm builds search trees starting from each unmatched vertex. Each vertex has a "budget" based originally on the maximum weight of the graph. If no augmented path can be found directly, the algorithm spends down some of the budget. This happens repeatedly until a new augmented path can be found, or the budgets prove no path exists.
      </p>

      <h3 class="font-semibold text-zinc-800">Budgets, slack, and tight edges</h3>
      <p>
        Every vertex has a budget which starts as half of the maximum input edge weight. Each edge has a related "slack". The slack for an edge that connects vertices
        <code>x</code>
        and <code>y</code>
        is calculated as <code>budget[x] + budget[y] − weight</code>. An edge is
        "tight" when its slack is zero. Once an edge is considered "tight" it can be added to the augmented path.
      </p>
      <p class="text-xs text-zinc-500">
        NOTE: All values are stored at 2× scale to avoid imprecision stemming from floating point division. The slack formula
        in this visualization reflects these 2× values.
      </p>

      <h3 class="font-semibold text-zinc-800">
        The search: <Util.s /> and <Util.t /> labels
      </h3>
      <p>
        The algorithm searches outward from each unmatched vertex. Vertices
        are labeled <Util.s /> or <Util.t />
        to track their depth: At the start of each stage, all unmatched vertices are labeled
        <Util.s />
        and go into a queue (everything else starts unlabeled). One-by-one, these are pulled off the queue. Each edge is examined and categorized as follows:
      </p>
      <ul class="list-disc ml-5 space-y-1">
        <li>
          <strong>Tight edge → unlabeled:</strong>
          Grow the search tree by labeling the neighbor <Util.t />, labeling its matching partner
          <Util.s /> and adding that newly
          <Util.s />-labeled vertex to the search queue. When this happens, we also mark that the original
          <Util.s /> vertex was the "parent" of the edge. This is important for the next case.
        </li>
        <li>
          <strong>Tight edge → <Util.s />:</strong>
          If the <Util.s />
          vertex is part of the same search tree, we need to form a blossom. Otherwise, we've found an augmenting path. If we've found an augmenting path the search can conclude and we can flip our augmenting path's matched/unmatched to gain a new edge.
        </li>
        <li><strong>Tight edge → <Util.t />:</strong> already in the tree, skip</li>
        <li>
          <strong>Not tight:</strong> recorded as a candidate for the next delta step (see below)
        </li>
      </ul>

      <h3 class="font-semibold text-zinc-800">Delta steps: spending budgets</h3>
      <p>
        When queue empties without finding an augmenting path, the algorithm adjusts each vertex budget by some value δ to
        make a new edge tight. <Util.s />-vertex budgets decrease by δ and
        <Util.t />-vertex budgets increase by δ. This increase/decrease is important in order to keep the existing tight edges tight.
      </p>
      <p>The size of δ is the <strong>minimum</strong> of four candidates:</p>
      <table class="w-full text-xs border border-zinc-200 rounded overflow-hidden">
        <thead class="bg-zinc-100 text-left">
          <tr>
            <th class="px-2 py-1 font-semibold">Δ</th>
            <th class="px-2 py-1 font-semibold">Source</th>
            <th class="px-2 py-1 font-semibold">What happens</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-zinc-100">
          <tr>
            <td class="px-2 py-1 font-mono">Δ₁</td>
            <td class="px-2 py-1">min <Util.s />-vertex budget</td>
            <td class="px-2 py-1">Budget hits 0 → stage ends, matching is optimal</td>
          </tr>
          <tr>
            <td class="px-2 py-1 font-mono">Δ₂</td>
            <td class="px-2 py-1">min slack among <Util.s /> → unlabeled</td>
            <td class="px-2 py-1">Edge becomes tight → tree grows</td>
          </tr>
          <tr>
            <td class="px-2 py-1 font-mono">Δ₃</td>
            <td class="px-2 py-1">½ min slack among <Util.s /> → <Util.s /></td>
            <td class="px-2 py-1">Edge becomes tight → augmenting path or blossom</td>
          </tr>
          <tr>
            <td class="px-2 py-1 font-mono">Δ₄</td>
            <td class="px-2 py-1">min <Util.t />-blossom budget</td>
            <td class="px-2 py-1">Budget hits 0 → expand blossom</td>
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
        tree (remember that as we scan from <Util.s />
        vertices, we label where we started searching from), it forms an "odd
        cycle." The algorithm contracts this cycle into a single super-vertex called a <strong class="text-violet-600">blossom</strong>. This is necessary because
        odd cycles break the alternating-path logic.
      </p>
      <p>
        Former <Util.t />-vertices inside a blossom become
        <Util.s />, unlocking their edges for scanning.
        Blossoms can be nested (a blossom can contain other blossoms). When a <Util.t />-blossom's
        budget reaches zero (Δ₄), it is expanded back into its sub-blossoms and scanning
        continues from the newly exposed <Util.s />-vertices.
      </p>
    </div>
    """
  end
end
