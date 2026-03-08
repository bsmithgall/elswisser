defmodule MaxWeightMatching.Stepper do
  @moduledoc """
  Instrumented runner for the blossom algorithm that produces step-by-step snapshots.

  Replays the same control flow as `Stage.run_stage/1` and `run_substages/1`,
  but captures a `Step` snapshot after each meaningful operation. The BFS scan
  is unpacked to per-vertex granularity via `Stage.scan_vertex_edges/2`.

  ## Usage

      # Get all steps as a list
      steps = MaxWeightMatching.Stepper.run([{0, 1, 10}, {1, 2, 5}])

      # Fold over steps with a callback
      {matching, count} = MaxWeightMatching.Stepper.run(edges, fn _step, n -> n + 1 end, 0)
  """

  alias MaxWeightMatching.{Context, Graph, Stage, Label, Augment, BlossomOps, Slack, LeastSlack}
  alias MaxWeightMatching.Blossom.NonTrivial
  alias MaxWeightMatching.Stepper.{Step, Snapshot}

  @type on_step :: (Step.t(), term() -> term())

  @doc """
  Run the matching algorithm on the given edges, collecting step snapshots.

  Returns a list of `Step` structs in chronological order.
  """
  @spec run([MaxWeightMatching.edge()]) :: [Step.t()]
  def run(edges) do
    {_matching, steps} = run(edges, fn step, acc -> [step | acc] end, [])
    Enum.reverse(steps)
  end

  @doc """
  Run the matching algorithm, folding over steps with a callback.

  `on_step` is called as `on_step.(step, accumulator)` for each event.
  Returns `{final_matching, final_accumulator}`.
  """
  @spec run([MaxWeightMatching.edge()], on_step, acc) ::
          {[MaxWeightMatching.matched_pair()], acc}
        when on_step: (Step.t(), acc -> acc), acc: term()
  def run(edges, on_step, initial_acc) do
    graph = Graph.new(edges)
    ctx = Context.new(graph)

    acc =
      emit(
        on_step,
        initial_acc,
        :init,
        %{num_vertices: graph.num_vertex, num_edges: graph.num_edges},
        ctx
      )

    {ctx, acc} = run_stages(ctx, acc, on_step, 1)

    matching = extract_matching(ctx, edges)
    {matching, acc}
  end

  # --- Stage loop ---

  defp run_stages(ctx, acc, on_step, stage_num) do
    ctx = Stage.reset_stage(ctx)
    ctx = label_unmatched_s(ctx)

    s_vertices =
      0..(ctx.graph.num_vertex - 1)
      |> Enum.filter(fn v -> Context.get_vertex_blossom(ctx, v).label == :s end)

    acc = emit(on_step, acc, :stage_start, %{stage: stage_num, s_vertices: s_vertices}, ctx)

    if Context.queue_empty?(ctx) do
      acc = emit(on_step, acc, :stage_end, %{stage: stage_num, augmented: false}, ctx)
      {ctx, acc}
    else
      {path, ctx, acc} = run_substages(ctx, acc, on_step, stage_num)

      case path do
        nil ->
          acc = emit(on_step, acc, :stage_end, %{stage: stage_num, augmented: false}, ctx)
          {ctx, acc}

        path ->
          ctx = Augment.augment_matching(ctx, path)
          acc = emit(on_step, acc, :augment, %{path_edges: path.edges}, ctx)
          ctx = Stage.reset_stage(ctx)
          acc = emit(on_step, acc, :stage_end, %{stage: stage_num, augmented: true}, ctx)
          run_stages(ctx, acc, on_step, stage_num + 1)
      end
    end
  end

  # --- Substage loop (scan + delta) ---

  defp run_substages(ctx, acc, on_step, stage_num) do
    case scan_loop(ctx, acc, on_step) do
      {:augmenting_path, path, ctx, acc} ->
        {path, ctx, acc}

      {:queue_empty, ctx, acc} ->
        {delta_type, delta_2x, delta_edge, delta_blossom_id} =
          Stage.substage_calc_dual_delta(ctx)

        delta_candidates = collect_delta_candidates(ctx)

        ctx = Stage.substage_apply_delta_step(ctx, delta_2x)

        case delta_type do
          1 ->
            acc =
              emit(
                on_step,
                acc,
                :delta_step,
                %{delta_type: 1, delta_2x: delta_2x, delta_candidates: delta_candidates},
                ctx
              )

            {nil, ctx, acc}

          2 ->
            {x, y, _w} = Graph.get_edge(ctx.graph, delta_edge)

            {x, y} =
              if Context.get_vertex_blossom(ctx, x).label != :s, do: {y, x}, else: {x, y}

            ctx = Label.assign_label_t(ctx, x, y)

            acc =
              emit(
                on_step,
                acc,
                :delta_step,
                %{
                  delta_type: 2,
                  delta_2x: delta_2x,
                  edge: delta_edge,
                  x: x,
                  y: y,
                  delta_candidates: delta_candidates
                },
                ctx
              )

            run_substages(ctx, acc, on_step, stage_num)

          3 ->
            {x, y, _w} = Graph.get_edge(ctx.graph, delta_edge)

            case Stage.add_s_to_s_edge(ctx, x, y) do
              {:augmenting_path, path, ctx} ->
                acc =
                  emit(
                    on_step,
                    acc,
                    :delta_step,
                    %{
                      delta_type: 3,
                      delta_2x: delta_2x,
                      edge: delta_edge,
                      result: :augmenting_path,
                      delta_candidates: delta_candidates
                    },
                    ctx
                  )

                {path, ctx, acc}

              {:blossom, ctx} ->
                acc =
                  emit(
                    on_step,
                    acc,
                    :delta_step,
                    %{
                      delta_type: 3,
                      delta_2x: delta_2x,
                      edge: delta_edge,
                      result: :blossom,
                      delta_candidates: delta_candidates
                    },
                    ctx
                  )

                run_substages(ctx, acc, on_step, stage_num)
            end

          4 ->
            ctx = BlossomOps.expand_t_blossom(ctx, delta_blossom_id)

            acc =
              emit(
                on_step,
                acc,
                :delta_step,
                %{
                  delta_type: 4,
                  delta_2x: delta_2x,
                  delta_candidates: delta_candidates
                },
                ctx
              )

            run_substages(ctx, acc, on_step, stage_num)
        end
    end
  end

  # --- BFS scan loop (per-vertex granularity) ---

  defp scan_loop(ctx, acc, on_step) do
    case Context.dequeue(ctx) do
      :empty ->
        {:queue_empty, ctx, acc}

      {x, ctx} ->
        neighbor_edges = analyze_vertex_edges(ctx, x)
        prev_delta_candidates = collect_delta_candidates(ctx)
        blossom_count_before = map_size(ctx.blossoms)

        case Stage.scan_vertex_edges(ctx, x) do
          {:augmenting_path, path, ctx} ->
            delta_candidates = collect_delta_candidates(ctx)

            acc =
              emit(
                on_step,
                acc,
                :scan_step,
                %{
                  vertex: x,
                  result: :augmenting_path,
                  neighbor_edges: neighbor_edges,
                  prev_delta_candidates: prev_delta_candidates,
                  delta_candidates: delta_candidates,
                  active_delta_wins: compute_active_delta_wins(ctx, x, delta_candidates)
                },
                ctx
              )

            {:augmenting_path, path, ctx, acc}

          {:continue, ctx} ->
            # Detect blossoms created as a side effect of scan_vertex_edges
            # (tight S-S same-tree edges create blossoms but return :continue)
            delta_candidates = collect_delta_candidates(ctx)

            detail = %{
              vertex: x,
              neighbor_edges: neighbor_edges,
              prev_delta_candidates: prev_delta_candidates,
              delta_candidates: delta_candidates,
              active_delta_wins: compute_active_delta_wins(ctx, x, delta_candidates)
            }

            detail =
              if map_size(ctx.blossoms) > blossom_count_before do
                Map.put(detail, :result, :blossom)
              else
                detail
              end

            acc = emit(on_step, acc, :scan_step, detail, ctx)

            scan_loop(ctx, acc, on_step)
        end
    end
  end

  # --- Edge analysis (read-only, for visualization) ---

  defp analyze_vertex_edges(ctx, x) do
    adjacent_edges = Map.fetch!(ctx.graph.adjacent_edges, x)
    x_dual_2x = Map.fetch!(ctx.vertex_dual_2x, x)

    Enum.flat_map(adjacent_edges, fn e ->
      {p, q, w} = Graph.get_edge(ctx.graph, e)
      y = if p == x, do: q, else: p
      y_dual_2x = Map.fetch!(ctx.vertex_dual_2x, y)

      if Context.same_blossom?(ctx, x, y) do
        [%{edge: e, neighbor: y, weight: w, classification: :internal}]
      else
        slack = Slack.edge_slack_2x(ctx, e)
        by = Context.get_vertex_blossom(ctx, y)

        classification =
          case {by.label, slack <= 0} do
            {:none, true} -> :grow
            {:s, true} -> :s_to_s
            {:t, true} -> :tight_t
            {:s, false} -> :delta3
            {_, false} -> :delta2
          end

        [
          %{
            edge: e,
            neighbor: y,
            weight: w,
            slack_2x: slack,
            neighbor_label: by.label,
            classification: classification,
            x_budget: x_dual_2x,
            y_budget: y_dual_2x,
            neighbor_in_blossom: match?(%NonTrivial{}, by)
          }
        ]
      end
    end)
  end

  # --- Delta candidate collection (read-only, for visualization) ---

  defp collect_delta_candidates(ctx) do
    # Δ₁: min S-vertex dual
    delta1 =
      0..(ctx.graph.num_vertex - 1)
      |> Enum.filter(fn x -> Context.get_vertex_blossom(ctx, x).label == :s end)
      |> Enum.map(fn x -> Map.fetch!(ctx.vertex_dual_2x, x) end)
      |> Enum.min(fn -> nil end)

    # Δ₂: best S-to-unlabeled edge
    {e2, slack2} = LeastSlack.get_best_vertex_edge(ctx)

    # Δ₃: best S-to-S edge (halved)
    {e3, slack3_raw} = LeastSlack.get_best_blossom_edge(ctx)

    slack3 =
      cond do
        e3 == -1 -> nil
        ctx.graph.integer_weights -> div(slack3_raw, 2)
        true -> slack3_raw / 2
      end

    # Δ₄: min T-blossom dual
    delta4 =
      ctx.blossoms
      |> Map.values()
      |> Enum.filter(fn
        %NonTrivial{label: :t, parent_id: nil} -> true
        _ -> false
      end)
      |> Enum.min_by(& &1.dual_var_2x, fn -> nil end)
      |> case do
        nil -> nil
        b -> b.dual_var_2x
      end

    [
      if(delta1, do: %{delta_type: 1, value_2x: delta1, edge: nil}),
      if(e2 != -1, do: %{delta_type: 2, value_2x: slack2, edge: e2}),
      if(slack3, do: %{delta_type: 3, value_2x: slack3, edge: e3}),
      if(delta4, do: %{delta_type: 4, value_2x: delta4, edge: nil})
    ]
    |> Enum.reject(&is_nil/1)
  end

  # Determine which delta types the scanned vertex x is directly responsible for.
  # Used to highlight the relevant row in the scan-step delta table.
  defp compute_active_delta_wins(ctx, x, candidates) do
    Enum.flat_map(candidates, fn
      %{delta_type: dt, edge: e} when dt in [2, 3] and not is_nil(e) ->
        {p, q, _} = Graph.get_edge(ctx.graph, e)
        if p == x or q == x, do: [dt], else: []

      _ ->
        []
    end)
  end

  # --- Helpers ---

  defp emit(on_step, acc, type, detail, ctx) do
    step = %Step{
      type: type,
      detail: detail,
      snapshot: Snapshot.from_context(ctx)
    }

    on_step.(step, acc)
  end

  defp label_unmatched_s(ctx) do
    Enum.reduce(0..(ctx.graph.num_vertex - 1), ctx, fn x, ctx ->
      if Map.fetch!(ctx.vertex_mate, x) == -1 do
        Label.assign_label_s(ctx, x)
      else
        ctx
      end
    end)
  end

  defp extract_matching(ctx, edges) do
    edges
    |> Enum.filter(fn {x, y, _w} -> Map.fetch!(ctx.vertex_mate, x) == y end)
    |> Enum.map(fn {x, y, _w} -> {x, y} end)
  end
end
