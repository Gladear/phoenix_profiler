defmodule PhoenixProfiler.Elements.MemoryUsage do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div :if={@memory} class="phxprof-element" aria-label={"Memory, #{@memory.phrase}"}>
      <div class="phxprof-element-item">
        <%= @memory.value %>
        <span class="phxprof-toolbar-label"><%= @memory.label %></span>
      </div>

      <div class="phxprof-toolbar-details">
        <span class="phxprof-item-label">Memory</span>
        <span class="phxprof-item-value"><%= @memory.value %> <%= @memory.label %></span>
      </div>
    </div>
    """
  end
end
