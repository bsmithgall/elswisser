defmodule MaxWeightMatching.Viz.Live do
  use ElswisserWeb, :live_view

  alias MaxWeightMatching.Stepper
  alias MaxWeightMatching.Viz.EdgeParser
  alias MaxWeightMatching.Viz.HowItWorks
  alias MaxWeightMatching.Viz.Legend
  alias MaxWeightMatching.Viz.Serializer
  alias MaxWeightMatching.Viz.StepText
  alias MaxWeightMatching.Viz.Summary

  @default_edges [
    {0, 1, 10},
    {1, 2, 10},
    {2, 0, 10},
    {0, 3, 8},
    {1, 4, 8},
    {2, 5, 8},
    {3, 4, 5},
    {4, 5, 5},
    {5, 6, 4}
  ]
  @play_interval_ms 800

  @impl true
  def mount(params, _session, socket) do
    {edges, vertex_labels} = edges_from_params(params)
    steps = Stepper.run(edges)

    socket =
      socket
      |> assign(
        page_title: "Edmond's Blossom Algorithm",
        edges: edges,
        edge_input: EdgeParser.format(edges),
        vertex_labels: vertex_labels,
        steps: steps,
        current: 0,
        playing: false,
        error: nil
      )

    {:ok, push_current_step(socket), layout: {ElswisserWeb.Layouts, :viz}}
  end

  @impl true
  def render(assigns) do
    step = Enum.at(assigns.steps, assigns.current)
    assigns = assign(assigns, step: step)

    ~H"""
    <div class="flex items-center gap-2 mb-6">
      <h1 class="text-lg font-semibold leading-8 text-zinc-800">Edmond's Blossom Algorithm</h1>
      <button
        phx-click={show_modal("how-it-works")}
        class="text-zinc-400 hover:text-zinc-600"
        title="How this works"
      >
        <.icon name="hero-question-mark-circle" class="h-5 w-5" />
      </button>
    </div>

    <div class="flex flex-col lg:flex-row gap-6">
      <div class="flex-1 min-h-[400px] max-h-[600px]">
        <div
          id="matching-graph"
          phx-hook="MatchingVizHook"
          phx-update="ignore"
          class="w-full h-full min-h-[400px] max-h-[600px] border border-zinc-200 rounded-lg bg-zinc-50"
        >
        </div>
      </div>

      <div class="w-full lg:w-96 flex flex-col gap-3">
        <Summary.summary current={@current} total={length(@steps)} step={@step} playing={@playing} />

        <div class="text-xs text-zinc-600 bg-zinc-50 border border-zinc-200 rounded px-3 py-2 leading-relaxed min-h-[6rem] max-h-[16rem] overflow-y-auto">
          {StepText.explanation(@step)}
        </div>

        <Legend.legend />

        <form phx-submit="set-edges" class="space-y-2">
          <label class="block text-sm font-medium text-zinc-700">
            Edges <span class="text-zinc-400 font-normal">(one per line: x, y, weight)</span>
          </label>
          <textarea
            name="edges"
            rows="5"
            class="block w-full rounded-md border-zinc-300 text-sm font-mono shadow-sm focus:border-blue-500 focus:ring-blue-500"
          >{@edge_input}</textarea>
          <button
            type="submit"
            class="rounded-md bg-brand px-3 py-1.5 text-sm font-semibold text-white hover:opacity-90"
          >
            Update Graph
          </button>
          <p :if={@error} class="text-sm text-red-600">{@error}</p>
        </form>
      </div>
    </div>

    <.modal id="how-it-works">
      <HowItWorks.how_it_works />
    </.modal>
    """
  end

  @impl true
  def handle_event("prev", _params, socket) do
    {:noreply, go_to(socket, socket.assigns.current - 1)}
  end

  def handle_event("next", _params, socket) do
    {:noreply, go_to(socket, socket.assigns.current + 1)}
  end

  def handle_event("first", _params, socket) do
    {:noreply, go_to(socket, 0)}
  end

  def handle_event("last", _params, socket) do
    {:noreply, go_to(socket, length(socket.assigns.steps) - 1)}
  end

  def handle_event("toggle-play", _params, socket) do
    playing = !socket.assigns.playing

    if playing, do: schedule_tick()

    {:noreply, assign(socket, playing: playing)}
  end

  def handle_event("set-edges", %{"edges" => input}, socket) do
    case EdgeParser.parse(input) do
      {:ok, edges} ->
        steps = Stepper.run(edges)

        socket =
          socket
          |> assign(
            edges: edges,
            edge_input: input,
            vertex_labels: %{},
            steps: steps,
            current: 0,
            playing: false,
            error: nil
          )
          |> push_event("reset", %{})
          |> push_current_step()

        {:noreply, socket}

      {:error, msg} ->
        {:noreply, assign(socket, error: msg)}
    end
  end

  @impl true
  def handle_info(:tick, socket) do
    if socket.assigns.playing do
      max = length(socket.assigns.steps) - 1
      next = socket.assigns.current + 1

      if next > max do
        {:noreply, assign(socket, playing: false)}
      else
        schedule_tick()
        {:noreply, go_to(socket, next)}
      end
    else
      {:noreply, socket}
    end
  end

  # --- Helpers ---

  defp go_to(socket, idx) do
    max = length(socket.assigns.steps) - 1
    idx = idx |> max(0) |> min(max)

    socket
    |> assign(current: idx)
    |> push_current_step()
  end

  defp push_current_step(socket) do
    step = Enum.at(socket.assigns.steps, socket.assigns.current)

    data =
      step
      |> Serializer.serialize()
      |> Map.put(:vertex_labels_map, serialize_vertex_labels(socket.assigns.vertex_labels))

    push_event(socket, "step", data)
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @play_interval_ms)
  end

  defp edges_from_params(%{"edges" => edges_param} = params) do
    case EdgeParser.decode(edges_param) do
      {:ok, edges} ->
        labels = parse_labels_param(params["labels"], length(vertex_ids(edges)))
        {edges, labels}

      {:error, _} ->
        {@default_edges, %{}}
    end
  end

  defp edges_from_params(_), do: {@default_edges, %{}}

  defp parse_labels_param(nil, _), do: %{}
  defp parse_labels_param("", _), do: %{}

  defp parse_labels_param(labels_param, expected_count) do
    names = String.split(labels_param, "|")

    if length(names) == expected_count do
      names |> Enum.with_index() |> Map.new(fn {name, idx} -> {idx, name} end)
    else
      %{}
    end
  end

  defp vertex_ids(edges) do
    edges
    |> Enum.flat_map(fn {x, y, _w} -> [x, y] end)
    |> Enum.uniq()
  end

  defp serialize_vertex_labels(labels) when map_size(labels) == 0, do: nil

  defp serialize_vertex_labels(labels) do
    Map.new(labels, fn {k, v} -> {Integer.to_string(k), v} end)
  end
end
