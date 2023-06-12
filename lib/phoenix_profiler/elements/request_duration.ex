defmodule PhoenixProfiler.Elements.RequestDuration do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div :if={@durations} class="phxprof-element" aria-label="Durations">
      <div class="phxprof-element-item">
        <% {value, label} = current_duration(@durations) %>
        <%= value %>
        <span class="phxprof-toolbar-label"><%= label %></span>
      </div>

      <div class="phxprof-toolbar-details">
        <%= if @durations.total do %>
          <span class="phxprof-item-label">Total Duration</span>
          <span class="phxprof-item-value"><%= @durations.total.value %><%= @durations.total.label %></span>
        <% end %>
        <%= if @durations.endpoint do %>
          <span class="phxprof-item-label">Endpoint Duration</span>
          <span class="phxprof-item-value"><%= @durations.endpoint.value %> <%= @durations.endpoint.label %></span>
        <% end %>
        <%= if @durations.latest_event do %>
          <span class="phxprof-item-label">Latest Event Duration</span>
          <span class="phxprof-item-value"><%= @durations.latest_event.value %><%= @durations.latest_event.label %></span>
        <% end %>
      </div>
    </div>
    """
  end

  defp current_duration(durations) do
    if event = durations.latest_event,
      do: {event.value, event.label},
      else: {durations.total.value, durations.total.label}
  end
end
