defmodule ElswisserWeb.Layouts do
  use ElswisserWeb, :html

  embed_templates "layouts/*"

  def topnav(assigns) do
    ~H"""
    <header class="px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between border-b border-zinc-100 py-3 text-sm">
        <div class="flex items-center gap-4">
          <a href="/">
            <img src={~p"/images/elswisser.svg"} width="36" />
          </a>
          <p class="bg-brand/5 text-brand rounded-sm px-2 font-medium leading-6">
            Elswisser
          </p>
        </div>
        <div class="flex items-center gap-4 font-semibold leading-6 text-zinc-900">
          <a href={~p"/tournaments"} class="hover:text-zinc-500">
            Tournaments
          </a>
          <a href={~p"/players"} class="hover:text-zinc-500">
            Players
          </a>
        </div>
      </div>
    </header>
    """
  end
end