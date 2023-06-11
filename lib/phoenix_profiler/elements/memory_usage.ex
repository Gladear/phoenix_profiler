defmodule PhoenixProfiler.Elements.MemoryUsage do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div :if={@memory} class="phxprof-toolbar-panel phxprof-toolbar-panel-memory" aria-label={"Memory, #{@memory.phrase}"}>
      <div class="phxprof-toolbar-icon">
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
          <path stroke="none" d="M0 0h24v24H0z" fill="none"></path>
          <path d="M6 7h11a2 2 0 0 1 2 2v.5a0.5 .5 0 0 0 .5 .5a0.5 .5 0 0 1 .5 .5v3a0.5 .5 0 0 1 -.5 .5a0.5 .5 0 0 0 -.5 .5v.5a2 2 0 0 1 -2 2h-11a2 2 0 0 1 -2 -2v-6a2 2 0 0 1 2 -2"></path>
          <line x1="7" y1="10" x2="7" y2="14"></line>
          <line x1="10" y1="10" x2="10" y2="14"></line>
          <line x1="13" y1="10" x2="13" y2="14"></line>
        </svg>
        <span class="phxprof-toolbar-value"><%= @memory.value %></span>
        <span class="phxprof-toolbar-label"><%= @memory.label %></span>
      </div>
      <div class="phxprof-toolbar-info">
        <div class="phxprof-toolbar-info-item">
          <b>Memory</b>
          <span><%= @memory.value %> <%= @memory.label %></span>
        </div>
      </div>
    </div>
    """
  end
end
