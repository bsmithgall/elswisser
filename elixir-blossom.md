# Elixir Implementation Plan: Maximum Weighted Matching (Blossom Algorithm)

This document provides a comprehensive specification for implementing Edmonds' Blossom Algorithm for Maximum Weighted Matching in Elixir. It serves as a complete reference including algorithm theory, implementation details, and references to the Python source.

## Quick Start for Future Sessions

**If you're continuing implementation work, here's what you need to know:**

1. **Reference implementation**: `priv/python/mwmatching.py` - a complete, working Python implementation
2. **Current phase**: Check what's been implemented, then find the next phase in [Implementation Phases](#implementation-phases)
3. **Key challenge**: Elixir's immutability means all state changes return new Context structs
4. **Blossom identity**: Use `make_ref()` for unique IDs; store blossoms in maps keyed by ID
5. **Testing**: Each phase has specific test cases; bipartite graphs work after Phase 7, all graphs after Phase 9

**If you're debugging:**
- See [Common Pitfalls and Debugging](#common-pitfalls-and-debugging)
- See [Critical Invariants](#critical-invariants) for what must always be true

**If you need to understand the algorithm:**
- See [Algorithm Overview](#algorithm-overview) for the high-level flow
- See [Worked Example](#worked-example-triangle-graph) for a step-by-step trace
- See [Mathematical Foundation](#mathematical-foundation) for the theory

---

## Table of Contents

1. [Algorithm Overview](#algorithm-overview)
2. [Mathematical Foundation](#mathematical-foundation)
3. [Data Structures](#data-structures)
4. [Core Algorithm Functions](#core-algorithm-functions)
5. [Implementation Phases](#implementation-phases)
6. [Python Reference Guide](#python-reference-guide)
7. [Elixir-Specific Considerations](#elixir-specific-considerations)
8. [Recommended Blossom Identity Design](#recommended-blossom-identity-design)
9. [Testing Strategy](#testing-strategy)
10. [Common Pitfalls and Debugging](#common-pitfalls-and-debugging)
11. [Critical Invariants](#critical-invariants)
12. [Worked Example: Triangle Graph](#worked-example-triangle-graph)
13. [Suggested Module Structure](#suggested-module-structure)
14. [Detailed Test Cases](#detailed-test-cases)
15. [Appendix: Algorithm Terminology](#appendix-algorithm-terminology)

---

## Algorithm Overview

### What is Maximum Weighted Matching?

Given an undirected graph G = (V, E) where each edge has a weight, a **matching** is a subset of edges such that no two edges share a vertex. A **maximum weighted matching** is a matching where the sum of edge weights is maximized.

### The Blossom Algorithm

Edmonds' Blossom Algorithm (1965) solves this problem for general graphs. The key insight is handling **odd cycles** (blossoms) by temporarily contracting them into single vertices, finding augmenting paths, and then expanding them back.

### Complexity

- Time: O(n³) for the implementation we're targeting
- Space: O(n + m) where n = vertices, m = edges

### High-Level Algorithm Flow

```
1. Initialize: empty matching, set dual variables
2. Repeat STAGES until no improvement:
   a. Label all unmatched vertices as S (roots of alternating trees)
   b. Repeat SUBSTAGES:
      - Scan S-vertices for tight edges
      - If tight edge to unlabeled vertex: extend tree (assign T, then S to mate)
      - If tight edge between S-vertices in same tree: create blossom
      - If tight edge between S-vertices in different trees: AUGMENT
      - If no tight edges: calculate delta, update duals
      - If delta type 4: expand T-blossom
   c. If augmenting path found: augment matching
   d. Reset labels for next stage
3. Return matching
```

---

## Mathematical Foundation

### Dual Linear Programming Problem

The maximum weighted matching can be formulated as a linear program. The algorithm maintains dual variables that satisfy complementary slackness conditions.

#### Dual Variables

- **Vertex duals**: `u_x` for each vertex x
- **Blossom duals**: `z_B` for each non-trivial blossom B (always >= 0)

#### Edge Slack

For an edge (x, y) with weight w:

```
slack(x,y) = u_x + u_y + sum(z_B for all blossoms B containing edge (x,y)) - w
```

An edge is **tight** when slack = 0.

#### Optimality Conditions

A matching is optimal when:
1. All dual variables are non-negative
2. All edge slacks are non-negative
3. All matched edges have zero slack
4. All unmatched vertices have zero dual
5. All blossoms with non-zero dual are "full" (all but one vertex matched internally)

### Delta Step Types

When no tight edges are available, the algorithm calculates the minimum adjustment (delta) from four sources:

| Type | Description | Formula |
|------|-------------|---------|
| δ₁ | Min dual of S-vertex | `min(u_x)` for S-vertices |
| δ₂ | Min slack to unlabeled | `min(slack(x,y))` where x is S, y is unlabeled |
| δ₃ | Half min slack between S-blossoms | `min(slack(x,y))/2` where x,y in different S-blossoms |
| δ₄ | Half min dual of T-blossom | `min(z_B)/2` for T-blossoms |

#### Dual Variable Updates

After choosing delta = min(δ₁, δ₂, δ₃, δ₄):
- S-vertices: subtract delta from dual
- T-vertices: add delta to dual
- S-blossoms: add 2*delta to blossom dual
- T-blossoms: subtract 2*delta from blossom dual

---

## Data Structures

### Graph Representation

**Module: `MaxWeightMatching.Graph`**

```elixir
defmodule MaxWeightMatching.Graph do
  @type t :: %__MODULE__{
    edges: [{non_neg_integer(), non_neg_integer(), number()}],
    num_vertex: non_neg_integer(),
    adjacent_edges: %{non_neg_integer() => [non_neg_integer()]},
    integer_weights: boolean()
  }

  defstruct [:edges, :num_vertex, :adjacent_edges, :integer_weights]
end
```

**Python Reference** (`priv/python/mwmatching.py:298-346`):
```python
class _GraphInfo:
    def __init__(self, edges: Sequence[tuple[int, int, int|float]]) -> None:
        self.edges: Sequence[tuple[int, int, int|float]] = edges

        if edges:
            self.num_vertex = 1 + max(max(x, y) for (x, y, _w) in edges)
        else:
            self.num_vertex = 0

        self.adjacent_edges: list[list[int]] = [
            [] for v in range(self.num_vertex)]
        for (e, (x, y, _w)) in enumerate(edges):
            self.adjacent_edges[x].append(e)
            self.adjacent_edges[y].append(e)

        self.integer_weights: bool = all(isinstance(w, int)
                                         for (_x, _y, w) in edges)
```

### Blossom Types

#### Labels

```elixir
@type label :: :none | :s | :t
```

**Python Reference** (`priv/python/mwmatching.py:348-352`):
```python
_LABEL_NONE = 0
_LABEL_S = 1
_LABEL_T = 2
```

#### Trivial Blossom (Single Vertex)

```elixir
defmodule MaxWeightMatching.TrivialBlossom do
  @type t :: %__MODULE__{
    base_vertex: non_neg_integer(),
    parent: reference() | nil,
    label: :none | :s | :t,
    tree_edge: {non_neg_integer(), non_neg_integer()} | nil,
    best_edge: integer(),  # -1 if none
    marker: boolean()
  }

  defstruct [
    :base_vertex,
    parent: nil,
    label: :none,
    tree_edge: nil,
    best_edge: -1,
    marker: false
  ]
end
```

**Python Reference** (`priv/python/mwmatching.py:354-418`):
```python
class _Blossom:
    def __init__(self, base_vertex: int) -> None:
        self.parent: Optional[_NonTrivialBlossom] = None
        self.base_vertex: int = base_vertex
        self.label: int = _LABEL_NONE
        self.tree_edge: Optional[tuple[int, int]] = None
        self.best_edge: int = -1
        self.marker: bool = False

    def vertices(self) -> list[int]:
        return [self.base_vertex]
```

#### Non-Trivial Blossom (Contains Sub-blossoms)

```elixir
defmodule MaxWeightMatching.NonTrivialBlossom do
  @type t :: %__MODULE__{
    base_vertex: non_neg_integer(),
    parent: reference() | nil,
    label: :none | :s | :t,
    tree_edge: {non_neg_integer(), non_neg_integer()} | nil,
    best_edge: integer(),
    marker: boolean(),
    subblossoms: [TrivialBlossom.t() | t()],
    edges: [{non_neg_integer(), non_neg_integer()}],
    dual_var: number(),
    best_edge_set: [non_neg_integer()] | nil
  }

  defstruct [
    :base_vertex,
    :subblossoms,
    :edges,
    parent: nil,
    label: :none,
    tree_edge: nil,
    best_edge: -1,
    marker: false,
    dual_var: 0,
    best_edge_set: nil
  ]
end
```

**Python Reference** (`priv/python/mwmatching.py:421-496`):
```python
class _NonTrivialBlossom(_Blossom):
    def __init__(
            self,
            subblossoms: list[_Blossom],
            edges: list[tuple[int, int]]
            ) -> None:
        super().__init__(subblossoms[0].base_vertex)

        n = len(subblossoms)
        assert len(edges) == n
        assert n >= 3
        assert n % 2 == 1

        self.subblossoms: list[_Blossom] = subblossoms
        self.edges: list[tuple[int, int]] = edges
        self.dual_var: int|float = 0
        self.best_edge_set: Optional[list[int]] = None

    def vertices(self) -> list[int]:
        # Iterative traversal using explicit stack
        stack: list[_NonTrivialBlossom] = [self]
        nodes: list[int] = []
        while stack:
            b = stack.pop()
            for sub in b.subblossoms:
                if isinstance(sub, _NonTrivialBlossom):
                    stack.append(sub)
                else:
                    nodes.append(sub.base_vertex)
        return nodes
```

### Matching Context (Algorithm State)

```elixir
defmodule MaxWeightMatching.Context do
  @type t :: %__MODULE__{
    graph: Graph.t(),
    vertex_mate: %{non_neg_integer() => integer()},  # -1 if unmatched
    trivial_blossom: %{non_neg_integer() => TrivialBlossom.t()},
    nontrivial_blossom: [NonTrivialBlossom.t()],
    vertex_top_blossom: %{non_neg_integer() => TrivialBlossom.t() | NonTrivialBlossom.t()},
    vertex_dual_2x: %{non_neg_integer() => number()},
    vertex_best_edge: %{non_neg_integer() => integer()},
    queue: :queue.queue()
  }

  defstruct [
    :graph,
    :vertex_mate,
    :trivial_blossom,
    :nontrivial_blossom,
    :vertex_top_blossom,
    :vertex_dual_2x,
    :vertex_best_edge,
    :queue
  ]
end
```

**Python Reference** (`priv/python/mwmatching.py:505-572`):
```python
class _MatchingContext:
    def __init__(self, graph: _GraphInfo) -> None:
        num_vertex = graph.num_vertex
        self.graph = graph

        # Initially all vertices unmatched
        self.vertex_mate: list[int] = num_vertex * [-1]

        # Trivial blossoms for each vertex
        self.trivial_blossom: list[_Blossom] = [_Blossom(x)
                                                for x in range(num_vertex)]

        # Initially no non-trivial blossoms
        self.nontrivial_blossom: list[_NonTrivialBlossom] = []

        # Initially each vertex is its own top-level blossom
        self.vertex_top_blossom: list[_Blossom] = self.trivial_blossom.copy()

        # Vertex duals initialized to half max weight (stored as 2x)
        max_weight = max(w for (_x, _y, w) in graph.edges)
        self.vertex_dual_2x: list[int|float] = num_vertex * [max_weight]

        # Best edge tracking
        self.vertex_best_edge: list[int] = num_vertex * [-1]

        # Queue for S-vertex scanning
        self.queue: collections.deque[int] = collections.deque()
```

---

## Core Algorithm Functions

### Input Validation

**Module: `MaxWeightMatching.Validation`**

#### `check_input_types(edges)`

Validates edge list structure and types.

**Python Reference** (`priv/python/mwmatching.py:206-251`):
```python
def _check_input_types(edges: Sequence[tuple[int, int, int|float]]) -> None:
    float_limit = sys.float_info.max / 4

    if not isinstance(edges, list):
        raise TypeError('"edges" must be a list')

    for e in edges:
        if (not isinstance(e, tuple)) or (len(e) != 3):
            raise TypeError("Each edge must be specified as a 3-tuple")

        (x, y, w) = e

        if (not isinstance(x, int)) or (not isinstance(y, int)):
            raise TypeError("Edge endpoints must be integers")

        if (x < 0) or (y < 0):
            raise ValueError("Edge endpoints must be non-negative integers")

        if not isinstance(w, (int, float)):
            raise TypeError("Edge weights must be integers or floating point numbers")

        if isinstance(w, float):
            if not math.isfinite(w):
                raise ValueError("Edge weights must be finite numbers")
            if w > float_limit:
                raise ValueError(f"Floating point edge weights must be less than {float_limit:g}")
```

#### `check_input_graph(edges)`

Validates no self-edges or duplicate edges.

**Python Reference** (`priv/python/mwmatching.py:253-281`):
```python
def _check_input_graph(edges: Sequence[tuple[int, int, int|float]]) -> None:
    # Check no self-edges
    for (x, y, _w) in edges:
        if x == y:
            raise ValueError("Self-edges are not supported")

    # Check no duplicate edges (sort and compare consecutive)
    edge_endpoints = [((x, y) if (x < y) else (y, x)) for (x, y, _w) in edges]
    edge_endpoints.sort()

    for i in range(len(edge_endpoints) - 1):
        if edge_endpoints[i] == edge_endpoints[i+1]:
            raise ValueError(f"Duplicate edge {edge_endpoints[i]}")
```

### Edge Slack Calculation

**Module: `MaxWeightMatching.Slack`**

#### `edge_slack_2x(context, edge_index)`

Returns 2x the slack of an edge (keeps integers when weights are integers).

**Python Reference** (`priv/python/mwmatching.py:574-587`):
```python
def edge_slack_2x(self, e: int) -> int|float:
    """Return 2 times the slack of the edge with index "e".

    The result is only valid for edges that are not between vertices
    that belong to the same top-level blossom.
    """
    (x, y, w) = self.graph.edges[e]
    assert self.vertex_top_blossom[x] is not self.vertex_top_blossom[y]
    return self.vertex_dual_2x[x] + self.vertex_dual_2x[y] - 2 * w
```

### Least-Slack Edge Tracking

**Module: `MaxWeightMatching.LeastSlack`**

This subsystem efficiently tracks least-slack edges for delta calculations.

#### `reset(context)`

**Python Reference** (`priv/python/mwmatching.py:620-635`):
```python
def lset_reset(self) -> None:
    num_vertex = self.graph.num_vertex

    for x in range(num_vertex):
        self.vertex_best_edge[x] = -1

    for blossom in self.trivial_blossom:
        blossom.best_edge = -1

    for blossom in self.nontrivial_blossom:
        blossom.best_edge = -1
        blossom.best_edge_set = None
```

#### `add_vertex_edge(context, y, edge_index, slack)`

Track least-slack edge from S-vertex to unlabeled/T vertex y.

**Python Reference** (`priv/python/mwmatching.py:637-649`):
```python
def lset_add_vertex_edge(self, y: int, e: int, slack: int|float) -> None:
    best_edge = self.vertex_best_edge[y]
    if best_edge == -1:
        self.vertex_best_edge[y] = e
    else:
        best_slack = self.edge_slack_2x(best_edge)
        if slack < best_slack:
            self.vertex_best_edge[y] = e
```

#### `get_best_vertex_edge(context)`

Find least-slack edge between any S-vertex and unlabeled vertex.

**Python Reference** (`priv/python/mwmatching.py:651-674`):
```python
def lset_get_best_vertex_edge(self) -> tuple[int, int|float]:
    best_index = -1
    best_slack: int|float = 0

    for x in range(self.graph.num_vertex):
        if self.vertex_top_blossom[x].label == _LABEL_NONE:
            e = self.vertex_best_edge[x]
            if e != -1:
                slack = self.edge_slack_2x(e)
                if (best_index == -1) or (slack < best_slack):
                    best_index = e
                    best_slack = slack

    return (best_index, best_slack)
```

#### `add_blossom_edge(context, blossom, edge_index, slack)`

Track edge between S-blossoms.

**Python Reference** (`priv/python/mwmatching.py:684-711`):
```python
def lset_add_blossom_edge(self, blossom: _Blossom, e: int, slack: int|float) -> None:
    # Track least-slack edge between this blossom and any other S-blossom
    if blossom.best_edge == -1:
        blossom.best_edge = e
    else:
        best_slack = self.edge_slack_2x(blossom.best_edge)
        if slack < best_slack:
            blossom.best_edge = e

    # Also add to edge set for non-trivial blossoms (for later merging)
    if isinstance(blossom, _NonTrivialBlossom):
        assert blossom.best_edge_set is not None
        blossom.best_edge_set.append(e)
```

#### `merge_blossoms(context, blossom)`

Merge edge tracking when creating new blossom.

**Python Reference** (`priv/python/mwmatching.py:713-798`):
```python
def lset_merge_blossoms(self, blossom: _NonTrivialBlossom) -> None:
    num_vertex = self.graph.num_vertex

    # Temporary array: best edge to each S-blossom (by base vertex)
    best_edge_to_blossom: list[int] = num_vertex * [-1]
    best_slack_to_blossom: list[int|float] = num_vertex * [0]

    best_edge = -1
    best_slack: int|float = 0

    # Process S-labeled sub-blossoms only
    for sub in blossom.subblossoms:
        if sub.label != _LABEL_S:
            continue

        if isinstance(sub, _NonTrivialBlossom):
            sub_edge_set = sub.best_edge_set
            sub.best_edge_set = None  # Clear from sub-blossom
        else:
            # Trivial: scan all adjacent edges
            sub_edge_set = self.graph.adjacent_edges[sub.base_vertex]

        for e in sub_edge_set:
            (x, y, _w) = self.graph.edges[e]
            bx = self.vertex_top_blossom[x]
            by = self.vertex_top_blossom[y]

            # Skip internal edges
            if bx is by:
                continue

            # Get blossom at other end
            bx = by if (bx is blossom) else bx

            # Skip non-S blossoms
            if bx.label != _LABEL_S:
                continue

            # Keep only least-slack edge to each external blossom
            slack = self.edge_slack_2x(e)
            bx_base = bx.base_vertex
            if (best_edge_to_blossom[bx_base] == -1) or (slack < best_slack_to_blossom[bx_base]):
                best_edge_to_blossom[bx_base] = e
                best_slack_to_blossom[bx_base] = slack

            if (best_edge == -1) or (slack < best_slack):
                best_edge = e
                best_slack = slack

    # Extract compact list
    blossom.best_edge_set = [e for e in best_edge_to_blossom if e != -1]
    blossom.best_edge = best_edge
```

#### `get_best_blossom_edge(context)`

Find least-slack edge between any pair of S-blossoms.

**Python Reference** (`priv/python/mwmatching.py:800-823`):
```python
def lset_get_best_blossom_edge(self) -> tuple[int, int|float]:
    best_index = -1
    best_slack: int|float = 0

    for blossom in self.trivial_blossom + self.nontrivial_blossom:
        if (blossom.label == _LABEL_S) and (blossom.parent is None):
            e = blossom.best_edge
            if e != -1:
                slack = self.edge_slack_2x(e)
                if (best_index == -1) or (slack < best_slack):
                    best_index = e
                    best_slack = slack

    return (best_index, best_slack)
```

### Alternating Path Operations

**Module: `MaxWeightMatching.AlternatingPath`**

#### `trace_alternating_paths(context, x, y)`

Trace from vertices x and y to find common ancestor (blossom) or augmenting path.

**Python Reference** (`priv/python/mwmatching.py:847-925`):
```python
def trace_alternating_paths(self, x: int, y: int) -> _AlternatingPath:
    marked_blossoms: list[_Blossom] = []

    # Pre-load edge (x, y) on both paths
    xedges: list[tuple[int, int]] = [(x, y)]
    yedges: list[tuple[int, int]] = [(y, x)]

    first_common: Optional[_Blossom] = None

    # Alternate between tracing from x and y
    while x != -1 or y != -1:
        # Check if we found common ancestor
        bx = self.vertex_top_blossom[x]
        if bx.marker:
            first_common = bx
            break

        # Mark as potential common ancestor
        bx.marker = True
        marked_blossoms.append(bx)

        # Track back through tree
        if bx.tree_edge is None:
            x = -1  # Reached root
        else:
            xedges.append(bx.tree_edge)
            x = bx.tree_edge[0]

        # Swap to alternate between paths
        if y != -1:
            (x, y) = (y, x)
            (xedges, yedges) = (yedges, xedges)

    # Clear markers
    for b in marked_blossoms:
        b.marker = False

    # Trim paths if common ancestor found
    if first_common is not None:
        assert self.vertex_top_blossom[xedges[-1][0]] is first_common
        while self.vertex_top_blossom[yedges[-1][0]] is not first_common:
            yedges.pop()

    # Fuse paths: reverse one, flip edges in other
    path_edges = xedges[::-1] + [(y, x) for (x, y) in yedges[1:]]

    assert len(path_edges) % 2 == 1  # Must be odd length

    return _AlternatingPath(path_edges)
```

#### `find_path_through_blossom(blossom, sub_blossom)`

Construct path from sub-blossom to base of parent blossom.

**Python Reference** (`priv/python/mwmatching.py:983-1008`):
```python
@staticmethod
def find_path_through_blossom(
        blossom: _NonTrivialBlossom,
        sub: _Blossom
        ) -> tuple[list[_Blossom], list[tuple[int, int]]]:

    # Find position of sub in parent's list
    p = blossom.subblossoms.index(sub)

    if p % 2 == 0:
        # Walk backwards, flip edge directions
        nodes = blossom.subblossoms[p::-1]
        edges = [(j, i) for (i, j) in blossom.edges[:p][::-1]]
    else:
        # Walk forwards
        nodes = blossom.subblossoms[p:] + blossom.subblossoms[0:1]
        edges = blossom.edges[p:]

    return (nodes, edges)
```

### Blossom Operations

**Module: `MaxWeightMatching.BlossomOps`**

#### `make_blossom(context, path)`

Create new blossom from alternating cycle.

**Python Reference** (`priv/python/mwmatching.py:931-981`):
```python
def make_blossom(self, path: _AlternatingPath) -> None:
    assert len(path.edges) % 2 == 1
    assert len(path.edges) >= 3

    # Get sub-blossoms from path
    subblossoms = [self.vertex_top_blossom[x] for (x, y) in path.edges]

    # Verify cyclic
    subblossoms_next = [self.vertex_top_blossom[y] for (x, y) in path.edges]
    assert subblossoms[0] == subblossoms_next[-1]
    assert subblossoms[1:] == subblossoms_next[:-1]

    # Create new blossom
    blossom = _NonTrivialBlossom(subblossoms, path.edges)
    self.nontrivial_blossom.append(blossom)

    # Link sub-blossoms to parent
    for sub in subblossoms:
        sub.parent = blossom

    # Update vertex -> blossom mapping
    for x in blossom.vertices():
        self.vertex_top_blossom[x] = blossom

    # Assign label S
    assert subblossoms[0].label == _LABEL_S
    blossom.label = _LABEL_S
    blossom.tree_edge = subblossoms[0].tree_edge

    # Add former T-vertices to queue
    for sub in subblossoms:
        if sub.label == _LABEL_T:
            self.queue.extend(sub.vertices())

    # Merge edge tracking
    self.lset_merge_blossoms(blossom)
```

#### `expand_t_blossom(context, blossom)`

Expand T-labeled blossom.

**Python Reference** (`priv/python/mwmatching.py:1010-1070`):
```python
def expand_t_blossom(self, blossom: _NonTrivialBlossom) -> None:
    assert blossom.parent is None
    assert blossom.label == _LABEL_T

    # Convert sub-blossoms to top-level
    for sub in blossom.subblossoms:
        assert sub.label == _LABEL_NONE
        sub.parent = None
        if isinstance(sub, _NonTrivialBlossom):
            for x in sub.vertices():
                self.vertex_top_blossom[x] = sub
        else:
            self.vertex_top_blossom[sub.base_vertex] = sub

    # Find sub-blossom attached to tree parent
    assert blossom.tree_edge is not None
    (x, y) = blossom.tree_edge
    sub = self.vertex_top_blossom[y]

    # Assign T to that sub-blossom
    sub.label = _LABEL_T
    sub.tree_edge = blossom.tree_edge

    # Walk through blossom, assign alternating labels
    (path_nodes, path_edges) = self.find_path_through_blossom(blossom, sub)

    for p in range(0, len(path_edges), 2):
        # Pattern: T -- S -- T
        (y, x) = path_edges[p]
        self.assign_label_s(x)

        sub = path_nodes[p+2]
        sub.label = _LABEL_T
        sub.tree_edge = path_edges[p+1]

    # Remove blossom
    self.nontrivial_blossom.remove(blossom)
```

#### `expand_unlabeled_blossom(context, blossom)`

Expand unlabeled blossom (simpler case).

**Python Reference** (`priv/python/mwmatching.py:1072-1093`):
```python
def expand_unlabeled_blossom(self, blossom: _NonTrivialBlossom) -> None:
    assert blossom.parent is None
    assert blossom.label == _LABEL_NONE

    # Convert sub-blossoms to top-level
    for sub in blossom.subblossoms:
        assert sub.label == _LABEL_NONE
        sub.parent = None

        if isinstance(sub, _NonTrivialBlossom):
            for x in sub.vertices():
                self.vertex_top_blossom[x] = sub
        else:
            self.vertex_top_blossom[sub.base_vertex] = sub

    # Remove blossom
    self.nontrivial_blossom.remove(blossom)
```

### Augmentation

**Module: `MaxWeightMatching.Augment`**

#### `augment_blossom(context, blossom, sub_blossom)`

Augment through blossom from sub to base.

**Python Reference** (`priv/python/mwmatching.py:1158-1194`):
```python
def augment_blossom(self, blossom: _NonTrivialBlossom, sub: _Blossom) -> None:
    # Use explicit stack to avoid deep recursion
    stack = [(blossom, sub)]

    while stack:
        (outer_blossom, sub) = stack.pop()
        assert sub.parent is not None
        blossom = sub.parent

        if blossom != outer_blossom:
            # Need to augment through intermediate blossoms first
            stack.append((outer_blossom, blossom))

        # Augment this level
        self.augment_blossom_rec(blossom, sub, stack)
```

#### `augment_blossom_rec(context, blossom, sub, stack)`

Helper for augment_blossom.

**Python Reference** (`priv/python/mwmatching.py:1099-1156`):
```python
def augment_blossom_rec(self, blossom: _NonTrivialBlossom, sub: _Blossom,
                        stack: list[tuple[_NonTrivialBlossom, _Blossom]]) -> None:
    (path_nodes, path_edges) = self.find_path_through_blossom(blossom, sub)

    for p in range(0, len(path_edges), 2):
        # Pull edge (x, y) into matching
        (x, y) = path_edges[p+1]
        self.vertex_mate[x] = y
        self.vertex_mate[y] = x

        # Queue non-trivial sub-blossoms for recursive augmentation
        bx = path_nodes[p+1]
        if isinstance(bx, _NonTrivialBlossom):
            stack.append((bx, self.trivial_blossom[x]))

        by = path_nodes[p+2]
        if isinstance(by, _NonTrivialBlossom):
            stack.append((by, self.trivial_blossom[y]))

    # Rotate so new base is at position 0
    p = blossom.subblossoms.index(sub)
    blossom.subblossoms = blossom.subblossoms[p:] + blossom.subblossoms[:p]
    blossom.edges = blossom.edges[p:] + blossom.edges[:p]

    # Update base vertex
    blossom.base_vertex = sub.base_vertex
```

#### `augment_matching(context, path)`

Augment matching along augmenting path.

**Python Reference** (`priv/python/mwmatching.py:1196-1234`):
```python
def augment_matching(self, path: _AlternatingPath) -> None:
    # Verify path endpoints are unmatched
    assert len(path.edges) % 2 == 1
    for x in (path.edges[0][0], path.edges[-1][1]):
        b = self.vertex_top_blossom[x]
        assert self.vertex_mate[b.base_vertex] == -1

    # Walk through unmatched edges (positions 0, 2, 4, ...)
    for (x, y) in path.edges[0::2]:
        # Augment through non-trivial blossoms
        bx = self.vertex_top_blossom[x]
        if isinstance(bx, _NonTrivialBlossom):
            self.augment_blossom(bx, self.trivial_blossom[x])

        by = self.vertex_top_blossom[y]
        if isinstance(by, _NonTrivialBlossom):
            self.augment_blossom(by, self.trivial_blossom[y])

        # Pull edge into matching
        self.vertex_mate[x] = y
        self.vertex_mate[y] = x
```

### Labeling

**Module: `MaxWeightMatching.Label`**

#### `assign_label_s(context, x)`

Label blossom containing x as S.

**Python Reference** (`priv/python/mwmatching.py:1240-1281`):
```python
def assign_label_s(self, x: int) -> None:
    bx = self.vertex_top_blossom[x]
    assert bx.label == _LABEL_NONE
    bx.label = _LABEL_S

    y = self.vertex_mate[x]
    if y == -1:
        # Unmatched: this is a tree root
        assert bx.base_vertex == x
        bx.tree_edge = None
    else:
        # Matched to T-vertex
        by = self.vertex_top_blossom[y]
        assert by.label == _LABEL_T
        bx.tree_edge = (y, x)

    # Start edge tracking
    self.lset_new_blossom(bx)

    # Add all vertices to queue
    self.queue.extend(bx.vertices())
```

#### `assign_label_t(context, x, y)`

Label blossom containing y as T, attached via edge from x.

**Python Reference** (`priv/python/mwmatching.py:1283-1311`):
```python
def assign_label_t(self, x: int, y: int) -> None:
    assert self.vertex_top_blossom[x].label == _LABEL_S

    by = self.vertex_top_blossom[y]

    # Expand zero-dual blossoms before labeling
    while isinstance(by, _NonTrivialBlossom) and (by.dual_var == 0):
        self.expand_unlabeled_blossom(by)
        by = self.vertex_top_blossom[y]

    # Assign label T
    assert by.label == _LABEL_NONE
    by.label = _LABEL_T
    by.tree_edge = (x, y)

    # Assign label S to matched blossom
    z = self.vertex_mate[by.base_vertex]
    assert z != -1
    self.assign_label_s(z)
```

### Main Algorithm Loop

**Module: `MaxWeightMatching.Stage`**

#### `substage_scan(context)`

Scan S-vertices to expand alternating trees.

**Python Reference** (`priv/python/mwmatching.py:1342-1414`):
```python
def substage_scan(self) -> Optional[_AlternatingPath]:
    edges = self.graph.edges
    adjacent_edges = self.graph.adjacent_edges

    while self.queue:
        x = self.queue.popleft()
        bx = self.vertex_top_blossom[x]
        assert bx.label == _LABEL_S

        for e in adjacent_edges[x]:
            (p, q, _w) = edges[e]
            y = p if p != x else q

            bx = self.vertex_top_blossom[x]  # May have changed
            by = self.vertex_top_blossom[y]

            # Skip internal edges
            if bx is by:
                continue

            ylabel = by.label
            slack = self.edge_slack_2x(e)

            if slack <= 0:  # Tight edge
                if ylabel == _LABEL_NONE:
                    self.assign_label_t(x, y)
                elif ylabel == _LABEL_S:
                    alternating_path = self.add_s_to_s_edge(x, y)
                    if alternating_path is not None:
                        return alternating_path

            elif ylabel == _LABEL_S:
                self.lset_add_blossom_edge(bx, e, slack)

            if ylabel != _LABEL_S:
                self.lset_add_vertex_edge(y, e, slack)

    return None
```

#### `add_s_to_s_edge(context, x, y)`

Handle edge between two S-vertices.

**Python Reference** (`priv/python/mwmatching.py:1313-1340`):
```python
def add_s_to_s_edge(self, x: int, y: int) -> Optional[_AlternatingPath]:
    path = self.trace_alternating_paths(x, y)

    p = path.edges[0][0]
    q = path.edges[-1][1]

    if self.vertex_top_blossom[p] is self.vertex_top_blossom[q]:
        # Same blossom: create new blossom
        self.make_blossom(path)
        return None
    else:
        # Different trees: augmenting path found
        return path
```

#### `substage_calc_dual_delta(context)`

Calculate minimum delta from four types.

**Python Reference** (`priv/python/mwmatching.py:1420-1484`):
```python
def substage_calc_dual_delta(self) -> tuple[int, float|int, int, Optional[_NonTrivialBlossom]]:
    num_vertex = self.graph.num_vertex

    delta_edge = -1
    delta_blossom: Optional[_NonTrivialBlossom] = None

    # Delta1: min dual of S-vertices
    delta_type = 1
    delta_2x = min(
        self.vertex_dual_2x[x]
        for x in range(num_vertex)
        if self.vertex_top_blossom[x].label == _LABEL_S)

    # Delta2: min slack to unlabeled vertex
    (e, slack) = self.lset_get_best_vertex_edge()
    if (e != -1) and (slack <= delta_2x):
        delta_type = 2
        delta_2x = slack
        delta_edge = e

    # Delta3: half min slack between S-blossoms
    (e, slack) = self.lset_get_best_blossom_edge()
    if e != -1:
        if self.graph.integer_weights:
            assert slack % 2 == 0
            slack = slack // 2
        else:
            slack = slack / 2
        if slack <= delta_2x:
            delta_type = 3
            delta_2x = slack
            delta_edge = e

    # Delta4: min dual of T-blossom
    for blossom in self.nontrivial_blossom:
        if (blossom.label == _LABEL_T) and (blossom.parent is None):
            if blossom.dual_var <= delta_2x:
                delta_type = 4
                delta_2x = blossom.dual_var
                delta_blossom = blossom

    return (delta_type, delta_2x, delta_edge, delta_blossom)
```

#### `substage_apply_delta_step(context, delta_2x)`

Apply delta to dual variables.

**Python Reference** (`priv/python/mwmatching.py:1486-1510`):
```python
def substage_apply_delta_step(self, delta_2x: int|float) -> None:
    num_vertex = self.graph.num_vertex

    # Update vertex duals
    for x in range(num_vertex):
        xlabel = self.vertex_top_blossom[x].label
        if xlabel == _LABEL_S:
            self.vertex_dual_2x[x] -= delta_2x
        elif xlabel == _LABEL_T:
            self.vertex_dual_2x[x] += delta_2x

    # Update blossom duals
    for blossom in self.nontrivial_blossom:
        if blossom.parent is None:
            blabel = blossom.label
            if blabel == _LABEL_S:
                blossom.dual_var += delta_2x
            elif blabel == _LABEL_T:
                blossom.dual_var -= delta_2x
```

#### `run_stage(context)`

Execute one complete stage.

**Python Reference** (`priv/python/mwmatching.py:1516-1602`):
```python
def run_stage(self) -> bool:
    num_vertex = self.graph.num_vertex

    # Label unmatched vertices as S
    for x in range(num_vertex):
        if self.vertex_mate[x] == -1:
            self.assign_label_s(x)

    # Stop if all matched
    if not self.queue:
        return False

    augmenting_path = None
    while True:
        # Scan for augmenting path
        augmenting_path = self.substage_scan()
        if augmenting_path is not None:
            break

        # Calculate and apply delta
        (delta_type, delta_2x, delta_edge, delta_blossom) = self.substage_calc_dual_delta()
        self.substage_apply_delta_step(delta_2x)

        if delta_type == 2:
            # Unlocked S-to-unlabeled edge
            (x, y, _w) = self.graph.edges[delta_edge]
            if self.vertex_top_blossom[x].label != _LABEL_S:
                (x, y) = (y, x)
            self.assign_label_t(x, y)

        elif delta_type == 3:
            # Unlocked S-to-S edge
            (x, y, _w) = self.graph.edges[delta_edge]
            augmenting_path = self.add_s_to_s_edge(x, y)
            if augmenting_path is not None:
                break

        elif delta_type == 4:
            # Expand T-blossom
            assert delta_blossom is not None
            self.expand_t_blossom(delta_blossom)

        else:
            # No improvement possible
            assert delta_type == 1
            break

    # Augment if path found
    if augmenting_path is not None:
        self.augment_matching(augmenting_path)

    # Reset for next stage
    self.reset_stage()

    return (augmenting_path is not None)
```

#### `reset_stage(context)`

Clear labels and queue for next stage.

**Python Reference** (`priv/python/mwmatching.py:829-845`):
```python
def reset_stage(self) -> None:
    # Remove blossom labels
    for blossom in self.trivial_blossom + self.nontrivial_blossom:
        blossom.label = _LABEL_NONE
        blossom.tree_edge = None

    # Clear queue
    self.queue.clear()

    # Reset edge tracking
    self.lset_reset()
```

### Main Entry Point

**Module: `MaxWeightMatching`**

#### `maximum_weight_matching(edges)`

**Python Reference** (`priv/python/mwmatching.py:37-115`):
```python
def maximum_weight_matching(edges: Sequence[tuple[int, int, int|float]]) -> list[tuple[int, int]]:
    # Validate input
    _check_input_types(edges)
    _check_input_graph(edges)

    # Remove negative edges
    edges = _remove_negative_weight_edges(edges)

    # Handle empty graph
    if not edges:
        return []

    # Initialize
    graph = _GraphInfo(edges)
    ctx = _MatchingContext(graph)

    # Run stages until no improvement
    while ctx.run_stage():
        pass

    # Extract result
    pairs: list[tuple[int, int]] = [
        (x, y) for (x, y, _w) in edges if ctx.vertex_mate[x] == y]

    # Verify (for integer weights)
    if graph.integer_weights:
        _verify_optimum(ctx)

    return pairs
```

#### `adjust_weights_for_maximum_cardinality_matching(edges)`

**Python Reference** (`priv/python/mwmatching.py:118-195`):
```python
def adjust_weights_for_maximum_cardinality_matching(
        edges: Sequence[tuple[int, int, int|float]]
        ) -> Sequence[tuple[int, int, int|float]]:

    _check_input_types(edges)

    if not edges:
        return edges

    num_vertex = 1 + max(max(x, y) for (x, y, _w) in edges)

    min_weight = min(w for (_x, _y, w) in edges)
    max_weight = max(w for (_x, _y, w) in edges)
    weight_range = max_weight - min_weight

    # Check if already satisfies conditions
    if min_weight > 0 and min_weight >= num_vertex * weight_range:
        return edges

    # Calculate adjustment
    if weight_range > 0:
        delta = num_vertex * weight_range - min_weight
    else:
        delta = 1 - min_weight

    return [(x, y, w + delta) for (x, y, w) in edges]
```

---

## Implementation Phases

The implementation is broken into 10 phases, each sized to fit within a single Claude Code session. Each phase has 2-4 functions and a clear testing boundary.

### Phase 1: Foundation - Graph and Validation

**Goal:** Set up input parsing and validation.

**Functions to implement:**
1. `MaxWeightMatching.Graph.new/1` - Parse edges, build adjacency lists, derive `num_vertex`, track `integer_weights`
2. `MaxWeightMatching.Validation.check_input_types/1` - Validate edge list structure
3. `MaxWeightMatching.Validation.check_input_graph/1` - Check no self-edges or duplicates
4. `MaxWeightMatching.Validation.remove_negative_weight_edges/1` - Filter negative weights

**Testing:** Unit tests for valid/invalid inputs, edge cases (empty list, single edge).

**Python references:**
- `_GraphInfo.__init__`: lines 304-345
- `_check_input_types`: lines 206-251
- `_check_input_graph`: lines 253-281
- `_remove_negative_weight_edges`: lines 284-295

---

### Phase 2: Foundation - Blossom Structs and Context

**Goal:** Define core data structures.

**Functions to implement:**
1. `MaxWeightMatching.Blossom` module with `TrivialBlossom` and `NonTrivialBlossom` structs
2. `MaxWeightMatching.Blossom.vertices/1` - Return list of vertices (trivial case)
3. `MaxWeightMatching.Blossom.vertices/1` - Return list of vertices (non-trivial, recursive)
4. `MaxWeightMatching.Context.new/1` - Initialize from graph (vertex_mate, trivial_blossom, vertex_top_blossom, vertex_dual_2x, queue)

**Testing:** Unit tests for struct creation, `vertices/1` for nested blossoms.

**Python references:**
- `_Blossom.__init__`: lines 374-414
- `_Blossom.vertices`: lines 416-418
- `_NonTrivialBlossom.__init__`: lines 440-479
- `_NonTrivialBlossom.vertices`: lines 481-496
- `_MatchingContext.__init__`: lines 512-572

---

### Phase 3: Basic Operations - Slack and Edge Tracking

**Goal:** Implement edge slack calculation and least-slack tracking (without merge).

**Functions to implement:**
1. `MaxWeightMatching.Slack.edge_slack_2x/2` - Calculate 2x slack of an edge
2. `MaxWeightMatching.LeastSlack.reset/1` - Reset all edge tracking
3. `MaxWeightMatching.LeastSlack.add_vertex_edge/4` - Track S-to-vertex edge
4. `MaxWeightMatching.LeastSlack.get_best_vertex_edge/1` - Find best S-to-unlabeled edge
5. `MaxWeightMatching.LeastSlack.new_blossom/1` - Initialize tracking for new S-blossom
6. `MaxWeightMatching.LeastSlack.add_blossom_edge/4` - Track S-to-S edge
7. `MaxWeightMatching.LeastSlack.get_best_blossom_edge/1` - Find best S-to-S edge

**Note:** Defer `merge_blossoms/2` to Phase 7.

**Testing:** Unit tests with manually constructed contexts.

**Python references:**
- `edge_slack_2x`: lines 574-587
- `lset_reset`: lines 620-635
- `lset_add_vertex_edge`: lines 637-649
- `lset_get_best_vertex_edge`: lines 651-674
- `lset_new_blossom`: lines 676-682
- `lset_add_blossom_edge`: lines 684-711
- `lset_get_best_blossom_edge`: lines 800-823

---

### Phase 4: Basic Operations - Labeling

**Goal:** Implement S and T label assignment.

**Functions to implement:**
1. `MaxWeightMatching.Label.assign_label_s/2` - Label blossom as S, add vertices to queue
2. `MaxWeightMatching.Label.assign_label_t/3` - Label blossom as T, then call assign_label_s on mate

**Note:** `assign_label_t` calls `expand_unlabeled_blossom` which doesn't exist yet. For this phase, implement a simplified version that skips the expansion loop (assumes no zero-dual blossoms). We'll update it in Phase 8.

**Testing:** Unit tests verifying labels are set correctly, queue is populated.

**Python references:**
- `assign_label_s`: lines 1240-1281
- `assign_label_t`: lines 1283-1311

---

### Phase 5: Delta Mechanics

**Goal:** Implement dual variable updates.

**Functions to implement:**
1. `MaxWeightMatching.Stage.substage_calc_dual_delta/1` - Calculate min delta from 4 types
2. `MaxWeightMatching.Stage.substage_apply_delta_step/2` - Apply delta to vertex and blossom duals
3. `MaxWeightMatching.Stage.reset_stage/1` - Clear labels, queue, and edge tracking

**Testing:** Unit tests with known delta scenarios.

**Python references:**
- `substage_calc_dual_delta`: lines 1420-1484
- `substage_apply_delta_step`: lines 1486-1510
- `reset_stage`: lines 829-845

---

### Phase 6: Path Operations and Simple Augmentation

**Goal:** Implement path tracing and augmentation (without blossom support).

**Functions to implement:**
1. `MaxWeightMatching.AlternatingPath.trace_alternating_paths/3` - Trace from x,y to find path (simplified: no blossom traversal yet)
2. `MaxWeightMatching.Augment.augment_matching/2` - Augment along path (simplified: skip blossom augmentation)
3. `MaxWeightMatching.Stage.add_s_to_s_edge/3` - Handle S-to-S edge (simplified: only return augmenting path, no blossom creation)

**Testing:** Test on simple trees without odd cycles.

**Python references:**
- `trace_alternating_paths`: lines 847-925
- `augment_matching`: lines 1196-1234
- `add_s_to_s_edge`: lines 1313-1340

---

### Phase 7: Stage Integration and Bipartite Testing

**Goal:** Complete the main loop for bipartite graphs.

**Functions to implement:**
1. `MaxWeightMatching.Stage.substage_scan/1` - Scan S-vertices (with simplified add_s_to_s_edge)
2. `MaxWeightMatching.Stage.run_stage/1` - Execute one complete stage
3. `MaxWeightMatching.maximum_weight_matching/1` - Main entry point

**Testing:** Test on bipartite graphs (paths, even cycles, complete bipartite). These don't require blossoms.

**Python references:**
- `substage_scan`: lines 1342-1414
- `run_stage`: lines 1516-1602
- `maximum_weight_matching`: lines 37-115

**Milestone:** At this point, the algorithm works correctly for all bipartite graphs!

---

### Phase 8: Blossom Creation and Path Through Blossom

**Goal:** Add ability to create and navigate blossoms.

**Functions to implement:**
1. `MaxWeightMatching.BlossomOps.make_blossom/2` - Create blossom from alternating cycle
2. `MaxWeightMatching.LeastSlack.merge_blossoms/2` - Merge edge tracking for new blossom (deferred from Phase 3)
3. `MaxWeightMatching.BlossomOps.find_path_through_blossom/2` - Path from sub-blossom to base
4. Update `add_s_to_s_edge/3` to call `make_blossom` when cycle detected

**Testing:** Test blossom creation on triangles and other odd cycles.

**Python references:**
- `make_blossom`: lines 931-981
- `lset_merge_blossoms`: lines 713-798
- `find_path_through_blossom`: lines 983-1008

---

### Phase 9: Blossom Expansion and Augmentation

**Goal:** Complete blossom support.

**Functions to implement:**
1. `MaxWeightMatching.BlossomOps.expand_unlabeled_blossom/2` - Expand unlabeled blossom
2. `MaxWeightMatching.BlossomOps.expand_t_blossom/2` - Expand T-blossom (more complex)
3. `MaxWeightMatching.Augment.augment_blossom/3` - Augment through blossom
4. `MaxWeightMatching.Augment.augment_blossom_rec/4` - Helper for augment_blossom
5. Update `assign_label_t/3` to expand zero-dual blossoms
6. Update `augment_matching/2` to call `augment_blossom`

**Testing:** Test on graphs with odd cycles (triangle, pentagon, nested blossoms).

**Python references:**
- `expand_unlabeled_blossom`: lines 1072-1093
- `expand_t_blossom`: lines 1010-1070
- `augment_blossom`: lines 1158-1194
- `augment_blossom_rec`: lines 1099-1156

**Milestone:** At this point, the algorithm works correctly for all graphs!

---

### Phase 10: Verification and Polish

**Goal:** Add verification and cardinality adjustment.

**Functions to implement:**
1. `MaxWeightMatching.Verification.verify_optimum/1` - Verify matching is optimal
2. `MaxWeightMatching.Verification.verify_blossom_edges/3` - Helper for verify_optimum
3. `MaxWeightMatching.adjust_weights_for_maximum_cardinality_matching/1` - Weight adjustment

**Testing:**
- Run verification on all test cases
- Property-based tests with random graphs
- Comparison tests against Python implementation

**Python references:**
- `_verify_optimum`: lines 1731-1810
- `_verify_blossom_edges`: lines 1605-1728
- `adjust_weights_for_maximum_cardinality_matching`: lines 118-195

---

### Phase Summary

| Phase | Focus | Key Functions | Testing Milestone |
|-------|-------|---------------|-------------------|
| 1 | Graph & Validation | 4 functions | Input validation works |
| 2 | Structs & Context | 4 functions | Data structures work |
| 3 | Slack & Edge Tracking | 7 functions | Edge tracking works |
| 4 | Labeling | 2 functions | Labels assigned correctly |
| 5 | Delta Mechanics | 3 functions | Dual updates work |
| 6 | Paths & Augmentation | 3 functions | Simple paths work |
| 7 | Stage Integration | 3 functions | **Bipartite graphs work** |
| 8 | Blossom Creation | 4 functions | Blossoms created correctly |
| 9 | Blossom Expansion | 6 functions | **All graphs work** |
| 10 | Verification | 3 functions | Optimality verified |

---

## Python Reference Guide

### File Structure

The Python implementation is in `priv/python/mwmatching.py`:

| Lines | Content |
|-------|---------|
| 1-35 | License and docstring |
| 37-115 | `maximum_weight_matching()` - Main entry point |
| 118-195 | `adjust_weights_for_maximum_cardinality_matching()` |
| 198-203 | `MatchingError` exception |
| 206-251 | `_check_input_types()` |
| 253-281 | `_check_input_graph()` |
| 284-295 | `_remove_negative_weight_edges()` |
| 298-346 | `_GraphInfo` class |
| 348-352 | Label constants |
| 354-418 | `_Blossom` class (trivial) |
| 421-496 | `_NonTrivialBlossom` class |
| 499-503 | `_AlternatingPath` named tuple |
| 505-1602 | `_MatchingContext` class (main algorithm) |
| 1605-1728 | `_verify_blossom_edges()` |
| 1731-1810 | `_verify_optimum()` |

### Key Methods in `_MatchingContext`

| Method | Lines | Purpose |
|--------|-------|---------|
| `__init__` | 512-572 | Initialize algorithm state |
| `edge_slack_2x` | 574-587 | Calculate edge slack |
| `lset_reset` | 620-635 | Reset edge tracking |
| `lset_add_vertex_edge` | 637-649 | Track S-to-vertex edge |
| `lset_get_best_vertex_edge` | 651-674 | Find best S-to-unlabeled edge |
| `lset_new_blossom` | 676-682 | Init edge tracking for new S-blossom |
| `lset_add_blossom_edge` | 684-711 | Track S-to-S edge |
| `lset_merge_blossoms` | 713-798 | Merge edge tracking for new blossom |
| `lset_get_best_blossom_edge` | 800-823 | Find best S-to-S edge |
| `reset_stage` | 829-845 | Clear labels and queue |
| `trace_alternating_paths` | 847-925 | Find augmenting path or blossom |
| `make_blossom` | 931-981 | Create blossom from cycle |
| `find_path_through_blossom` | 983-1008 | Path from sub to base |
| `expand_t_blossom` | 1010-1070 | Expand T-blossom |
| `expand_unlabeled_blossom` | 1072-1093 | Expand unlabeled blossom |
| `augment_blossom_rec` | 1099-1156 | Augment through blossom (helper) |
| `augment_blossom` | 1158-1194 | Augment through blossom |
| `augment_matching` | 1196-1234 | Augment along path |
| `assign_label_s` | 1240-1281 | Label blossom as S |
| `assign_label_t` | 1283-1311 | Label blossom as T |
| `add_s_to_s_edge` | 1313-1340 | Handle S-to-S edge |
| `substage_scan` | 1342-1414 | Scan S-vertices |
| `substage_calc_dual_delta` | 1420-1484 | Calculate delta |
| `substage_apply_delta_step` | 1486-1510 | Apply delta |
| `run_stage` | 1516-1602 | Run one stage |

---

## Elixir-Specific Considerations

### Immutability

All state changes must return new structs. The pattern will be:

```elixir
def some_operation(context, args) do
  # ... compute changes ...
  %{context | field1: new_value1, field2: new_value2}
end
```

Consider threading context through with `with` or pipeline operators.

### Data Structure Choices

| Python | Elixir | Notes |
|--------|--------|-------|
| `list[int]` for vertex_mate | `%{vertex => mate}` | Map for O(log n) access |
| `list[Blossom]` indexed by vertex | `%{vertex => blossom_id}` | Use IDs, store blossoms in separate map |
| `collections.deque` | `:queue` module | `:queue.in/2`, `:queue.out/1` |
| Object identity (`is`) | Compare by ID | Blossoms need unique identifiers |
| Mutable object fields | Structs with updates | Return new structs |

### Blossom Identity

Python uses `is` to compare blossoms. In Elixir:

```elixir
# Option 1: Use make_ref() for IDs
%TrivialBlossom{id: make_ref(), ...}

# Option 2: Use vertex as ID for trivial, index for non-trivial
trivial_blossom_id = {:trivial, vertex}
nontrivial_blossom_id = {:nontrivial, index}

# Store all blossoms in a map
blossoms = %{blossom_id => blossom_struct}
```

### Recursion Patterns

The Python code uses explicit stacks to avoid deep recursion. In Elixir, prefer tail recursion with accumulators:

```elixir
# For vertices/1 in NonTrivialBlossom
def vertices(blossom, blossoms_map) do
  do_vertices([blossom.id], [], blossoms_map)
end

defp do_vertices([], acc, _blossoms), do: acc
defp do_vertices([id | rest], acc, blossoms) do
  case Map.get(blossoms, id) do
    %TrivialBlossom{base_vertex: v} ->
      do_vertices(rest, [v | acc], blossoms)
    %NonTrivialBlossom{subblossoms: subs} ->
      do_vertices(subs ++ rest, acc, blossoms)
  end
end
```

### Pattern Matching

Use pattern matching for blossom type dispatch:

```elixir
def vertices(%TrivialBlossom{base_vertex: v}), do: [v]
def vertices(%NonTrivialBlossom{} = b), do: collect_vertices(b)

def handle_delta(context, 1, _edge, _blossom), do: context  # No improvement
def handle_delta(context, 2, edge, _blossom), do: assign_label_t_from_edge(context, edge)
def handle_delta(context, 3, edge, _blossom), do: add_s_to_s_edge_from_edge(context, edge)
def handle_delta(context, 4, _edge, blossom), do: expand_t_blossom(context, blossom)
```

### Queue Operations

```elixir
# Initialize
queue = :queue.new()

# Enqueue
queue = :queue.in(item, queue)

# Enqueue multiple
queue = Enum.reduce(items, queue, fn item, q -> :queue.in(item, q) end)

# Dequeue
case :queue.out(queue) do
  {{:value, item}, new_queue} -> {item, new_queue}
  {:empty, queue} -> :empty
end

# Check empty
:queue.is_empty(queue)
```

### Integer Division

For delta3 with integer weights:

```elixir
# Python: slack // 2
# Elixir:
slack = div(slack, 2)
```

---

## Recommended Blossom Identity Design

The most challenging Elixir design decision is handling blossom identity. Python uses object identity (`is`), which doesn't translate directly. Here's the recommended approach:

### Use `make_ref()` for Unique IDs

```elixir
defmodule MaxWeightMatching.Blossom do
  defmodule Trivial do
    defstruct [:id, :base_vertex, :parent_id, :label, :tree_edge, :best_edge, :marker]

    def new(vertex) do
      %__MODULE__{
        id: make_ref(),
        base_vertex: vertex,
        parent_id: nil,
        label: :none,
        tree_edge: nil,
        best_edge: -1,
        marker: false
      }
    end
  end

  defmodule NonTrivial do
    defstruct [:id, :base_vertex, :parent_id, :label, :tree_edge, :best_edge, :marker,
               :subblossom_ids, :edges, :dual_var, :best_edge_set]

    def new(subblossom_ids, edges, base_vertex) do
      %__MODULE__{
        id: make_ref(),
        base_vertex: base_vertex,
        parent_id: nil,
        label: :none,
        tree_edge: nil,
        best_edge: -1,
        marker: false,
        subblossom_ids: subblossom_ids,
        edges: edges,
        dual_var: 0,
        best_edge_set: nil
      }
    end
  end
end
```

### Store Blossoms in a Map

```elixir
defmodule MaxWeightMatching.Context do
  defstruct [
    :graph,
    :vertex_mate,           # %{vertex => vertex | -1}
    :blossoms,              # %{ref() => Trivial.t() | NonTrivial.t()}
    :vertex_top_blossom_id, # %{vertex => ref()}
    :vertex_dual_2x,        # %{vertex => number}
    :vertex_best_edge,      # %{vertex => edge_index | -1}
    :queue                  # :queue.queue()
  ]

  def new(graph) do
    # Create trivial blossoms for each vertex
    trivial_blossoms =
      for v <- 0..(graph.num_vertex - 1), into: %{} do
        blossom = Blossom.Trivial.new(v)
        {blossom.id, blossom}
      end

    # Map vertices to their blossom IDs
    vertex_to_blossom =
      for {id, blossom} <- trivial_blossoms, into: %{} do
        {blossom.base_vertex, id}
      end

    max_weight = graph.edges |> Enum.map(&elem(&1, 2)) |> Enum.max()

    %__MODULE__{
      graph: graph,
      vertex_mate: Map.new(0..(graph.num_vertex - 1), fn v -> {v, -1} end),
      blossoms: trivial_blossoms,
      vertex_top_blossom_id: vertex_to_blossom,
      vertex_dual_2x: Map.new(0..(graph.num_vertex - 1), fn v -> {v, max_weight} end),
      vertex_best_edge: Map.new(0..(graph.num_vertex - 1), fn v -> {v, -1} end),
      queue: :queue.new()
    }
  end

  # Helper to get a blossom by ID
  def get_blossom(context, id), do: Map.fetch!(context.blossoms, id)

  # Helper to get vertex's top-level blossom
  def get_vertex_blossom(context, vertex) do
    id = Map.fetch!(context.vertex_top_blossom_id, vertex)
    get_blossom(context, id)
  end

  # Helper to update a blossom
  def update_blossom(context, id, updates) do
    updated = Map.merge(get_blossom(context, id), updates)
    %{context | blossoms: Map.put(context.blossoms, id, updated)}
  end
end
```

### Comparing Blossoms

```elixir
# Instead of Python's: if bx is by
# Use:
def same_blossom?(context, vertex_x, vertex_y) do
  Map.fetch!(context.vertex_top_blossom_id, vertex_x) ==
    Map.fetch!(context.vertex_top_blossom_id, vertex_y)
end

# Or compare IDs directly:
bx_id = context.vertex_top_blossom_id[x]
by_id = context.vertex_top_blossom_id[y]
if bx_id == by_id do
  # Same blossom
end
```

### Getting Vertices from a Blossom

```elixir
def vertices(context, blossom_id) do
  blossom = Context.get_blossom(context, blossom_id)
  do_vertices(context, [blossom_id], [])
end

defp do_vertices(_context, [], acc), do: acc
defp do_vertices(context, [id | rest], acc) do
  case Context.get_blossom(context, id) do
    %Blossom.Trivial{base_vertex: v} ->
      do_vertices(context, rest, [v | acc])
    %Blossom.NonTrivial{subblossom_ids: sub_ids} ->
      do_vertices(context, sub_ids ++ rest, acc)
  end
end
```

### Why This Design?

1. **Immutable updates**: When we need to update a blossom (e.g., change its label), we update the map entry
2. **Identity comparison**: `make_ref()` gives us unique, comparable identifiers
3. **No circular references**: Blossoms store `parent_id` and `subblossom_ids`, not direct references
4. **Easy serialization**: The state is just maps and simple values
5. **Debugging**: References are readable in IEx for debugging

---

## Testing Strategy

### Unit Tests

Test each module in isolation with known inputs/outputs.

### Property-Based Tests

Using StreamData or PropCheck:

```elixir
property "matching is valid" do
  check all edges <- list_of(edge_generator()) do
    result = MaxWeightMatching.maximum_weight_matching(edges)

    # All result edges exist in input
    assert Enum.all?(result, fn {x, y} ->
      Enum.any?(edges, fn {a, b, _w} ->
        (a == x and b == y) or (a == y and b == x)
      end)
    end)

    # No vertex appears twice
    vertices = result |> Enum.flat_map(fn {x, y} -> [x, y] end)
    assert length(vertices) == length(Enum.uniq(vertices))
  end
end
```

### Known Test Cases

1. **Empty graph**: `[]` -> `[]`

2. **Single edge**: `[{0, 1, 10}]` -> `[{0, 1}]`

3. **Path graph**: `[{0,1,5}, {1,2,3}]` -> `[{0,1}]` (heavier edge wins)

4. **Triangle** (odd cycle, requires blossom):
   ```
   [{0,1,10}, {1,2,10}, {0,2,10}]
   ```
   Result should have exactly one edge.

5. **Square with diagonal**:
   ```
   [{0,1,1}, {1,2,1}, {2,3,1}, {0,3,1}, {0,2,5}]
   ```
   Should match `{0,2}` and `{1,3}` (if 1-3 edge added) or just `{0,2}`.

6. **Larger blossom test** from Python tests (if available)

### Comparison Tests

Generate random graphs and compare Elixir results against Python implementation:

```elixir
test "matches python implementation" do
  edges = generate_random_edges(20, 50)

  elixir_result = MaxWeightMatching.maximum_weight_matching(edges)
  python_result = call_python_implementation(edges)

  elixir_weight = total_weight(edges, elixir_result)
  python_weight = total_weight(edges, python_result)

  assert elixir_weight == python_weight
end
```

---

## Common Pitfalls and Debugging

### Critical Pitfalls to Avoid

1. **Marker field must be cleared after use**
   In `trace_alternating_paths`, the `marker` field is set to `true` on blossoms during traversal. These MUST be cleared before the function returns, even on early exit. Failure to do so will corrupt future path traces.

2. **Blossom identity changes during substage_scan**
   In `substage_scan`, the line `bx = self.vertex_top_blossom[x]` appears twice - once at the start and once inside the edge loop. This is because creating a blossom changes `vertex_top_blossom` for all vertices in the new blossom. Always re-fetch `bx` after any operation that might create a blossom.

3. **Edge direction matters in paths**
   Edges in alternating paths are ordered tuples `{x, y}`. When fusing paths in `trace_alternating_paths`, one path is reversed and edges are flipped. Get this wrong and augmentation will fail.

4. **Sub-blossom labels are NOT cleared when creating a blossom**
   When `make_blossom` is called, sub-blossoms keep their S/T labels. This is intentional - `merge_blossoms` uses these labels to determine which sub-blossoms to process. The labels are only cleared at the end of the stage by `reset_stage`.

5. **Delta3 division must match weight type**
   For integer weights, delta3 slack is always even (proof in the original paper). Use integer division `div(slack, 2)`. For floats, use regular division. Mixing these up will cause subtle bugs.

6. **Blossom expansion updates vertex_top_blossom**
   When expanding a blossom, you must update `vertex_top_blossom` for ALL vertices in the sub-blossoms, not just the direct children. Use the `vertices()` function to get all contained vertices.

7. **The base vertex of a blossom can change**
   During augmentation, `augment_blossom_rec` rotates the sub-blossom list and updates `base_vertex`. This is correct - after augmentation, a different vertex becomes the base.

8. **Unlabeled blossoms with zero dual must be expanded**
   In `assign_label_t`, before assigning label T, the code expands any zero-dual unlabeled blossoms. This is required for correctness - these blossoms "don't really exist" from the algorithm's perspective.

### Debugging Strategies

1. **Verify invariants after each operation**
   - All vertices in a top-level blossom should map to that blossom in `vertex_top_blossom`
   - `vertex_mate` should be symmetric: if `mate[x] == y` then `mate[y] == x`
   - Matched edges should have zero slack
   - All dual variables should be non-negative

2. **Print the alternating tree structure**
   Create a debug function that prints the tree structure: which blossoms are labeled S/T, what their tree_edges are, and how they connect.

3. **Trace path operations step-by-step**
   When `trace_alternating_paths` or `augment_matching` fails, log each step: which blossoms are visited, what edges are collected, where markers are placed.

4. **Use the verification function early**
   Don't wait until Phase 10 to implement `verify_optimum`. A partial version that just checks invariants can catch bugs early.

5. **Test with the Python implementation**
   Set up a test harness that runs both implementations on the same input and compares:
   - Final matching weight (should be equal)
   - Number of matched edges (should be equal)
   - Intermediate state after each stage (for deep debugging)

### Common Error Patterns

| Symptom | Likely Cause |
|---------|--------------|
| Infinite loop in stage | Delta calculation returning 0 repeatedly; check edge tracking |
| Wrong matching weight | Augmentation not updating `vertex_mate` correctly |
| Assertion failure in path trace | Markers not being cleared; blossom identity mismatch |
| Missing edges in result | Edge extraction using wrong condition |
| Stack overflow | Using recursion instead of iteration for blossom traversal |

---

## Critical Invariants

These invariants MUST be maintained throughout the algorithm:

### Graph Invariants
- Vertices are integers 0 to n-1 with no gaps
- Each edge appears exactly once in the edge list
- `adjacent_edges[v]` contains exactly the edge indices incident to v

### Matching Invariants
- `vertex_mate[x] == y` implies `vertex_mate[y] == x`
- `vertex_mate[x] == -1` means x is unmatched
- Matched edges exist in the graph

### Blossom Invariants
- Every vertex belongs to exactly one top-level blossom
- `vertex_top_blossom[x].parent == nil` for all x (top-level means no parent)
- Trivial blossoms have `base_vertex == x` for their single vertex x
- Non-trivial blossoms have odd number of sub-blossoms (>= 3)
- `base_vertex` of a blossom is contained within that blossom
- The base vertex of a blossom is the unique vertex not matched to another vertex in the same blossom

### Dual Variable Invariants
- All `vertex_dual_2x[x] >= 0`
- All `blossom.dual_var >= 0` for non-trivial blossoms
- For matched edge (x,y): `vertex_dual_2x[x] + vertex_dual_2x[y] == 2 * weight` (zero slack)
- Unmatched vertices at end of algorithm have `vertex_dual_2x[x] == 0`

### Alternating Tree Invariants (during a stage)
- S-blossoms and T-blossoms alternate along tree paths
- Every T-blossom has a matched base vertex
- The mate of a T-blossom's base is in an S-blossom
- Tree roots are S-blossoms containing unmatched vertices
- `tree_edge` points toward the root of the tree

---

## Worked Example: Triangle Graph

This example traces the algorithm through a simple triangle graph to illustrate key concepts.

### Input
```
Edges: [{0, 1, 10}, {1, 2, 10}, {0, 2, 10}]
Vertices: 0, 1, 2
```

### Initialization
```
vertex_mate = {0: -1, 1: -1, 2: -1}  # All unmatched
vertex_dual_2x = {0: 10, 1: 10, 2: 10}  # max_weight = 10
vertex_top_blossom = {0: B0, 1: B1, 2: B2}  # Trivial blossoms
```

### Stage 1

**Step 1: Label unmatched vertices as S**
- B0, B1, B2 all get label S (all are unmatched)
- Queue: [0, 1, 2]

**Step 2: Scan vertex 0**
- Edge (0,1): slack = 10 + 10 - 2*10 = 0 (tight!)
- Both endpoints are S-blossoms in different trees
- Call `add_s_to_s_edge(0, 1)`
- Trace paths: both reach roots immediately (no tree edges)
- Different trees → augmenting path found: [(0, 1)]

**Step 3: Augment**
- Set `vertex_mate[0] = 1`, `vertex_mate[1] = 0`
- Matching: {(0, 1)}

**Step 4: Reset stage**
- Clear all labels, queue

### Stage 2

**Step 1: Label unmatched vertices as S**
- Only vertex 2 is unmatched → B2 gets label S
- Vertices 0, 1 are matched → not labeled yet
- Queue: [2]

**Step 2: Scan vertex 2**
- Edge (0,2): slack = 10 + 10 - 2*10 = 0 (tight!)
- B2 is S, B0 is unlabeled → call `assign_label_t(2, 0)`
  - B0 gets label T, tree_edge = (2, 0)
  - B0's base (0) is matched to 1
  - Call `assign_label_s(1)` → B1 gets label S, tree_edge = (0, 1)
  - Queue: [2, 1]

- Edge (1,2): slack = 10 + 10 - 2*10 = 0 (tight!)
- B2 is S, B1 is S → call `add_s_to_s_edge(2, 1)`
- Trace from 2: tree_edge = nil (root), edges = [(2, 1)]
- Trace from 1: tree_edge = (0, 1), edges = [(1, 2), (0, 1)]
- They meet at... let's trace:
  - From 2: mark B2, follow tree_edge=nil, x=-1
  - From 1: mark B1, follow tree_edge=(0,1), x=0
  - Swap, now tracing from 0
  - From 0: B0 is marked? No. Mark B0, follow tree_edge=(2,0), x=2
  - Swap, now tracing from -1 (2's side done)
  - From 2: B2 is marked? Yes! Common ancestor found: B2

**This is a blossom!**

**Step 3: Create blossom**
- Path: [(2, 1), (1, 0), (0, 2)] - odd length cycle
- Sub-blossoms: [B2, B1, B0]
- Create NonTrivialBlossom with these sub-blossoms
- New blossom contains all 3 vertices
- Former T-blossom B0's vertices added to queue

**Step 4: Continue scan**
- Queue now has vertex 0
- But all vertices are now in the same blossom
- No external edges to scan
- Queue empties

**Step 5: Calculate delta**
- δ₁ = min dual of S-vertices = 10
- No unlabeled vertices → δ₂ = ∞
- No external S-blossoms → δ₃ = ∞
- No T-blossoms (the T was absorbed) → δ₄ = ∞
- Delta type 1, no improvement possible

**Step 6: End stage**
- No augmenting path found
- Matching stays: {(0, 1)}

### Final Result
```
Matching: [{0, 1}]
Total weight: 10
```

This is correct - in a triangle, we can only match one edge.

---

## Suggested Module Structure

```
lib/
├── max_weight_matching.ex              # Main entry point
│   └── maximum_weight_matching/1
│   └── adjust_weights_for_maximum_cardinality_matching/1
│
├── max_weight_matching/
│   ├── graph.ex                        # Graph struct and construction
│   │   └── Graph struct
│   │   └── new/1
│   │
│   ├── validation.ex                   # Input validation
│   │   └── check_input_types/1
│   │   └── check_input_graph/1
│   │   └── remove_negative_weight_edges/1
│   │
│   ├── blossom.ex                      # Blossom structs
│   │   └── TrivialBlossom struct
│   │   └── NonTrivialBlossom struct
│   │   └── vertices/1
│   │   └── is_trivial?/1
│   │
│   ├── context.ex                      # Algorithm state
│   │   └── Context struct
│   │   └── new/1
│   │
│   ├── slack.ex                        # Edge slack calculation
│   │   └── edge_slack_2x/2
│   │
│   ├── least_slack.ex                  # Edge tracking
│   │   └── reset/1
│   │   └── add_vertex_edge/4
│   │   └── get_best_vertex_edge/1
│   │   └── new_blossom/1
│   │   └── add_blossom_edge/4
│   │   └── get_best_blossom_edge/1
│   │   └── merge_blossoms/2
│   │
│   ├── label.ex                        # Labeling operations
│   │   └── assign_label_s/2
│   │   └── assign_label_t/3
│   │
│   ├── alternating_path.ex             # Path operations
│   │   └── trace_alternating_paths/3
│   │   └── find_path_through_blossom/2
│   │
│   ├── blossom_ops.ex                  # Blossom create/expand
│   │   └── make_blossom/2
│   │   └── expand_t_blossom/2
│   │   └── expand_unlabeled_blossom/2
│   │
│   ├── augment.ex                      # Matching augmentation
│   │   └── augment_matching/2
│   │   └── augment_blossom/3
│   │   └── augment_blossom_rec/4
│   │
│   ├── stage.ex                        # Main algorithm loop
│   │   └── run_stage/1
│   │   └── substage_scan/1
│   │   └── add_s_to_s_edge/3
│   │   └── substage_calc_dual_delta/1
│   │   └── substage_apply_delta_step/2
│   │   └── reset_stage/1
│   │
│   └── verification.ex                 # Optimality verification
│       └── verify_optimum/1
│       └── verify_blossom_edges/3

test/
├── max_weight_matching_test.exs        # Integration tests
├── max_weight_matching/
│   ├── graph_test.exs
│   ├── validation_test.exs
│   ├── blossom_test.exs
│   ├── context_test.exs
│   ├── slack_test.exs
│   ├── least_slack_test.exs
│   ├── label_test.exs
│   ├── alternating_path_test.exs
│   ├── blossom_ops_test.exs
│   ├── augment_test.exs
│   ├── stage_test.exs
│   └── verification_test.exs
```

---

## Detailed Test Cases

### Basic Cases

```elixir
# Empty graph
assert MaxWeightMatching.maximum_weight_matching([]) == []

# Single edge
assert MaxWeightMatching.maximum_weight_matching([{0, 1, 5}]) == [{0, 1}]

# Two disjoint edges
edges = [{0, 1, 5}, {2, 3, 10}]
result = MaxWeightMatching.maximum_weight_matching(edges)
assert length(result) == 2
assert total_weight(edges, result) == 15

# Path of 3 vertices - must choose one edge
edges = [{0, 1, 5}, {1, 2, 3}]
result = MaxWeightMatching.maximum_weight_matching(edges)
assert result == [{0, 1}]  # Heavier edge wins
```

### Bipartite Cases (No Blossoms Needed)

```elixir
# Square (4-cycle) - bipartite
edges = [{0, 1, 1}, {1, 2, 1}, {2, 3, 1}, {3, 0, 1}]
result = MaxWeightMatching.maximum_weight_matching(edges)
assert length(result) == 2
assert total_weight(edges, result) == 2

# Complete bipartite K_{2,2}
edges = [{0, 2, 1}, {0, 3, 2}, {1, 2, 3}, {1, 3, 4}]
result = MaxWeightMatching.maximum_weight_matching(edges)
# Optimal: {0,2} + {1,3} = 5, or {0,3} + {1,2} = 5
assert total_weight(edges, result) == 5

# Weighted path favoring skip
edges = [{0, 1, 1}, {1, 2, 10}, {2, 3, 1}]
result = MaxWeightMatching.maximum_weight_matching(edges)
# Should pick {1, 2} alone for weight 10, not {0,1} + {2,3} for weight 2
assert result == [{1, 2}]
```

### Blossom Cases

```elixir
# Triangle (simplest blossom)
edges = [{0, 1, 10}, {1, 2, 10}, {0, 2, 10}]
result = MaxWeightMatching.maximum_weight_matching(edges)
assert length(result) == 1
assert total_weight(edges, result) == 10

# Pentagon (5-cycle)
edges = [{0, 1, 1}, {1, 2, 1}, {2, 3, 1}, {3, 4, 1}, {4, 0, 1}]
result = MaxWeightMatching.maximum_weight_matching(edges)
assert length(result) == 2
assert total_weight(edges, result) == 2

# Triangle with tail
edges = [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 10}]
result = MaxWeightMatching.maximum_weight_matching(edges)
# Should match {0,1} and {2,3} for total weight 15
assert length(result) == 2
assert total_weight(edges, result) == 15

# Two triangles connected
edges = [
  {0, 1, 1}, {1, 2, 1}, {0, 2, 1},  # Triangle 1
  {3, 4, 1}, {4, 5, 1}, {3, 5, 1},  # Triangle 2
  {2, 3, 10}                         # Bridge
]
result = MaxWeightMatching.maximum_weight_matching(edges)
# Should match bridge + one edge from each triangle
assert total_weight(edges, result) == 12
```

### Edge Cases

```elixir
# Negative weights (should be ignored)
edges = [{0, 1, -5}, {1, 2, 10}]
result = MaxWeightMatching.maximum_weight_matching(edges)
assert result == [{1, 2}]

# All same weight
edges = [{0, 1, 5}, {1, 2, 5}, {2, 3, 5}, {3, 0, 5}]
result = MaxWeightMatching.maximum_weight_matching(edges)
assert length(result) == 2

# Large weight differences
edges = [{0, 1, 1000000}, {1, 2, 1}]
result = MaxWeightMatching.maximum_weight_matching(edges)
assert result == [{0, 1}]

# Float weights
edges = [{0, 1, 1.5}, {1, 2, 2.5}]
result = MaxWeightMatching.maximum_weight_matching(edges)
assert result == [{1, 2}]
```

### Helper Function for Tests

```elixir
defp total_weight(edges, matching) do
  matching
  |> Enum.map(fn {x, y} ->
    Enum.find_value(edges, 0, fn {a, b, w} ->
      if (a == x and b == y) or (a == y and b == x), do: w
    end)
  end)
  |> Enum.sum()
end
```

---

## Appendix: Algorithm Terminology

| Term | Definition |
|------|------------|
| **Matching** | Set of edges with no shared vertices |
| **Augmenting path** | Path from unmatched vertex to unmatched vertex, alternating matched/unmatched edges |
| **Blossom** | Odd-length alternating cycle, contracted to single "super-vertex" |
| **Trivial blossom** | A single vertex (not contracted) |
| **Base vertex** | The unique vertex in a blossom not matched to another vertex in the same blossom |
| **S-vertex/blossom** | "Outer" label, part of alternating tree, reachable from root by even-length path |
| **T-vertex/blossom** | "Inner" label, part of alternating tree, reachable from root by odd-length path |
| **Tight edge** | Edge with zero slack |
| **Dual variable** | Variable in the dual LP; used to track "potential" for vertices/blossoms |
| **Stage** | One iteration of the main loop, increases matching size by 1 (if possible) |
| **Substage** | One iteration within a stage, either extends tree or updates duals |
