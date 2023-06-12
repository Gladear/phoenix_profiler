defmodule PhoenixProfiler.Elements.LiveExceptions do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div :if={not Enum.empty?(@exits)} class="phxprof-element phxprof-element-status-red" aria-label="Exits">
      <div class="phxprof-element-item"><%= @exits_count %></div>

      <div class="phxprof-toolbar-details">
        <%= for %{at: at, ref: ref, reason: reason} <- @exits do %>
          <span class="phxprof-item-label" data-ref={ref}><%= at %></span>
          <span class="phxprof-item-value" data-ref={ref}><%= reason %></span>
        <% end %>
      </div>
    </div>
    """
  end
end
