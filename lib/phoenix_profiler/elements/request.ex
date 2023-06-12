defmodule PhoenixProfiler.Elements.Request do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div class="phxprof-element" aria-label={"Status, #{@request.status_phrase}"}>
      <span class={"phxprof-element-status phxprof-element-status-#{@request.class}"}>
        <%= if @request.status_code == ":|" do %>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM7 9a1 1 0 100-2 1 1 0 000 2zm7-1a1 1 0 11-2 0 1 1 0 012 0zm-7.536 5.879a1 1 0 001.415 0 3 3 0 014.242 0 1 1 0 001.415-1.415 5 5 0 00-7.072 0 1 1 0 000 1.415z" clip-rule="evenodd" />
          </svg>
        <% else %>
          <%= @request.status_code %>
        <% end %>
      </span>
      <div :if={@request.router_helper} class="phxprof-element-item" title={@request.router_helper}>
        <span class="phxprof-toolbar-label">@</span>
        <%= @request.router_helper %>
      </div>

      <div class="phxprof-toolbar-details">
        <span class="phxprof-item-label">HTTP status</span>
        <span class="phxprof-item-value"><%= @request.status_code %> <%= @request.status_phrase %></span>

        <span class="phxprof-item-label">Plug</span>
        <span class="phxprof-item-value"><%= @request.plug %></span>

        <span class="phxprof-item-label">Route action</span>
        <span class="phxprof-item-value"><%= @request.action %></span>

        <span class="phxprof-item-label">Router</span>
        <span class="phxprof-item-value"><%= @request.router %></span>

        <span class="phxprof-item-label">Endpoint</span>
        <span class="phxprof-item-value"><%= @request.endpoint %></span>
      </div>
    </div>
    """
  end
end
