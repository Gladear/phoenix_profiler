defmodule PhoenixProfiler.ToolbarLive do
  # The LiveView for the Web Debug Toolbar
  @moduledoc false
  use Phoenix.LiveView, container: {:div, [class: "phxprof-toolbar-view"]}

  require Logger

  alias PhoenixProfiler.Profile
  alias PhoenixProfiler.Server
  alias PhoenixProfiler.Utils

  @toolbar_css Application.app_dir(:phoenix_profiler, "priv/static/toolbar.css")
               |> File.read!()
  @toolbar_js Application.app_dir(:phoenix_profiler, "priv/static/toolbar.js")
              |> File.read!()

  def toolbar(assigns) do
    assigns =
      assigns
      |> Map.put(:toolbar_css, @toolbar_css)
      |> Map.put(:toolbar_js, @toolbar_js)

    ~H"""
    <!-- START Phoenix Web Debug Toolbar -->
    <div {@toolbar_attrs}>
      <div class="phxprof-minitoolbar">
        <button
          class="show-button"
          type="button"
          id={"phxprof-toolbar-show-#{@profile.token}"}
          title="Show Toolbar"
          accesskey="D"
          aria-expanded="true"
          aria-controls={"phxprof-toolbar-main-#{@profile.token}"}
        >
        </button>
      </div>
      <%= live_render(@conn, __MODULE__, session: @session) %>
    </div>
    <script>
      <%= Phoenix.HTML.raw(@toolbar_js) %>
    </script>
    <style type="text/css">
      <%= Phoenix.HTML.raw(@toolbar_css) %>
    </style>
    <!-- END Phoenix Web Debug Toolbar -->
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= for {element, assigns} <- @elements_assigns do %>
      <%= element.render(assigns) %>
    <% end %>

    <div class="phxprof-toolbar-spacer" />

    <.profile_panel profile={@profile} />
    <.hide_button token={@profile.token} />
    """
  end

  defp profile_panel(assigns) do
    ~H"""
    <div class="phxprof-element" aria-label="Config">
      <div class="phxprof-element-item phxprof-element-phoenix-logo">
        <%= @profile.system.phoenix %>
      </div>

      <div class="phxprof-toolbar-details" style="left: auto; right: 0px">
        <span class="phxprof-item-label">Profiler Token</span>
        <span class="phxprof-item-value"><%= @profile.token %></span>

        <span class="phxprof-item-label">LiveView Version</span>
        <span class="phxprof-item-value">
          <a href={"https://hexdocs.pm/phoenix_live_view/#{@profile.system.phoenix_live_view}/"}>
            <%= @profile.system.phoenix_live_view %>
          </a>
        </span>

        <span class="phxprof-item-label">Elixir Version</span>
        <span class="phxprof-item-value">
          <a href={"https://hexdocs.pm/elixir/#{@profile.system.elixir}/"}>
            <%= @profile.system.elixir %>
          </a>
        </span>

        <span class="phxprof-item-label">OTP Release</span>
        <span class="phxprof-item-value">
          <a href="https://erlang.org/erldoc"><%= @profile.system.otp %></a>
        </span>

        <span class="phxprof-item-label">Resources</span>
        <span class="phxprof-item-value">
          <a href={"https://hexdocs.pm/phoenix/#{@profile.system.phoenix}"}>
            Read Phoenix <%= @profile.system.phoenix %> Docs
          </a>
        </span>

        <span class="phxprof-item-label">Help</span>
        <span class="phxprof-item-value">
          <a href="https://hexdocs.pm/phoenix/community.html">Phoenix Community</a>
        </span>

        <span class="phxprof-item-label">Toolbar version</span>
        <span class="phxprof-item-value">
          <a href={"https://hexdocs.pm/phoenix_profiler/#{@profile.system.phoenix_profiler}"}>
            <%= @profile.system.phoenix_profiler %>
          </a>
        </span>
      </div>
    </div>
    """
  end

  defp hide_button(assigns) do
    ~H"""
    <button
      class="hide-button"
      type="button"
      title="Hide Toolbar"
      accesskey="D"
      aria-expanded="true"
      aria-controls={"phxprof-toolbar-main-#{@token}"}
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
        <path
          fill-rule="evenodd"
          d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
          clip-rule="evenodd"
        />
      </svg>
    </button>
    """
  end

  @impl Phoenix.LiveView
  def mount(_, %{"_phxprof" => %Profile{} = profile}, socket) do
    data_entries = Server.get_entries(profile.token)

    socket =
      socket
      |> assign_elements_assigns(data_entries)
      |> assign(:profile, profile)

    if connected?(socket) do
      Server.subscribe(self(), profile.token)
    end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:entries, new_entries}, socket) do
    {:noreply, assign_elements_assigns(socket, new_entries)}
  end

  defp assign_elements_assigns(socket, entries) do
    entries_by_element = Enum.group_by(entries, &elem(&1, 1), &elem(&1, 2))

    socket
    |> assign_new(:elements_assigns, fn -> [] end)
    |> update(:elements_assigns, fn current_element_assigns ->
      Utils.elements()
      |> Enum.map(fn element ->
        element_entries = Map.get(entries_by_element, element, [])
        current_assigns = Keyword.get(current_element_assigns, element, %{})
        {element, element.entries_assigns(element_entries, current_assigns)}
      end)
    end)
  end
end
