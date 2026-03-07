defmodule MaxWeightMatching.StepperTest do
  use ExUnit.Case, async: true

  alias MaxWeightMatching.Stepper

  # --- Helpers ---

  defp step_types(steps), do: Enum.map(steps, & &1.type)

  defp final_matching(steps) do
    List.last(steps).snapshot.matched_edges |> Enum.sort()
  end

  defp expected_matching(edges) do
    MaxWeightMatching.maximum_weight_matching(edges)
    |> Enum.map(fn {x, y} -> if x < y, do: {x, y}, else: {y, x} end)
    |> Enum.sort()
  end

  defp assert_structural_invariants(steps) do
    types = step_types(steps)

    # First step is :init
    assert hd(types) == :init

    # Last step is :stage_end with augmented: false
    last = List.last(steps)
    assert last.type == :stage_end
    assert last.detail.augmented == false

    # Every :stage_start has a corresponding :stage_end
    starts = Enum.count(types, &(&1 == :stage_start))
    ends = Enum.count(types, &(&1 == :stage_end))
    assert starts == ends

    # Stage numbers are sequential
    stage_nums =
      steps
      |> Enum.filter(&(&1.type in [:stage_start, :stage_end]))
      |> Enum.map(& &1.detail.stage)
      |> Enum.uniq()
      |> Enum.sort()

    assert stage_nums == Enum.to_list(1..length(stage_nums))
  end

  # --- Tests ---

  describe "structural invariants" do
    test "single edge" do
      steps = Stepper.run([{0, 1, 10}])
      assert_structural_invariants(steps)
    end

    test "path of 3" do
      steps = Stepper.run([{0, 1, 5}, {1, 2, 3}])
      assert_structural_invariants(steps)
    end

    test "triangle" do
      steps = Stepper.run([{0, 1, 10}, {1, 2, 7}, {0, 2, 8}])
      assert_structural_invariants(steps)
    end

    test "4-vertex path" do
      steps = Stepper.run([{0, 1, 10}, {1, 2, 9}, {2, 3, 10}])
      assert_structural_invariants(steps)
    end

    test "5-vertex graph with blossom" do
      steps = Stepper.run([{0, 1, 7}, {0, 2, 8}, {1, 2, 9}, {2, 3, 5}, {3, 4, 6}])
      assert_structural_invariants(steps)
    end
  end

  describe "final matching correctness" do
    test "single edge" do
      edges = [{0, 1, 10}]
      steps = Stepper.run(edges)
      assert final_matching(steps) == expected_matching(edges)
    end

    test "path of 3 — heavier edge wins" do
      edges = [{0, 1, 5}, {1, 2, 3}]
      steps = Stepper.run(edges)
      assert final_matching(steps) == expected_matching(edges)
    end

    test "triangle" do
      edges = [{0, 1, 10}, {1, 2, 7}, {0, 2, 8}]
      steps = Stepper.run(edges)
      assert final_matching(steps) == expected_matching(edges)
    end

    test "4-vertex path — two edges matched" do
      edges = [{0, 1, 10}, {1, 2, 9}, {2, 3, 10}]
      steps = Stepper.run(edges)
      assert final_matching(steps) == expected_matching(edges)
    end

    test "5-vertex graph" do
      edges = [{0, 1, 7}, {0, 2, 8}, {1, 2, 9}, {2, 3, 5}, {3, 4, 6}]
      steps = Stepper.run(edges)
      assert final_matching(steps) == expected_matching(edges)
    end

    test "complete graph K4" do
      edges = [{0, 1, 3}, {0, 2, 4}, {0, 3, 2}, {1, 2, 5}, {1, 3, 6}, {2, 3, 1}]
      steps = Stepper.run(edges)
      assert final_matching(steps) == expected_matching(edges)
    end

    test "disconnected components" do
      edges = [{0, 1, 10}, {2, 3, 8}]
      steps = Stepper.run(edges)
      assert final_matching(steps) == expected_matching(edges)
    end
  end

  describe "step types" do
    test "single edge produces expected sequence" do
      steps = Stepper.run([{0, 1, 10}])
      types = step_types(steps)

      assert types == [
               :init,
               :stage_start,
               :scan_step,
               :augment,
               :stage_end,
               :stage_start,
               :stage_end
             ]
    end

    test "triangle produces delta_step events" do
      steps = Stepper.run([{0, 1, 10}, {1, 2, 7}, {0, 2, 8}])
      types = step_types(steps)

      assert :delta_step in types
    end

    test "graph with blossom shows blossom in snapshot" do
      steps = Stepper.run([{0, 1, 10}, {1, 2, 7}, {0, 2, 8}])

      blossom_steps =
        Enum.filter(steps, fn s -> length(s.snapshot.blossoms) > 0 end)

      assert length(blossom_steps) > 0

      blossom = hd(hd(blossom_steps).snapshot.blossoms)
      assert Enum.sort(blossom.vertices) == [0, 1, 2]
    end
  end

  describe "run/3 callback" do
    test "counts events by type" do
      edges = [{0, 1, 10}, {1, 2, 7}, {0, 2, 8}]

      {_matching, counts} =
        Stepper.run(
          edges,
          fn step, acc ->
            Map.update(acc, step.type, 1, &(&1 + 1))
          end,
          %{}
        )

      assert counts[:init] == 1
      assert counts[:stage_start] >= 1
      assert counts[:stage_end] >= 1
    end

    test "returns correct matching" do
      edges = [{0, 1, 10}]
      {matching, _acc} = Stepper.run(edges, fn _step, acc -> acc end, nil)
      assert matching == [{0, 1}]
    end
  end

  describe "snapshot contents" do
    test "init snapshot has all vertices unlabeled and unmatched" do
      steps = Stepper.run([{0, 1, 10}, {1, 2, 5}])
      init = hd(steps)

      assert init.snapshot.vertex_labels == %{0 => :none, 1 => :none, 2 => :none}
      assert init.snapshot.matched_edges == []
      assert init.snapshot.blossoms == []
      assert map_size(init.snapshot.edges) == 2
    end

    test "stage_start snapshot shows S-labeled vertices" do
      steps = Stepper.run([{0, 1, 10}])
      stage_start = Enum.find(steps, &(&1.type == :stage_start and &1.detail.stage == 1))

      assert stage_start.snapshot.vertex_labels == %{0 => :s, 1 => :s}
    end

    test "vertex duals start at max_weight (2× scale)" do
      steps = Stepper.run([{0, 1, 10}, {1, 2, 6}])
      init = hd(steps)

      # max weight is 10, stored internally as 2× → dual_2x = 10
      assert init.snapshot.vertex_duals == %{0 => 10, 1 => 10, 2 => 10}
    end

    test "augment step shows new matched edges" do
      steps = Stepper.run([{0, 1, 10}])
      augment = Enum.find(steps, &(&1.type == :augment))

      assert augment.snapshot.matched_edges == [{0, 1}]
    end
  end
end
