defmodule PhoenixProfiler.Elements.Request do
  use PhoenixProfiler.Element

  @impl PhoenixProfiler.Element
  def render(assigns) do
    ~H"""
    <.element aria-label={"Status, #{@status_phrase}"}>
      <:status color={@status_class}>
        <%= if @status_code == ":|" do %>
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
          <%= @status_code %>
        <% end %>
      </:status>

      <:item>
        <.label>@</.label>
        <%= @router_helper %>
      </:item>

      <:details>
        <.item>
          <:label>HTTP status</:label>
          <:value><%= @status_code %> <%= @status_phrase %></:value>
        </.item>
        <.item>
          <:label>Plug</:label>
          <:value><%= @plug %></:value>
        </.item>
        <.item>
          <:label>Route action</:label>
          <:value><%= @action %></:value>
        </.item>
        <.item>
          <:label>Router</:label>
          <:value><%= @router %></:value>
        </.item>
        <.item>
          <:label>Endpoint</:label>
          <:value><%= @endpoint %></:value>
        </.item>
      </:details>
    </.element>
    """
  end

  @impl PhoenixProfiler.Element
  def subscribed_events, do: [[:phoenix, :endpoint, :stop]]

  @impl PhoenixProfiler.Element
  def collect([:phoenix, :endpoint, :stop], _measurements, metadata) do
    %{conn: metadata.conn}
  end

  @impl PhoenixProfiler.Element
  def entries_assigns(entries) do
    [%{conn: conn} | _] = entries

    router = conn.private[:phoenix_router]
    {helper, plug, action} = conn_info(conn)

    %{
      status_phrase: Plug.Conn.Status.reason_phrase(conn.status),
      status_class: request_class(conn.status),
      status_code: conn.status,
      router_helper: helper,
      plug: inspect(plug),
      action: inspect(action),
      router: inspect(router),
      endpoint: inspect(conn.private.phoenix_endpoint)
    }
  end

  defp request_class(code) when is_integer(code) do
    case code do
      code when code >= 200 and code < 300 -> :green
      code when code >= 400 and code < 500 -> :red
      code when code >= 500 and code < 600 -> :red
      _ -> nil
    end
  end

  @route_not_found {:route_not_found, nil, nil}
  @router_not_set {:router_not_set, nil, nil}

  # Returns route information from the given `conn`.
  #
  # If no router is set on the conn, returns `@router_not_set`.
  # If the route cannot be determined, returns `@route_not_found`.
  #
  # Otherwise, this function returns a tuple of `{helper, plug_or_live_view, action_or_plug_opts}`.
  defp conn_info(%Plug.Conn{private: %{phoenix_router: router}} = conn) do
    with {:ok, route_info} <- fetch_route_info(router, conn),
         {:ok, routes} <- fetch_routes(router),
         {:ok, route} <- find_route_within_routes(route_info, routes) do
      {route.helper, route.plug, route.plug_opts}
    end
  end

  defp conn_info(%Plug.Conn{}), do: @router_not_set

  defp fetch_route_info(router, conn) do
    case Phoenix.Router.route_info(router, conn.method, conn.request_path, conn.host) do
      %{} = route_info -> {:ok, route_info}
      :error -> @route_not_found
    end
  end

  defp fetch_routes(router) do
    case Phoenix.Router.routes(router) do
      [] -> @route_not_found
      routes -> {:ok, routes}
    end
  end

  defp find_route_within_routes(route_info, routes) do
    if route = Enum.find(routes, &same_route?(&1, route_info)),
      do: {:ok, route},
      else: @route_not_found
  end

  defp same_route?(route, route_info) do
    route.path == route_info.route and
      route.plug == route_info.plug and
      route.plug_opts == route_info.plug_opts
  end
end
