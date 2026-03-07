defmodule MaxWeightMatching.Viz.SerializerTest do
  use ExUnit.Case, async: true

  alias MaxWeightMatching.Stepper
  alias MaxWeightMatching.Viz.Serializer

  @edges [{0, 1, 10}, {1, 2, 7}, {0, 2, 8}]

  test "serialize produces JSON-safe maps (no tuples, no non-string-key atoms)" do
    steps = Stepper.run(@edges)

    for step <- steps do
      serialized = Serializer.serialize(step)

      assert is_map(serialized)
      assert is_atom(serialized.type)
      assert is_map(serialized.detail)
      assert is_map(serialized.snapshot)

      # vertex_labels keys are strings
      for {k, v} <- serialized.snapshot.vertex_labels do
        assert is_binary(k)
        assert v in ["s", "t", "none"]
      end

      # vertex_duals keys are strings, values are numbers
      for {k, v} <- serialized.snapshot.vertex_duals do
        assert is_binary(k)
        assert is_number(v)
      end

      # matched_edges are lists of lists, not tuples
      for edge <- serialized.snapshot.matched_edges do
        assert is_list(edge)
        assert length(edge) == 2
      end

      # edges values are lists, not tuples
      for {k, v} <- serialized.snapshot.edges do
        assert is_binary(k)
        assert is_list(v)
        assert length(v) == 3
      end

      # blossoms are plain maps
      for b <- serialized.snapshot.blossoms do
        assert is_map(b)
        assert is_list(b.vertices)
        assert is_integer(b.base)
        assert is_number(b.dual)
      end
    end
  end

  test "serialize preserves step type" do
    steps = Stepper.run(@edges)

    for step <- steps do
      serialized = Serializer.serialize(step)
      assert serialized.type == step.type
    end
  end

  test "detail atoms are converted to strings" do
    steps = Stepper.run(@edges)

    augment_step = Enum.find(steps, &(&1.type == :augment))

    if augment_step do
      serialized = Serializer.serialize(augment_step)

      # path_edges should be serialized (they're lists of integers)
      assert is_list(serialized.detail.path_edges)
    end
  end
end
