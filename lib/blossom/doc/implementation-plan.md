# Blossom Algorithm: Elixir Implementation Plan

## Implementation Status

| Phase | Status | Description | Files |
|-------|--------|-------------|-------|
| 1 | ✅ Complete | Graph & Validation | `max_weight_matching.ex`, `graph.ex`, `validation.ex` |
| 2 | ✅ Complete | Blossom Structs & Context | `blossom.ex`, `blossom/trivial.ex`, `blossom/non_trivial.ex`, `context.ex` |
| 3 | ✅ Complete | Slack & Edge Tracking | `slack.ex`, `least_slack.ex` |
| 4 | ✅ Complete | Labeling | `label.ex` |
| 5 | ✅ Complete | Delta Mechanics | `stage.ex` |
| 6 | ✅ Complete | Paths & Augmentation | `alternating_path.ex`, `augment.ex` |
| 7 | ✅ Complete | Stage Integration | `stage.ex` - **Bipartite graphs work** |
| 8 | Pending | Blossom Creation | `blossom_ops.ex` |
| 9 | Pending | Blossom Expansion | `blossom_ops.ex`, `augment.ex` - **All graphs work** |
| 10 | Pending | Verification | `verification.ex` |

All files are under `lib/blossom/max_weight_matching/`.

---

## Quick Start for Future Sessions

1. **Reference implementation**: `priv/python/mwmatching.py`
2. **Check status table above** to find the next phase
3. **Key Elixir patterns**: All state changes return new Context structs
4. **Blossom identity**: Use `make_ref()` for unique IDs; store blossoms in maps keyed by ID
5. **Testing milestones**: Bipartite graphs work after Phase 7, all graphs after Phase 9

---

## Elixir Gotchas

Lessons learned during implementation:

1. **Alias ordering matters**: When aliasing both `Blossom` and `Blossom.Trivial`, alias the child modules FIRST:
   ```elixir
   # Correct:
   alias Blossom.MaxWeightMatching.Blossom.Trivial
   alias Blossom.MaxWeightMatching.Blossom.NonTrivial
   alias Blossom.MaxWeightMatching.Blossom

   # Wrong (causes path duplication):
   alias Blossom.MaxWeightMatching.Blossom
   alias Blossom.MaxWeightMatching.Blossom.{Trivial, NonTrivial}
   ```

2. **Map access is O(1)**: Elixir maps use HAMT with effectively constant-time lookup

3. **Use `make_ref()` for identity**: Replaces Python's `is` operator for blossom comparison

4. **One module per file**: Avoids compilation order issues with struct aliases

5. **Use `Map.update!/3` for blossom updates**:
   ```elixir
   Map.update!(blossoms, id, &struct(&1, updates))
   ```

---

## Implementation Phases

### Phase 3: Slack & Edge Tracking

**Goal:** Implement edge slack calculation and least-slack tracking.

**Functions:**
- `Slack.edge_slack_2x/2` - Calculate 2x slack of an edge
- `LeastSlack.reset/1` - Reset all edge tracking
- `LeastSlack.add_vertex_edge/4` - Track S-to-vertex edge
- `LeastSlack.get_best_vertex_edge/1` - Find best S-to-unlabeled edge
- `LeastSlack.new_blossom/2` - Initialize tracking for new S-blossom
- `LeastSlack.add_blossom_edge/4` - Track S-to-S edge
- `LeastSlack.get_best_blossom_edge/1` - Find best S-to-S edge

**Python references:**
- `edge_slack_2x`: lines 574-587
- `lset_reset`: lines 620-635
- `lset_add_vertex_edge`: lines 637-649
- `lset_get_best_vertex_edge`: lines 651-674
- `lset_new_blossom`: lines 676-682
- `lset_add_blossom_edge`: lines 684-711
- `lset_get_best_blossom_edge`: lines 800-823

**Note:** Defer `merge_blossoms/2` to Phase 8.

---

