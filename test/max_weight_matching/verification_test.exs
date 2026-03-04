defmodule MaxWeightMatching.VerificationTest do
  @moduledoc """
  Tests for the optimality verification functions.
  """

  use ExUnit.Case, async: true

  alias MaxWeightMatching.{Context, Graph, Stage}
  alias TestSupport.{GraphGenerator, Verification}

  describe "verify_optimum/1 on valid matchings" do
    test "verifies empty graph" do
      graph = Graph.new([])
      ctx = Context.new(graph)
      assert {:ok, :verified} = Verification.verify_optimum(ctx)
    end

    test "verifies single edge matching" do
      edges = [{0, 1, 10}]
      ctx = run_matching(edges)
      assert {:ok, :verified} = Verification.verify_optimum(ctx)
    end

    test "verifies path graph matching" do
      edges = [{0, 1, 5}, {1, 2, 3}]
      ctx = run_matching(edges)
      assert {:ok, :verified} = Verification.verify_optimum(ctx)
    end

    test "verifies square (4-cycle) matching" do
      edges = [{0, 1, 1}, {1, 2, 1}, {2, 3, 1}, {3, 0, 1}]
      ctx = run_matching(edges)
      assert {:ok, :verified} = Verification.verify_optimum(ctx)
    end

    test "verifies triangle matching" do
      edges = [{0, 1, 10}, {1, 2, 10}, {0, 2, 10}]
      ctx = run_matching(edges)
      assert {:ok, :verified} = Verification.verify_optimum(ctx)
    end

    test "verifies pentagon matching" do
      edges = [{0, 1, 1}, {1, 2, 1}, {2, 3, 1}, {3, 4, 1}, {4, 0, 1}]
      ctx = run_matching(edges)
      assert {:ok, :verified} = Verification.verify_optimum(ctx)
    end

    test "verifies complete graph K4 matching" do
      edges = [
        {0, 1, 1},
        {0, 2, 1},
        {0, 3, 1},
        {1, 2, 1},
        {1, 3, 1},
        {2, 3, 1}
      ]

      ctx = run_matching(edges)
      assert {:ok, :verified} = Verification.verify_optimum(ctx)
    end

    test "verifies complete graph K5 matching" do
      edges =
        for i <- 0..3, j <- (i + 1)..4 do
          {i, j, 1}
        end

      ctx = run_matching(edges)
      assert {:ok, :verified} = Verification.verify_optimum(ctx)
    end

    test "verifies triangle with tail matching" do
      edges = [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 10}]
      ctx = run_matching(edges)
      assert {:ok, :verified} = Verification.verify_optimum(ctx)
    end

    test "verifies disconnected components" do
      edges = [{0, 1, 5}, {2, 3, 10}]
      ctx = run_matching(edges)
      assert {:ok, :verified} = Verification.verify_optimum(ctx)
    end

    test "verifies weighted triangle - prefers heavy edge" do
      edges = [{0, 1, 10}, {1, 2, 5}, {0, 2, 5}]
      ctx = run_matching(edges)
      assert {:ok, :verified} = Verification.verify_optimum(ctx)
    end

    test "verifies nested blossoms" do
      # Two triangles connected by an edge
      edges = [
        {0, 1, 1},
        {1, 2, 1},
        {0, 2, 1},
        {2, 3, 1},
        {3, 4, 1},
        {4, 5, 1},
        {3, 5, 1}
      ]

      ctx = run_matching(edges)
      assert {:ok, :verified} = Verification.verify_optimum(ctx)
    end

    test "verifies 9-cycle matching" do
      edges =
        for i <- 0..8 do
          {i, rem(i + 1, 9), 1}
        end

      ctx = run_matching(edges)
      assert {:ok, :verified} = Verification.verify_optimum(ctx)
    end
  end

  describe "verify_optimum/1 with random graphs" do
    test "verifies 50 random small graphs" do
      :rand.seed(:exsss, {42, 42, 42})

      for _ <- 1..50 do
        num_vertices = max(2, :rand.uniform(10))
        density = :rand.uniform() * 0.8 + 0.1
        edges = GraphGenerator.random_graph(num_vertices, density, {1, 100})

        if edges != [] do
          ctx = run_matching(edges)
          assert {:ok, :verified} = Verification.verify_optimum(ctx)
        end
      end
    end

    test "verifies 20 random medium graphs" do
      :rand.seed(:exsss, {123, 123, 123})

      for _ <- 1..20 do
        num_vertices = max(2, :rand.uniform(20))
        density = :rand.uniform() * 0.6 + 0.2
        edges = GraphGenerator.random_graph(num_vertices, density, {1, 50})

        if edges != [] do
          ctx = run_matching(edges)
          assert {:ok, :verified} = Verification.verify_optimum(ctx)
        end
      end
    end
  end

  # Helper to run the matching algorithm and return the final context
  defp run_matching(edges) do
    edges = Enum.filter(edges, fn {_x, _y, w} -> w >= 0 end)

    if edges == [] do
      Graph.new([]) |> Context.new()
    else
      graph = Graph.new(edges)
      ctx = Context.new(graph)
      run_stages(ctx)
    end
  end

  defp run_stages(ctx) do
    case Stage.run_stage(ctx) do
      {true, ctx} -> run_stages(ctx)
      {false, ctx} -> ctx
    end
  end
end
