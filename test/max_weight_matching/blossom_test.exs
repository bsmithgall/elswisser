defmodule MaxWeightMatching.BlossomTest do
  use ExUnit.Case, async: true

  alias MaxWeightMatching.Blossom.Trivial
  alias MaxWeightMatching.Blossom.NonTrivial
  alias MaxWeightMatching.Blossom

  describe "Trivial.new/1" do
    test "creates trivial blossom with correct base_vertex" do
      blossom = Trivial.new(0)
      assert blossom.base_vertex == 0
    end

    test "creates trivial blossom with unique reference ID" do
      blossom = Trivial.new(5)
      assert is_reference(blossom.id)
    end

    test "each blossom gets a unique ID" do
      blossom1 = Trivial.new(0)
      blossom2 = Trivial.new(1)
      blossom3 = Trivial.new(0)

      assert blossom1.id != blossom2.id
      assert blossom1.id != blossom3.id
      assert blossom2.id != blossom3.id
    end

    test "initializes with correct default values" do
      blossom = Trivial.new(3)

      assert blossom.parent_id == nil
      assert blossom.label == :none
      assert blossom.tree_edge == nil
      assert blossom.best_edge == -1
      assert blossom.marker == false
    end

    test "works with vertex 0" do
      blossom = Trivial.new(0)
      assert blossom.base_vertex == 0
    end

    test "works with large vertex indices" do
      blossom = Trivial.new(999)
      assert blossom.base_vertex == 999
    end
  end

  describe "NonTrivial.new/3" do
    test "creates non-trivial blossom with 3 sub-blossoms" do
      b0 = Trivial.new(0)
      b1 = Trivial.new(1)
      b2 = Trivial.new(2)

      subblossom_ids = [b0.id, b1.id, b2.id]
      edges = [{0, 1}, {1, 2}, {2, 0}]

      blossom = NonTrivial.new(subblossom_ids, edges, 0)

      assert blossom.subblossom_ids == subblossom_ids
      assert blossom.edges == edges
      assert blossom.base_vertex == 0
    end

    test "creates non-trivial blossom with unique reference ID" do
      b0 = Trivial.new(0)
      b1 = Trivial.new(1)
      b2 = Trivial.new(2)

      blossom = NonTrivial.new([b0.id, b1.id, b2.id], [{0, 1}, {1, 2}, {2, 0}], 0)

      assert is_reference(blossom.id)
    end

    test "initializes with correct default values" do
      b0 = Trivial.new(0)
      b1 = Trivial.new(1)
      b2 = Trivial.new(2)

      blossom = NonTrivial.new([b0.id, b1.id, b2.id], [{0, 1}, {1, 2}, {2, 0}], 0)

      assert blossom.parent_id == nil
      assert blossom.label == :none
      assert blossom.tree_edge == nil
      assert blossom.best_edge == -1
      assert blossom.marker == false
      assert blossom.dual_var == 0
      assert blossom.best_edge_set == nil
    end

    test "works with 5 sub-blossoms (odd number)" do
      blossoms = for v <- 0..4, do: Trivial.new(v)
      ids = Enum.map(blossoms, & &1.id)
      edges = [{0, 1}, {1, 2}, {2, 3}, {3, 4}, {4, 0}]

      blossom = NonTrivial.new(ids, edges, 0)

      assert length(blossom.subblossom_ids) == 5
    end

    test "raises if less than 3 sub-blossoms" do
      b0 = Trivial.new(0)
      b1 = Trivial.new(1)

      assert_raise ArgumentError, ~r/at least 3 sub-blossoms/, fn ->
        NonTrivial.new([b0.id, b1.id], [{0, 1}, {1, 0}], 0)
      end
    end

    test "raises if even number of sub-blossoms" do
      blossoms = for v <- 0..3, do: Trivial.new(v)
      ids = Enum.map(blossoms, & &1.id)
      edges = [{0, 1}, {1, 2}, {2, 3}, {3, 0}]

      assert_raise ArgumentError, ~r/odd number/, fn ->
        NonTrivial.new(ids, edges, 0)
      end
    end

    test "raises if edges count doesn't match sub-blossoms count" do
      b0 = Trivial.new(0)
      b1 = Trivial.new(1)
      b2 = Trivial.new(2)

      assert_raise ArgumentError, ~r/edges length/, fn ->
        NonTrivial.new([b0.id, b1.id, b2.id], [{0, 1}, {1, 2}], 0)
      end
    end
  end

  describe "vertices/2 with trivial blossom" do
    test "returns single-element list with base_vertex" do
      blossom = Trivial.new(5)
      blossoms = %{blossom.id => blossom}

      assert Blossom.vertices(blossom.id, blossoms) == [5]
    end

    test "works with vertex 0" do
      blossom = Trivial.new(0)
      blossoms = %{blossom.id => blossom}

      assert Blossom.vertices(blossom.id, blossoms) == [0]
    end
  end

  describe "vertices/2 with non-trivial blossom" do
    test "returns all vertices from 3 trivial sub-blossoms" do
      b0 = Trivial.new(0)
      b1 = Trivial.new(1)
      b2 = Trivial.new(2)

      non_trivial =
        NonTrivial.new([b0.id, b1.id, b2.id], [{0, 1}, {1, 2}, {2, 0}], 0)

      blossoms = %{
        b0.id => b0,
        b1.id => b1,
        b2.id => b2,
        non_trivial.id => non_trivial
      }

      vertices = Blossom.vertices(non_trivial.id, blossoms)

      # Order may vary, so use MapSet for comparison
      assert MapSet.new(vertices) == MapSet.new([0, 1, 2])
      assert length(vertices) == 3
    end

    test "returns all vertices from nested non-trivial blossoms" do
      # Create a blossom containing another blossom
      # Inner blossom: vertices 0, 1, 2
      b0 = Trivial.new(0)
      b1 = Trivial.new(1)
      b2 = Trivial.new(2)

      inner = NonTrivial.new([b0.id, b1.id, b2.id], [{0, 1}, {1, 2}, {2, 0}], 0)

      # Outer blossom: inner blossom + vertices 3, 4
      b3 = Trivial.new(3)
      b4 = Trivial.new(4)

      outer = NonTrivial.new([inner.id, b3.id, b4.id], [{2, 3}, {3, 4}, {4, 0}], 0)

      blossoms = %{
        b0.id => b0,
        b1.id => b1,
        b2.id => b2,
        b3.id => b3,
        b4.id => b4,
        inner.id => inner,
        outer.id => outer
      }

      vertices = Blossom.vertices(outer.id, blossoms)

      # Should get all 5 vertices
      assert MapSet.new(vertices) == MapSet.new([0, 1, 2, 3, 4])
      assert length(vertices) == 5
    end

    test "returns all vertices from deeply nested blossoms" do
      # Three levels of nesting
      # Level 1: trivial blossoms 0, 1, 2
      b0 = Trivial.new(0)
      b1 = Trivial.new(1)
      b2 = Trivial.new(2)

      level1 = NonTrivial.new([b0.id, b1.id, b2.id], [{0, 1}, {1, 2}, {2, 0}], 0)

      # Level 2: level1 + trivial blossoms 3, 4
      b3 = Trivial.new(3)
      b4 = Trivial.new(4)

      level2 = NonTrivial.new([level1.id, b3.id, b4.id], [{2, 3}, {3, 4}, {4, 0}], 0)

      # Level 3: level2 + trivial blossoms 5, 6
      b5 = Trivial.new(5)
      b6 = Trivial.new(6)

      level3 = NonTrivial.new([level2.id, b5.id, b6.id], [{4, 5}, {5, 6}, {6, 0}], 0)

      blossoms = %{
        b0.id => b0,
        b1.id => b1,
        b2.id => b2,
        b3.id => b3,
        b4.id => b4,
        b5.id => b5,
        b6.id => b6,
        level1.id => level1,
        level2.id => level2,
        level3.id => level3
      }

      vertices = Blossom.vertices(level3.id, blossoms)

      # Should get all 7 vertices
      assert MapSet.new(vertices) == MapSet.new([0, 1, 2, 3, 4, 5, 6])
      assert length(vertices) == 7
    end
  end
end
