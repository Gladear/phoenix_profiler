defmodule PhoenixProfiler.Elements.MemoryUsage do
  use PhoenixProfiler.Element

  def render(assigns) do
    ~H"""
    <.element :if={@memory} aria-label={"Memory, #{@memory.phrase}"}>
      <:item>
        <%= @memory.value %>
        <.label><%= @memory.label %></.label>
      </:item>

      <:details>
        <.item>
          <:label>Memory</:label>
          <:value><%= @memory.value %> <%= @memory.label %></:value>
        </.item>
      </:details>
    </.element>
    """
  end
end