### Phase 4: Labeling

**Goal:** Implement S and T label assignment.

**Functions:**
- `Label.assign_label_s/2` - Label blossom as S, add vertices to queue
- `Label.assign_label_t/3` - Label blossom as T, then call assign_label_s on mate

**Note:** Initial version skips zero-dual blossom expansion (added in Phase 9).

**Python references:**
- `assign_label_s`: lines 1240-1281
- `assign_label_t`: lines 1283-1311

---

### Phase 5: Delta Mechanics

**Goal:** Implement dual variable updates.

**Functions:**
- `Stage.substage_calc_dual_delta/1` - Calculate min delta from 4 types
- `Stage.substage_apply_delta_step/2` - Apply delta to vertex and blossom duals
- `Stage.reset_stage/1` - Clear labels, queue, and edge tracking

**Python references:**
- `substage_calc_dual_delta`: lines 1420-1484
- `substage_apply_delta_step`: lines 1486-1510
- `reset_stage`: lines 829-845

---

### Phase 6: Paths & Simple Augmentation

**Goal:** Implement path tracing and augmentation (without blossom support).

**Functions:**
- `AlternatingPath.trace_alternating_paths/3` - Trace from x,y to find path
- `Augment.augment_matching/2` - Augment along path (simplified)
- `Stage.add_s_to_s_edge/3` - Handle S-to-S edge (simplified: only augmenting path)

**Python references:**
- `trace_alternating_paths`: lines 847-925
- `augment_matching`: lines 1196-1234
- `add_s_to_s_edge`: lines 1313-1340

---

### Phase 7: Stage Integration

**Goal:** Complete the main loop for bipartite graphs.

**Functions:**
- `Stage.substage_scan/1` - Scan S-vertices
- `Stage.run_stage/1` - Execute one complete stage
- `MaxWeightMatching.maximum_weight_matching/1` - Update main entry point

**Milestone:** Bipartite graphs (paths, even cycles, complete bipartite) work correctly.

**Python references:**
- `substage_scan`: lines 1342-1414
- `run_stage`: lines 1516-1602
- `maximum_weight_matching`: lines 37-115

---

### Phase 8: Blossom Creation

**Goal:** Add ability to create and navigate blossoms.

**Functions:**
- `BlossomOps.make_blossom/2` - Create blossom from alternating cycle
- `LeastSlack.merge_blossoms/2` - Merge edge tracking for new blossom
- `BlossomOps.find_path_through_blossom/2` - Path from sub-blossom to base
- Update `add_s_to_s_edge/3` to call `make_blossom` when cycle detected

**Python references:**
- `make_blossom`: lines 931-981
- `lset_merge_blossoms`: lines 713-798
- `find_path_through_blossom`: lines 983-1008

---

### Phase 9: Blossom Expansion & Full Augmentation

**Goal:** Complete blossom support.

**Functions:**
- `BlossomOps.expand_unlabeled_blossom/2` - Expand unlabeled blossom
- `BlossomOps.expand_t_blossom/2` - Expand T-blossom
- `Augment.augment_blossom/3` - Augment through blossom
- `Augment.augment_blossom_rec/4` - Helper for augment_blossom
- Update `assign_label_t/3` to expand zero-dual blossoms
- Update `augment_matching/2` to call `augment_blossom`

**Milestone:** All graphs work correctly.

**Python references:**
- `expand_unlabeled_blossom`: lines 1072-1093
- `expand_t_blossom`: lines 1010-1070
- `augment_blossom`: lines 1158-1194
- `augment_blossom_rec`: lines 1099-1156

---

### Phase 10: Verification

**Goal:** Add verification and cardinality adjustment.

**Functions:**
- `Verification.verify_optimum/1` - Verify matching is optimal
- `Verification.verify_blossom_edges/3` - Helper for verify_optimum
- `MaxWeightMatching.adjust_weights_for_maximum_cardinality_matching/1`

