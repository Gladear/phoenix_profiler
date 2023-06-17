defmodule PhoenixProfiler.Elements.RequestDuration do
  use PhoenixProfiler.Element

  @impl PhoenixProfiler.Element
  def render(assigns) do
    ~H"""
    <.element :if={@total} aria-label="Durations">
      <:item>
        <.current_duration total={@total} latest_event={@latest_event} />
      </:item>

      <:details>
        <.item :if={@total}>
          <:label>Total Duration</:label>
          <:value><%= @total.value %><%= @total.label %></:value>
        </.item>
        <.item :if={@endpoint}>
          <:label>Endpoint Duration</:label>
          <:value><%= @endpoint.value %><%= @endpoint.label %></:value>
        </.item>
        <.item :if={@latest_event}>
          <:label>Latest Event Duration</:label>
          <:value><%= @latest_event.value %><%= @latest_event.label %></:value>
        </.item>
      </:details>
    </.element>
    """
  end

  defp current_duration(%{latest_event: nil} = assigns) do
    assigns =
      assign_new(assigns, :duration, fn ->
        if event = assigns.latest_event,
          do: event,
          else: assigns.total
      end)

    ~H"""
    <%= @duration.value %>
    <.label><%= @duration.label %></.label>
    """
  end

  @impl PhoenixProfiler.Element
  def subscribed_events,
    do: [
      [:phxprof, :plug, :stop],
      [:phoenix, :endpoint, :stop]
    ]

  @impl PhoenixProfiler.Element
  def collect([:phxprof, :plug, :stop], measurements, _metadata) do
    %{total: measurements.duration}
  end

  def collect([:phoenix, :endpoint, :stop], measurements, _metadata) do
    %{endpoint: measurements.duration}
  end

  @impl PhoenixProfiler.Element
  def entries_assigns(entries) do
    %{total: total, endpoint: endpoint} = Enum.reduce(entries, &Map.merge/2)

    %{
      total: formatted_duration(total),
      endpoint: formatted_duration(endpoint),
      latest_event: nil
    }
  end

  defp formatted_duration(duration) when is_integer(duration) do
    duration = System.convert_time_unit(duration, :native, :microsecond)

    if duration > 1000 do
      value = duration |> div(1000) |> Integer.to_string()
      %{value: value, label: "ms", phrase: "#{value} milliseconds"}
    else
      value = Integer.to_string(duration)
      %{value: value, label: "µs", phrase: "#{value} microseconds"}
    end
  end
end
