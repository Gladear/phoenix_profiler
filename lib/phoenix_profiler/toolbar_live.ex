defmodule PhoenixProfiler.ToolbarLive do
  # The LiveView for the Web Debug Toolbar
  @moduledoc false
  use Phoenix.LiveView, container: {:div, [class: "phxprof-toolbar-view"]}
  require Logger
  alias PhoenixProfiler.ProfileStore
  alias PhoenixProfiler.Routes

  toolbar_css_path = Application.app_dir(:phoenix_profiler, "priv/static/toolbar.css")
  @external_resource toolbar_css_path

  toolbar_js_path = Application.app_dir(:phoenix_profiler, "priv/static/toolbar.js")
  @external_resource toolbar_js_path

  @toolbar_css File.read!(toolbar_css_path)
  @toolbar_js File.read!(toolbar_js_path)

  def toolbar(assigns) do
    assigns = Map.put(assigns, :toolbar_css, @toolbar_css)
    assigns = Map.put(assigns, :toolbar_js, @toolbar_js)

    ~H"""
    <!-- START Phoenix Web Debug Toolbar -->
    <div {@toolbar_attrs}>
      <div class="phxprof-minitoolbar"><button class="show-button" type="button" id={"phxprof-toolbar-show-#{@profile.token}"} title="Show Toolbar" accesskey="D" aria-expanded="true" aria-controls={"phxprof-toolbar-main-#{@profile.token}"}></button></div>
      <div id={"phxprof-toolbar-clearer-#{@profile.token}"} class="phxprof-toolbar-clearer" style="display: block;"></div>
      <%= live_render(@conn, __MODULE__, session: @session) %>
    </div>
    <script><%= Phoenix.HTML.raw(@toolbar_js) %></script>
    <style type="text/css"><%= Phoenix.HTML.raw(@toolbar_css) %></style>
    <!-- END Phoenix Web Debug Toolbar -->
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="phxprof-toolbar-container">
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

      <div :if={@memory} class="phxprof-toolbar-panel phxprof-toolbar-panel-memory" aria-label={"Memory, #{@memory.phrase}"}>
        <div class="phxprof-toolbar-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
            <path stroke="none" d="M0 0h24v24H0z" fill="none"></path>
            <path d="M6 7h11a2 2 0 0 1 2 2v.5a0.5 .5 0 0 0 .5 .5a0.5 .5 0 0 1 .5 .5v3a0.5 .5 0 0 1 -.5 .5a0.5 .5 0 0 0 -.5 .5v.5a2 2 0 0 1 -2 2h-11a2 2 0 0 1 -2 -2v-6a2 2 0 0 1 2 -2"></path>
            <line x1="7" y1="10" x2="7" y2="14"></line>
            <line x1="10" y1="10" x2="10" y2="14"></line>
            <line x1="13" y1="10" x2="13" y2="14"></line>
          </svg>
          <span class="phxprof-toolbar-value"><%= @memory.value %></span>
          <span class="phxprof-toolbar-label"><%= @memory.label %></span>
        </div>
        <div class="phxprof-toolbar-info">
          <div class="phxprof-toolbar-info-item">
            <b>Memory</b>
            <span><%= @memory.value %> <%= @memory.label %></span>
          </div>
        </div>
      </div>

      <div :if={not Enum.empty?(@exits)} class="phxprof-toolbar-panel phxprof-toolbar-panel-exits phxprof-toolbar-status-red" aria-label="Exits">
        <div class="phxprof-toolbar-icon">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
          </svg>
          <span class="phxprof-toolbar-value"><%= @exits_count %></span>
        </div>
        <div class="phxprof-toolbar-info">
          <div id="phxprof-toolbar-exits" class="phxprof-toolbar-info-group" phx-update="prepend">
            <div :for={%{at: at, ref: ref, reason: reason} <- @exits} id={ref} class="phxprof-toolbar-info-item">
              <b><%= at %></b>
              <span><pre><%= reason %></pre></span>
            </div>
          </div>
        </div>
      </div>

      <div class="phxprof-toolbar-panel phxprof-toolbar-panel-config phxprof-toolbar-panel-right" aria-label="Config">
        <div class="phxprof-toolbar-icon">
          <div class="phxprof-toolbar-label"></div>
          <div class="phxprof-toolbar-value"><%= @profile.system.phoenix %></div>
        </div>

        <div class="phxprof-toolbar-info" style="right: 36px;">
          <div class="phxprof-toolbar-info-group">
            <div class="phxprof-toolbar-info-item">
              <b>Profiler Token</b>
              <span><%= @profile.token %></span>
            </div>
          </div>

          <div class="phxprof-toolbar-info-group">
            <div class="phxprof-toolbar-info-item">
              <b>LiveView Version</b><span><a href={"https://hexdocs.pm/phoenix_live_view/#{@profile.system.phoenix_live_view}/"}><%= @profile.system.phoenix_live_view %></a></span>
            </div>
            <div class="phxprof-toolbar-info-item">
              <b>Elixir Version</b>
              <span><a href={"https://hexdocs.pm/elixir/#{@profile.system.elixir}/"}><%= @profile.system.elixir %></a></span>
            </div>
            <div class="phxprof-toolbar-info-item">
              <b>OTP Release</b>
              <span><a href="https://erlang.org/erldoc"><%= @profile.system.otp %></a></span>
            </div>
          </div>

          <div class="phxprof-toolbar-info-group">
            <div class="phxprof-toolbar-info-item">
              <b>Resources</b>
              <span><a href={"https://hexdocs.pm/phoenix/#{@profile.system.phoenix}"}>Read Phoenix <%= @profile.system.phoenix %> Docs</a></span>
            </div>
            <div class="phxprof-toolbar-info-item">
              <b>Help</b>
              <span><a href="https://hexdocs.pm/phoenix/community.html">Phoenix Community</a></span>
            </div>
          </div>
          <div class="phxprof-toolbar-info-group">
            <div class="phxprof-toolbar-info-item">
              <b>Toolbar Version</b>
              <span><a href={"https://hexdocs.pm/phoenix_profiler/#{@profile.system.phoenix_profiler}"}><%= @profile.system.phoenix_profiler %></a></span>
            </div>
            <div class="phxprof-toolbar-info-item attribution">
              <b>Made with <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clip-rule="evenodd" /></svg> by</b>
              <span><a href="https://github.com/sponsors/mcrumm">@mcrumm</a></span>
            </div>
          </div>
        </div>
      </div>
      <button class="hide-button" type="button" id={"phxprof-toolbar-hide-#{@profile.token}"} title="Hide Toolbar" accesskey="D" aria-expanded="true" aria-controls={"phxprof-toolbar-main-#{@profile.token}"}>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
        </svg>
      </button>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_, %{"_" => %PhoenixProfiler.Profile{} = profile}, socket) do
    socket =
      socket
      |> assign_defaults()
      |> assign(:profile, profile)

    socket =
      case ProfileStore.get(profile.token) do
        nil -> assign_error_toolbar(socket)
        remote_profile -> assign_toolbar(socket, remote_profile)
      end

    socket = subscribe(socket)

    {:ok, socket, temporary_assigns: [exits: []]}
  end

  def mount(_, _, socket) do
    {:ok,
     socket
     |> assign_defaults()
     |> assign_error_toolbar()}
  end

  defp assign_defaults(socket) do
    assign(socket,
      durations: nil,
      exits: [],
      exits_count: 0,
      memory: nil,
      root_pid: nil
    )
  end

  defp assign_error_toolbar(socket) do
    # Apply the minimal assigns when the profiler server is not started.
    # Usually this occurs after a node has been restarted and
    # a request is received for a stale token.
    assign(socket, %{
      durations: nil,
      request: %{
        status_code: ":|",
        status_phrase: "No Profiler Session (refresh)",
        endpoint: "n/a",
        router: "n/a",
        plug: "n/a",
        action: "n/a",
        router_helper: nil,
        class: "disconnected"
      }
    })
  end

  defp assign_toolbar(socket, profile) do
    %{metrics: metrics} = profile

    socket
    |> apply_request(profile)
    |> assign(:durations, %{
      total: duration(metrics.total_duration),
      endpoint: duration(metrics.endpoint_duration),
      latest_event: nil
    })
    |> assign(:memory, memory(metrics.memory))
  end

  defp apply_request(socket, profile) do
    %{conn: %Plug.Conn{} = conn} = profile
    router = conn.private[:phoenix_router]
    {helper, plug, action} = Routes.info(conn)
    socket = %{socket | private: Map.put(socket.private, :phoenix_router, router)}

    assign(socket, :request, %{
      status_code: conn.status,
      status_phrase: Plug.Conn.Status.reason_phrase(conn.status),
      endpoint: inspect(Phoenix.Controller.endpoint_module(conn)),
      router: inspect(router),
      plug: inspect(plug),
      action: inspect(action),
      router_helper: helper,
      class: request_class(conn.status)
    })
  end

  defp apply_navigation(socket, %{router: router} = route) do
    socket
    |> update(:root_pid, fn _ -> route.root_pid end)
    |> update(:request, fn req ->
      {helper, plug, action} = Routes.info(router, route)

      %{req | plug: inspect(plug), action: inspect(action), router_helper: helper}
    end)
  end

  defp duration(duration) when is_integer(duration) do
    duration = System.convert_time_unit(duration, :native, :microsecond)

    if duration > 1000 do
      value = duration |> div(1000) |> Integer.to_string()
      %{value: value, label: "ms", phrase: "#{value} milliseconds"}
    else
      value = Integer.to_string(duration)
      %{value: value, label: "µs", phrase: "#{value} microseconds"}
    end
  end

  defp duration(_), do: nil

  defp memory(memory) do
    if memory > 1024 do
      value = memory |> div(1024) |> Integer.to_string()
      %{value: value, label: "MiB", phrase: "#{value} mebibytes"}
    else
      value = Integer.to_string(memory)
      %{value: value, label: "KiB", phrase: "#{value} kibibytes"}
    end
  end

  defp request_class(code) when is_integer(code) do
    case code do
      code when code >= 200 and code < 300 -> :green
      code when code >= 400 and code < 500 -> :red
      code when code >= 500 and code < 600 -> :red
      _ -> nil
    end
  end

  defp subscribe(socket) do
    if connected?(socket) do
      subscribe(socket, socket.transport_pid)
    else
      socket
    end
  end

  defp subscribe(socket, transport_pid) do
    # todo: stop retrying after a resonable amount of time (proabably not a LiveView).
    case PhoenixProfiler.Server.subscribe(transport_pid) do
      {:ok, _token} -> :ok
      :error -> Process.send_after(self(), {:subscribe, transport_pid}, 1000)
    end

    socket
  end

  @impl Phoenix.LiveView
  def handle_info({:subscribe, transport_pid}, socket) do
    socket =
      if socket.transport_pid == transport_pid,
        do: subscribe(socket, transport_pid),
        else: socket

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {PhoenixProfiler.Server, _token,
         {:telemetry, [:phoenix, :live_view, _, _] = event, _time, data}},
        socket
      ) do
    [_, _, stage, action] = event

    socket =
      socket
      |> maybe_apply_navigation(data)
      |> apply_lifecycle(stage, action, data)
      |> apply_event_duration(stage, action, data)

    {:noreply, socket}
  end

  def handle_info(other, socket) do
    Logger.debug("ToolbarLive received an unknown message: #{inspect(other)}")
    {:noreply, socket}
  end

  defp maybe_apply_navigation(socket, data) do
    if connected?(socket) and not is_nil(data.router) and
         socket.assigns.root_pid != data.root_pid do
      apply_navigation(socket, data)
    else
      socket
    end
  end

  defp apply_lifecycle(socket, _stage, :exception, data) do
    %{kind: kind, reason: reason, stacktrace: stacktrace} = data

    exception = %{
      ref: Phoenix.LiveView.Utils.random_id(),
      reason: Exception.format(kind, reason, stacktrace),
      at: Time.utc_now() |> Time.truncate(:second)
    }

    socket
    |> update(:exits, &[exception | &1])
    |> update(:exits_count, &(&1 + 1))
  end

  defp apply_lifecycle(socket, _stage, _action, _data) do
    socket
  end

  defp apply_event_duration(socket, stage, :stop, %{duration: duration})
       when stage in [:handle_event, :handle_params] do
    update(socket, :durations, fn durations ->
      durations = durations || %{total: nil, endpoint: nil, latest_event: nil}
      %{durations | latest_event: duration(duration)}
    end)
  end

  defp apply_event_duration(socket, _stage, _action, _measurements) do
    socket
  end

  defp current_duration(durations) do
    if event = durations.latest_event,
      do: {event.value, event.label},
      else: {durations.total.value, durations.total.label}
  end
end
