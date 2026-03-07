defmodule MaxWeightMatching.Viz.Summary do
  @moduledoc """
  Function component that renders the step summary bar in the matching
  visualizer: step counter, help button, step-type badge, and transport
  controls (first / prev / play / next / last).

  Also owns the badge styling and label lookups for step types, since this
  is the only place they are rendered.
  """

  use ElswisserWeb, :html

  attr :current, :integer, required: true
  attr :total, :integer, required: true
  attr :step, :map, required: true
  attr :playing, :boolean, required: true

  def summary(assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <span class="text-sm font-medium text-zinc-700 whitespace-nowrap">
        Step {@current + 1} of {@total}
      </span>
      <button
        phx-click={show_modal("how-it-works")}
        class="text-zinc-400 hover:text-zinc-600"
        title="How this works"
      >
        <.icon name="hero-question-mark-circle" class="h-4 w-4" />
      </button>
      <span class={[
        "inline-flex items-center rounded-md px-2 py-0.5 text-xs font-medium ring-1 ring-inset",
        badge_classes(@step.type)
      ]}>
        {step_label(@step.type)}
      </span>
      <div class="flex items-center gap-1 ml-auto">
        <button
          phx-click="first"
          disabled={@current == 0}
          class="rounded bg-zinc-100 py px-2 text-zinc-700 hover:bg-zinc-200 disabled:opacity-40 disabled:cursor-not-allowed"
        >
          <.icon name="hero-backward-solid" class="h-2.5 w-2" />
        </button>
        <button
          phx-click="prev"
          disabled={@current == 0}
          class="rounded bg-zinc-100 py px-2 text-zinc-700 hover:bg-zinc-200 disabled:opacity-40 disabled:cursor-not-allowed"
        >
          <.icon name="hero-chevron-left-solid" class="h-2.5 w-2" />
        </button>
        <button
          phx-click="toggle-play"
          class={[
            "rounded py-1 px-2 text-xs font-semibold text-white",
            if(@playing,
              do: "bg-amber-500 hover:bg-amber-600",
              else: "bg-blue-500 hover:bg-blue-600"
            )
          ]}
        >
          {if @playing, do: "Pause", else: "Play"}
        </button>
        <button
          phx-click="next"
          disabled={@current >= @total - 1}
          class="rounded bg-zinc-100 py px-2 text-zinc-700 hover:bg-zinc-200 disabled:opacity-40 disabled:cursor-not-allowed"
        >
          <.icon name="hero-chevron-right-solid" class="h-2.5 w-2" />
        </button>
        <button
          phx-click="last"
          disabled={@current >= @total - 1}
          class="rounded bg-zinc-100 py px-2 text-zinc-700 hover:bg-zinc-200 disabled:opacity-40 disabled:cursor-not-allowed"
        >
          <.icon name="hero-forward-solid" class="h-2.5 w-2" />
        </button>
      </div>
    </div>
    """
  end

  # --- Badge styling and labels ---

  defp badge_classes(:init), do: "bg-zinc-50 text-zinc-600 ring-zinc-500/10"
  defp badge_classes(:stage_start), do: "bg-blue-50 text-blue-700 ring-blue-700/10"
  defp badge_classes(:scan_step), do: "bg-indigo-50 text-indigo-700 ring-indigo-700/10"
  defp badge_classes(:delta_step), do: "bg-amber-50 text-amber-700 ring-amber-700/10"
  defp badge_classes(:augment), do: "bg-green-50 text-green-700 ring-green-700/10"
  defp badge_classes(:stage_end), do: "bg-zinc-50 text-zinc-600 ring-zinc-500/10"

  defp step_label(:init), do: "Init"
  defp step_label(:stage_start), do: "Stage Start"
  defp step_label(:scan_step), do: "Scan"
  defp step_label(:delta_step), do: "Delta"
  defp step_label(:augment), do: "Augment"
  defp step_label(:stage_end), do: "Stage End"
end
