defmodule MaxWeightMatching.ValidationTest do
  use ExUnit.Case, async: true

  alias MaxWeightMatching.Validation

  describe "check_input_types/1" do
    test "accepts empty list" do
      assert Validation.check_input_types([]) == :ok
    end

    test "accepts single valid edge" do
      assert Validation.check_input_types([{0, 1, 10}]) == :ok
    end

    test "accepts multiple valid edges" do
      edges = [{0, 1, 10}, {1, 2, 5}, {2, 3, 8}]
      assert Validation.check_input_types(edges) == :ok
    end

    test "accepts integer weights" do
      assert Validation.check_input_types([{0, 1, 100}]) == :ok
    end

    test "accepts float weights" do
      assert Validation.check_input_types([{0, 1, 3.14}]) == :ok
    end

    test "accepts zero weight" do
      assert Validation.check_input_types([{0, 1, 0}]) == :ok
    end

    test "accepts negative weights (validation only checks types)" do
      assert Validation.check_input_types([{0, 1, -5}]) == :ok
    end

    test "rejects non-list input" do
      assert {:error, "edges must be a list"} = Validation.check_input_types("not a list")
      assert {:error, "edges must be a list"} = Validation.check_input_types({0, 1, 10})
      assert {:error, "edges must be a list"} = Validation.check_input_types(nil)
    end

    test "rejects edge that is not a tuple" do
      assert {:error, "each edge must be specified as a 3-tuple"} =
               Validation.check_input_types([[0, 1, 10]])
    end

    test "rejects edge that is not a 3-tuple" do
      assert {:error, "each edge must be specified as a 3-tuple"} =
               Validation.check_input_types([{0, 1}])

      assert {:error, "each edge must be specified as a 3-tuple"} =
               Validation.check_input_types([{0, 1, 10, :extra}])
    end

    test "rejects non-integer endpoints" do
      assert {:error, "edge endpoints must be integers"} =
               Validation.check_input_types([{"a", 1, 10}])

      assert {:error, "edge endpoints must be integers"} =
               Validation.check_input_types([{0, 1.5, 10}])
    end

    test "rejects negative vertex indices" do
      assert {:error, "edge endpoints must be non-negative integers"} =
               Validation.check_input_types([{-1, 0, 10}])

      assert {:error, "edge endpoints must be non-negative integers"} =
               Validation.check_input_types([{0, -2, 10}])
    end

    test "rejects non-numeric weight" do
      assert {:error, "edge weights must be integers or floating point numbers"} =
               Validation.check_input_types([{0, 1, "heavy"}])

      assert {:error, "edge weights must be integers or floating point numbers"} =
               Validation.check_input_types([{0, 1, :ten}])
    end

    test "rejects excessively large float weight" do
      # Weights larger than Float.max_finite() / 4 are rejected
      large_weight = Float.max_finite() / 2
      assert {:error, _} = Validation.check_input_types([{0, 1, large_weight}])
    end
  end

  describe "check_input_graph/1" do
    test "accepts valid graph" do
      assert Validation.check_input_graph([{0, 1, 10}, {1, 2, 5}]) == :ok
    end

    test "accepts empty graph" do
      assert Validation.check_input_graph([]) == :ok
    end

    test "rejects self-edges" do
      assert {:error, "self-edges are not supported"} =
               Validation.check_input_graph([{0, 0, 10}])

      assert {:error, "self-edges are not supported"} =
               Validation.check_input_graph([{0, 1, 5}, {2, 2, 10}])
    end

    test "rejects duplicate edges" do
      assert {:error, "duplicate edge {0, 1}"} =
               Validation.check_input_graph([{0, 1, 10}, {0, 1, 5}])
    end

    test "rejects duplicate edges in reversed order" do
      assert {:error, "duplicate edge {0, 1}"} =
               Validation.check_input_graph([{0, 1, 10}, {1, 0, 5}])
    end

    test "allows same weight for different edges" do
      assert Validation.check_input_graph([{0, 1, 10}, {1, 2, 10}]) == :ok
    end
  end

  describe "remove_negative_weight_edges/1" do
    test "returns same list when no negative weights" do
      edges = [{0, 1, 10}, {1, 2, 5}]
      assert Validation.remove_negative_weight_edges(edges) == edges
    end

    test "removes edges with negative weights" do
      edges = [{0, 1, 10}, {1, 2, -5}, {2, 3, 8}]
      assert Validation.remove_negative_weight_edges(edges) == [{0, 1, 10}, {2, 3, 8}]
    end

    test "keeps edges with zero weight" do
      edges = [{0, 1, 0}, {1, 2, 5}]
      assert Validation.remove_negative_weight_edges(edges) == edges
    end

    test "returns empty list when all weights are negative" do
      edges = [{0, 1, -10}, {1, 2, -5}]
      assert Validation.remove_negative_weight_edges(edges) == []
    end

    test "handles empty list" do
      assert Validation.remove_negative_weight_edges([]) == []
    end
  end
end
