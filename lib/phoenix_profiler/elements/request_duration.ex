defmodule PhoenixProfiler.Elements.RequestDuration do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div :if={@durations} class="phxprof-toolbar-panel phxprof-toolbar-panel-duration" aria-label="Durations">
      <div class="phxprof-toolbar-icon">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
        </svg>
        <% {value, label} = current_duration(@durations) %>
        <span class="phxprof-toolbar-value"><%= value %></span>
        <span class="phxprof-toolbar-label"><%= label %></span>
      </div>
      <div class="phxprof-toolbar-info">
        <div :if={@durations.total} class="phxprof-toolbar-info-item">
          <b>Total Duration</b>
          <span><%= @durations.total.value %><%= @durations.total.label %></span>
        </div>
        <div :if={@durations.endpoint} class="phxprof-toolbar-info-item">
          <b>Endpoint Duration</b>
          <span><%= @durations.endpoint.value %> <%= @durations.endpoint.label %></span>
        </div>
        <div :if={@durations.latest_event} class="phxprof-toolbar-info-item">
          <b>Latest Event Duration</b>
          <span><%= @durations.latest_event.value %><%= @durations.latest_event.label %></span>
        </div>
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