**Python references:**
- `_verify_optimum`: lines 1731-1810
- `_verify_blossom_edges`: lines 1605-1728
- `adjust_weights_for_maximum_cardinality_matching`: lines 118-195

---

## Critical Invariants

These MUST be maintained throughout the algorithm:

### Matching Invariants
- `vertex_mate[x] == y` implies `vertex_mate[y] == x`
- `vertex_mate[x] == -1` means x is unmatched

### Blossom Invariants
- Every vertex belongs to exactly one top-level blossom
- `vertex_top_blossom_id[x]` points to a blossom with `parent_id == nil`
- Trivial blossoms have `base_vertex == x` for their single vertex x
- Non-trivial blossoms have odd number of sub-blossoms (>= 3)
- The base vertex is the unique vertex not matched within the blossom

### Dual Variable Invariants
- All `vertex_dual_2x[x] >= 0`
- All `blossom.dual_var >= 0` for non-trivial blossoms
- For matched edge (x,y): slack == 0

### Alternating Tree Invariants (during a stage)
- S-blossoms and T-blossoms alternate along tree paths
- Every T-blossom has a matched base vertex
- Tree roots are S-blossoms containing unmatched vertices
- `tree_edge` points toward the root of the tree

---

## Common Pitfalls

1. **Marker field must be cleared after use** - In `trace_alternating_paths`, markers MUST be cleared before returning

2. **Re-fetch blossom after operations** - In `substage_scan`, re-fetch `bx` after any operation that might create a blossom

3. **Edge direction matters in paths** - When fusing paths, one is reversed and edges are flipped

4. **Sub-blossom labels are NOT cleared when creating a blossom** - They're used by `merge_blossoms`

5. **Delta3 division must match weight type** - Use `div(slack, 2)` for integers, `/` for floats

6. **Blossom expansion updates all vertices** - Use `vertices()` to get all contained vertices

7. **Base vertex can change during augmentation** - `augment_blossom_rec` rotates sub-blossoms

8. **Zero-dual blossoms must be expanded before labeling T** - Required for correctness

### Error Patterns

| Symptom | Likely Cause |
|---------|--------------|
| Infinite loop in stage | Delta returning 0 repeatedly |
| Wrong matching weight | Augmentation not updating `vertex_mate` correctly |
| Path trace assertion failure | Markers not cleared; blossom identity mismatch |
| Missing edges in result | Edge extraction using wrong condition |

---

## Test Cases

### Basic Cases
```elixir
# Empty graph
assert maximum_weight_matching([]) == []

# Single edge
assert maximum_weight_matching([{0, 1, 5}]) == [{0, 1}]

# Path - heavier edge wins
assert maximum_weight_matching([{0, 1, 5}, {1, 2, 3}]) == [{0, 1}]
```

### Bipartite Cases (Phase 7)
```elixir
# Square (4-cycle)
edges = [{0, 1, 1}, {1, 2, 1}, {2, 3, 1}, {3, 0, 1}]
result = maximum_weight_matching(edges)
assert length(result) == 2
```

### Blossom Cases (Phase 9)
```elixir
# Triangle
edges = [{0, 1, 10}, {1, 2, 10}, {0, 2, 10}]
result = maximum_weight_matching(edges)
assert length(result) == 1

# Pentagon (5-cycle)
edges = [{0, 1, 1}, {1, 2, 1}, {2, 3, 1}, {3, 4, 1}, {4, 0, 1}]
result = maximum_weight_matching(edges)
assert length(result) == 2

# Triangle with tail - should match {0,1} and {2,3} for weight 15
edges = [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 10}]
assert total_weight(edges, maximum_weight_matching(edges)) == 15
```

### Helper
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

## Related Documentation

- [Background & Theory](background.md) - Algorithm overview and mathematical foundation
- [Worked Example](worked-example.md) - Step-by-step trace through a triangle graph
- Python reference: `priv/python/mwmatching.py`
