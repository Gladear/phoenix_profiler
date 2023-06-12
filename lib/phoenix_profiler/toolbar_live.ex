defmodule PhoenixProfiler.ToolbarLive do
  # The LiveView for the Web Debug Toolbar
  @moduledoc false
  use Phoenix.LiveView, container: {:div, [class: "phxprof-toolbar-view"]}

  require Logger

  alias PhoenixProfiler.Elements
  alias PhoenixProfiler.ProfileStore
  alias PhoenixProfiler.Routes

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
        <button class="show-button" type="button" id={"phxprof-toolbar-show-#{@profile.token}"} title="Show Toolbar" accesskey="D" aria-expanded="true" aria-controls={"phxprof-toolbar-main-#{@profile.token}"}>
        </button>
      </div>
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
    <Elements.Request.render request={@request} />
    <Elements.RequestDuration.render durations={@durations} />
    <Elements.MemoryUsage.render memory={@memory} />
    <Elements.LiveExceptions.render exits={@exits} exits_count={@exits_count} />

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
    <button class="hide-button" type="button" title="Hide Toolbar" accesskey="D" aria-expanded="true" aria-controls={"phxprof-toolbar-main-#{@token}"}>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
      </svg>
    </button>
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
end
