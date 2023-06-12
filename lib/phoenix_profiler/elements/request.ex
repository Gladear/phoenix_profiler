defmodule PhoenixProfiler.Elements.Request do
  use PhoenixProfiler.Element

  def render(assigns) do
    ~H"""
    <.element aria-label={"Status, #{@request.status_phrase}"}>
      <:status color={@request.class}>
        <%= if @request.status_code == ":|" do %>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM7 9a1 1 0 100-2 1 1 0 000 2zm7-1a1 1 0 11-2 0 1 1 0 012 0zm-7.536 5.879a1 1 0 001.415 0 3 3 0 014.242 0 1 1 0 001.415-1.415 5 5 0 00-7.072 0 1 1 0 000 1.415z"
              clip-rule="evenodd"
            />
          </svg>
        <% else %>
          <%= @request.status_code %>
        <% end %>
      </:status>

      <:item>
        <.label>@</.label>
        <%= @request.router_helper %>
      </:item>

      <:details>
        <.item>
          <:label>HTTP status</:label>
          <:value><%= @request.status_code %> <%= @request.status_phrase %></:value>
        </.item>
        <.item>
          <:label>Plug</:label>
          <:value><%= @request.plug %></:value>
        </.item>
        <.item>
          <:label>Route action</:label>
          <:value><%= @request.action %></:value>
        </.item>
        <.item>
          <:label>Router</:label>
          <:value><%= @request.router %></:value>
        </.item>
        <.item>
          <:label>Endpoint</:label>
          <:value><%= @request.endpoint %></:value>
        </.item>
      </:details>
    </.element>
    """
  end
end
