# Blossom Algorithm: Theoretical Background

This document covers the theoretical foundation of Edmonds' Blossom Algorithm for Maximum Weighted Matching.

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

## Terminology

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

---

## References

- Edmonds, J. (1965). "Paths, Trees, and Flowers". Canadian Journal of Mathematics.
- Python reference implementation: `priv/python/mwmatching.py` by Joris van Rantwijk (2023)
