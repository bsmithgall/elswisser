defmodule ElswisserWeb.PairShare do
  import ElswisserWeb.CoreComponents
  use Phoenix.Component

  attr(:game, :map, required: true)

  def share_card(assigns) do
    ~H"""
    <div class="rounded-md leading-6">
      <.share_player_wrapper player={@game.white} color={:white} />
      <.share_player_wrapper player={@game.black} color={:black} />
    </div>
    """
  end

  attr(:player, :map, required: true)
  attr(:color, :atom, values: [:white, :black])

  def share_player_wrapper(%{color: :white} = assigns) do
    ~H"""
    <div class={[
      "border text-center p-4 relative uppercase",
      "bg-boardwhite border-boardblack text-zinc-800 border-b-0 rounded-t-md"
    ]}>
      <div class="absolute top-0 left-0 text-xs border border-zinc-600 rounded-sm px-0.5 ml-0.5 mt-0.5">
        White
      </div>
      <.share_player player={@player} />
    </div>
    """
  end

  def share_player_wrapper(%{color: :black} = assigns) do
    ~H"""
    <div class={[
      "border text-center p-4 relative uppercase",
      "bg-boardblack border-boardblack text-zinc-100 rounded-b-md"
    ]}>
      <div class="absolute top-0 left-0 text-xs border rounded-sm px-0.5 ml-0.5 mt-0.5">
        Black
      </div>
      <.share_player player={@player} />
    </div>
    """
  end

  attr(:player, :map, required: true)

  def share_player(assigns) do
    ~H"""
    <div class="text-base font-bold">
      {@player.name}
      <div
        :if={!is_nil(@player.chesscom) or !is_nil(@player.lichess)}
        class={[
          "mt-2 grid grid-flow-col gap-6 place-content-center",
          "normal-case font-light text-sm font-mono"
        ]}
      >
        <span :if={@player.chesscom} class="flex items-center gap-1">
          <.icon name="icon-chesscom" class="bg-green-400 opacity-70" />
          {@player.chesscom}
        </span>
        <span :if={@player.lichess} class="flex items-center gap-1">
          <.icon name="icon-lichess" />
          {@player.lichess}
        </span>
      </div>
    </div>
    """
  end
end
