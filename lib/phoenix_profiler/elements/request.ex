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

  # Copy-pasta from PhoenixProfiler.Routes

  @route_not_found {:route_not_found, nil, nil}
  @router_not_set {:router_not_set, nil, nil}

  @doc """
  Returns route information from the given `conn`.

  If no router is set on the conn, returns `#{inspect(@router_not_set)}`.

  If the route cannot be determined, returns `#{inspect(@route_not_found)}`.

  Otherwise, this function returns a tuple of `{helper, plug_or_live_view, action_or_plug_opts}`.
  """

  def info(%Plug.Conn{private: %{phoenix_router: router}} = conn) do
    case route_info(router, conn.method, conn.request_path, conn.host) do
      :error -> @route_not_found
      route_info -> info(router, route_info)
    end
  end

  def info(%Plug.Conn{}), do: @router_not_set

  @doc """
  Returns information about the given route.

  See `info/2`.
  """
  def info(router, route_info)

  def info(nil, _), do: @router_not_set

  def info(router, route_info) when is_atom(router) do
    case routes(router) do
      :error -> @route_not_found
      routes -> match_router_helper(routes, route_info)
    end
  end

  defp match_router_helper([], _), do: @route_not_found

  defp match_router_helper(routes, route_info) when is_list(routes) do
    Enum.find_value(routes, @route_not_found, &route(&1, route_info))
  end

  defp route_info(router, method, request_path, host) do
    Phoenix.Router.route_info(router, method, request_path, host)
  end

  defp routes(router) do
    Phoenix.Router.routes(router)
  end

  # route_info from LiveView telemetry
  defp route(
         %{metadata: %{phoenix_live_view: {lv, action, _opts, _extra}}} = route,
         %{root_pid: _, root_view: lv, live_action: action}
       ) do
    {route.helper, lv, route.plug_opts}
  end

  # Live route
  defp route(
         %{path: path, metadata: %{phoenix_live_view: {lv, action, _, _}}} = route,
         %{route: path, phoenix_live_view: {lv, action, _, _}}
       ) do
    {route.helper, lv, route.plug_opts}
  end

  # Plug route
  defp route(
         %{path: path, plug: plug, plug_opts: plug_opts} = route,
         %{route: path, plug: plug, plug_opts: plug_opts}
       ) do
    {route.helper, plug, plug_opts}
  end

  defp route(_, _), do: nil
end
