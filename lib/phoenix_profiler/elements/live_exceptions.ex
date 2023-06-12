defmodule PhoenixProfiler.Elements.LiveExceptions do
  use PhoenixProfiler.Element

  def render(assigns) do
    ~H"""
    <.element :if={@exits_count > 0} aria-label="Exits">
      <:item><%= @exits_count %></:item>

      <:details>
        <.item :for={%{at: at, reason: reason} <- @exits}>
          <:label><%= at %></:label>
          <:value><%= reason %></:value>
        </.item>
      </:details>
    </.element>
    """
  end
end
