defmodule PhoenixProfiler.Elements.RequestDuration do
  use PhoenixProfiler.Element

  def render(assigns) do
    ~H"""
    <.element :if={@durations} aria-label="Durations">
      <:item>
        <% {value, label} = current_duration(@durations) %>
        <%= value %>
        <.label><%= label %></.label>
      </:item>

      <:details>
        <.item :if={@durations.total}>
          <:label>Total Duration</:label>
          <:value><%= @durations.total.value %><%= @durations.total.label %></:value>
        </.item>
        <.item :if={@durations.endpoint}>
          <:label>Endpoint Duration</:label>
          <:value><%= @durations.endpoint.value %> <%= @durations.endpoint.label %></:value>
        </.item>
        <.item :if={@durations.latest_event}>
          <:label>Latest Event Duration</:label>
          <:value><%= @durations.latest_event.value %><%= @durations.latest_event.label %></:value>
        </.item>
      </:details>
    </.element>
    """
  end

  defp current_duration(durations) do
    if event = durations.latest_event,
      do: {event.value, event.label},
      else: {durations.total.value, durations.total.label}
  end
end
