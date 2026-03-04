defmodule Mix.Tasks.MaxWeightMatching.Verify do
  @moduledoc """
  Verifies the Elixir blossom implementation against the Python reference.

  Generates random graphs and compares the total matching weights from both
  implementations to ensure they produce optimal results.

  Note: This task is only available in the test environment since it depends
  on test support modules.

  ## Usage

      MIX_ENV=test mix max_weight_matching.verify [options]

  ## Options

    * `--count` - Number of random tests to run (default: 100)
    * `--max-vertices` - Maximum number of vertices in generated graphs (default: 15)
    * `--density` - Edge density for random graphs, 0.0 to 1.0 (default: 0.5)
    * `--seed` - Random seed for reproducible tests (default: random)
    * `--verbose` - Print details for each test case

  ## Examples

      MIX_ENV=test mix max_weight_matching.verify
      MIX_ENV=test mix max_weight_matching.verify --count 500 --max-vertices 20
      MIX_ENV=test mix max_weight_matching.verify --seed 12345 --verbose
  """

  @shortdoc "Verify Elixir blossom implementation against Python reference"

  use Mix.Task

  alias MaxWeightMatching
  alias TestSupport.GraphGenerator

  @default_count 100
  @default_max_vertices 15
  @default_density 0.5
  @weight_range {1, 100}

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          count: :integer,
          max_vertices: :integer,
          density: :float,
          seed: :integer,
          verbose: :boolean
        ],
        aliases: [
          c: :count,
          m: :max_vertices,
          d: :density,
          s: :seed,
          v: :verbose
        ]
      )

    count = Keyword.get(opts, :count, @default_count)
    max_vertices = Keyword.get(opts, :max_vertices, @default_max_vertices)
    density = Keyword.get(opts, :density, @default_density)
    verbose = Keyword.get(opts, :verbose, false)

    seed =
      case Keyword.get(opts, :seed) do
        nil ->
          seed = :rand.uniform(1_000_000)
          :rand.seed(:exsss, {seed, seed, seed})
          seed

        seed ->
          :rand.seed(:exsss, {seed, seed, seed})
          seed
      end

    Mix.shell().info("Blossom Algorithm Verification")
    Mix.shell().info("==============================")
    Mix.shell().info("Count: #{count}")
    Mix.shell().info("Max vertices: #{max_vertices}")
    Mix.shell().info("Density: #{density}")
    Mix.shell().info("Seed: #{seed}")
    Mix.shell().info("")

    # Start the Python worker
    Mix.shell().info("Starting Python worker...")
    path = [:code.priv_dir(:elswisser), "python"] |> Path.join()

    case :python.start([{:python_path, to_charlist(path)}, {:python, ~c"python3"}]) do
      {:ok, python_pid} ->
        try do
          run_comparison_tests(python_pid, count, max_vertices, density, verbose)
        after
          :python.stop(python_pid)
        end

      {:error, reason} ->
        Mix.shell().error("Failed to start Python: #{inspect(reason)}")
        Mix.shell().error("Make sure python3 is available and erlport is installed.")
    end
  end

  defp run_comparison_tests(python_pid, count, max_vertices, density, verbose) do
    Mix.shell().info("Running #{count} comparison tests...\n")

    results =
      1..count
      |> Enum.map(fn i ->
        # Generate random graph
        num_vertices = max(2, :rand.uniform(max_vertices))
        edges = GraphGenerator.random_graph(num_vertices, density, @weight_range)

        # Run both implementations
        {elixir_time, elixir_result} = :timer.tc(fn -> run_elixir(edges) end)
        {python_time, python_result} = :timer.tc(fn -> run_python(python_pid, edges) end)

        # Compare weights
        elixir_weight = total_weight(edges, elixir_result)
        python_weight = total_weight(edges, python_result)

        passed = elixir_weight == python_weight

        if verbose or not passed do
          status = if passed, do: "PASS", else: "FAIL"
          Mix.shell().info("Test #{i}: #{status}")
          Mix.shell().info("  Vertices: #{num_vertices}, Edges: #{length(edges)}")
          Mix.shell().info("  Elixir weight: #{elixir_weight} (#{elixir_time}μs)")
          Mix.shell().info("  Python weight: #{python_weight} (#{python_time}μs)")

          if not passed do
            Mix.shell().info("  Elixir matching: #{inspect(elixir_result)}")
            Mix.shell().info("  Python matching: #{inspect(python_result)}")
            Mix.shell().info("  Edges: #{inspect(edges)}")
          end

          Mix.shell().info("")
        else
          # Progress indicator
          if rem(i, 10) == 0 do
            Mix.shell().info("  Completed #{i}/#{count} tests...")
          end
        end

        %{passed: passed, elixir_time: elixir_time, python_time: python_time}
      end)

    # Summary
    passed = Enum.count(results, & &1.passed)
    failed = count - passed

    elixir_times = Enum.map(results, & &1.elixir_time)
    python_times = Enum.map(results, & &1.python_time)

    total_elixir_time = Enum.sum(elixir_times)
    total_python_time = Enum.sum(python_times)

    Mix.shell().info("")
    Mix.shell().info("Results")
    Mix.shell().info("=======")
    Mix.shell().info("Passed: #{passed}/#{count}")
    Mix.shell().info("Failed: #{failed}/#{count}")
    Mix.shell().info("")

    # Detailed timing statistics
    Mix.shell().info("Timing Summary")
    Mix.shell().info("--------------")
    Mix.shell().info("                   Elixir          Python")

    Mix.shell().info(
      "Total:             #{format_time(total_elixir_time)}       #{format_time(total_python_time)}"
    )

    Mix.shell().info(
      "Average:           #{format_time(avg(elixir_times))}       #{format_time(avg(python_times))}"
    )

    Mix.shell().info(
      "Median:            #{format_time(percentile(elixir_times, 50))}       #{format_time(percentile(python_times, 50))}"
    )

    Mix.shell().info(
      "P95:               #{format_time(percentile(elixir_times, 95))}       #{format_time(percentile(python_times, 95))}"
    )

    Mix.shell().info(
      "P99:               #{format_time(percentile(elixir_times, 99))}       #{format_time(percentile(python_times, 99))}"
    )

    Mix.shell().info(
      "Max:               #{format_time(Enum.max(elixir_times))}       #{format_time(Enum.max(python_times))}"
    )

    Mix.shell().info("")

    Mix.shell().info(
      "Elixir/Python ratio: #{Float.round(total_elixir_time / max(total_python_time, 1), 2)}x"
    )

    if failed > 0 do
      Mix.raise("#{failed} test(s) failed!")
    else
      Mix.shell().info("\nAll tests passed!")
    end
  end

  defp format_time(microseconds) when is_number(microseconds) do
    ms = Float.round(microseconds / 1000, 2)
    String.pad_leading("#{ms}ms", 10)
  end

  defp avg([]), do: 0
  defp avg(list), do: Enum.sum(list) / length(list)

  defp percentile([], _p), do: 0

  defp percentile(list, p) do
    sorted = Enum.sort(list)
    k = p / 100 * (length(sorted) - 1)
    f = floor(k)
    c = ceil(k)

    if f == c do
      Enum.at(sorted, f)
    else
      lower = Enum.at(sorted, f)
      upper = Enum.at(sorted, c)
      lower + (upper - lower) * (k - f)
    end
  end

  defp run_elixir(edges) do
    MaxWeightMatching.maximum_weight_matching(edges)
  end

  defp run_python(python_pid, edges) do
    # Convert edges to format Python expects (list of tuples)
    python_edges = Enum.map(edges, fn {x, y, w} -> {x, y, w} end)

    result = :python.call(python_pid, :mwmatching, :maximum_weight_matching, [python_edges])

    # Convert Python result to Elixir format
    # Python returns list of tuples
    result
    |> Enum.map(fn
      {x, y} -> {x, y}
      [x, y] -> {x, y}
    end)
  end

  defp total_weight(edges, matching) do
    matching
    |> Enum.map(fn {x, y} ->
      Enum.find_value(edges, 0, fn {a, b, w} ->
        if (a == x and b == y) or (a == y and b == x), do: w
      end)
    end)
    |> Enum.sum()
  end
end
