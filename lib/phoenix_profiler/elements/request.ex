defmodule PhoenixProfiler.Elements.Request do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div class="phxprof-toolbar-panel phxprof-toolbar-panel-request" aria-label={"Status, #{@request.status_phrase}"}>
      <div class="phxprof-toolbar-icon">
        <span class={"phxprof-toolbar-status phxprof-toolbar-status-#{@request.class}"}>
        <%= if @request.status_code == ":|" do %>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM7 9a1 1 0 100-2 1 1 0 000 2zm7-1a1 1 0 11-2 0 1 1 0 012 0zm-7.536 5.879a1 1 0 001.415 0 3 3 0 014.242 0 1 1 0 001.415-1.415 5 5 0 00-7.072 0 1 1 0 000 1.415z" clip-rule="evenodd" />
          </svg>
        <% else %>
          <%= @request.status_code %>
        <% end %>
        </span>
        <%= if @request.router_helper do %>
          <span class="phxprof-toolbar-label"> @</span>
          <span class="phxprof-toolbar-value" title={@request.router_helper}><%= @request.router_helper %></span>
        <% end %>
      </div>
      <div class="phxprof-toolbar-info">
        <div class="phxprof-toolbar-info-item">
          <b>HTTP status</b>
          <span><%= @request.status_code %> <%= @request.status_phrase %></span>
        </div>
        <div class="phxprof-toolbar-info-item">
          <b>Plug</b>
          <span><%= @request.plug %></span>
        </div>
        <div class="phxprof-toolbar-info-item">
          <b>Route action</b>
          <span><%= @request.action %></span>
        </div>
        <div class="phxprof-toolbar-info-item">
          <b>Router</b>
          <span><%= @request.router %></span>
        </div>
        <div class="phxprof-toolbar-info-item">
          <b>Endpoint</b>
          <span><%= @request.endpoint %></span>
        </div>
      </div>
    </div>
    """
  end
end
