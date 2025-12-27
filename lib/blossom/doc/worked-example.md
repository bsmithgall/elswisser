# Worked Example: Triangle Graph

This example traces the Blossom Algorithm through a simple triangle graph to illustrate key concepts including blossom creation.

## Input

```
Edges: [{0, 1, 10}, {1, 2, 10}, {0, 2, 10}]
Vertices: 0, 1, 2
```

## Initialization

```
vertex_mate = {0: -1, 1: -1, 2: -1}  # All unmatched
vertex_dual_2x = {0: 10, 1: 10, 2: 10}  # max_weight = 10
vertex_top_blossom = {0: B0, 1: B1, 2: B2}  # Trivial blossoms
```

---

## Stage 1

### Step 1: Label unmatched vertices as S
- B0, B1, B2 all get label S (all are unmatched)
- Queue: [0, 1, 2]

### Step 2: Scan vertex 0
- Edge (0,1): slack = 10 + 10 - 2*10 = 0 (tight!)
- Both endpoints are S-blossoms in different trees
- Call `add_s_to_s_edge(0, 1)`
- Trace paths: both reach roots immediately (no tree edges)
- Different trees → augmenting path found: [(0, 1)]

### Step 3: Augment
- Set `vertex_mate[0] = 1`, `vertex_mate[1] = 0`
- Matching: {(0, 1)}

### Step 4: Reset stage
- Clear all labels, queue

---

## Stage 2

### Step 1: Label unmatched vertices as S
- Only vertex 2 is unmatched → B2 gets label S
- Vertices 0, 1 are matched → not labeled yet
- Queue: [2]

### Step 2: Scan vertex 2
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
- Path tracing:
  - From 2: mark B2, follow tree_edge=nil, x=-1
  - From 1: mark B1, follow tree_edge=(0,1), x=0
  - Swap, now tracing from 0
  - From 0: B0 is marked? No. Mark B0, follow tree_edge=(2,0), x=2
  - Swap, now tracing from -1 (2's side done)
  - From 2: B2 is marked? Yes! Common ancestor found: B2

**This is a blossom!**

### Step 3: Create blossom
- Path: [(2, 1), (1, 0), (0, 2)] - odd length cycle
- Sub-blossoms: [B2, B1, B0]
- Create NonTrivialBlossom with these sub-blossoms
- New blossom contains all 3 vertices
- Former T-blossom B0's vertices added to queue

### Step 4: Continue scan
- Queue now has vertex 0
- But all vertices are now in the same blossom
- No external edges to scan
- Queue empties

### Step 5: Calculate delta
- δ₁ = min dual of S-vertices = 10
- No unlabeled vertices → δ₂ = ∞
- No external S-blossoms → δ₃ = ∞
- No T-blossoms (the T was absorbed) → δ₄ = ∞
- Delta type 1, no improvement possible

### Step 6: End stage
- No augmenting path found
- Matching stays: {(0, 1)}

---

## Final Result

```
Matching: [{0, 1}]
Total weight: 10
```

This is correct - in a triangle, we can only match one edge.

---

## Key Insights from This Example

1. **Blossom detection**: When two S-vertices in the same tree have a tight edge, they form a blossom
2. **Path tracing**: Uses markers to find common ancestors
3. **Blossom contraction**: All vertices in the blossom are now treated as one
4. **Delta type 1**: When all vertices are in one blossom with no external edges, no improvement is possible
