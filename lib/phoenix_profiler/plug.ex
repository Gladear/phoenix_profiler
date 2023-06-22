defmodule PhoenixProfiler.Plug do
  @moduledoc false
  import Plug.Conn

  alias PhoenixProfiler.Profiler
  alias PhoenixProfiler.ToolbarLive
  alias PhoenixProfiler.Utils

  @phxprof_token_header "x-phxprof-token"
  @phxprof_token_param "_phxprof_token"

  def init(opts) do
    opts
  end

  # TODO: remove this clause when we add config for profiler except_patterns
  def call(%Plug.Conn{path_info: ["phoenix", "live_reload", "frame" | _suffix]} = conn, _) do
    # this clause is to ignore the phoenix live reload iframe in case someone installs
    # the toolbar plug above the LiveReloader plug in their Endpoint.
    conn
  end

  def call(conn, _opts) do
    if Profiler.enabled?(conn) do
      token = conn_token(conn)

      conn
      |> Profiler.enable(token)
      |> before_send_profile()
    else
      conn
    end
  end

  defp conn_token(conn) do
    case get_req_header(conn, @phxprof_token_header) do
      [] -> nil
      [token | _] -> token
    end
  end

  defp before_send_profile(conn) do
    register_before_send(conn, fn conn ->
      with %{phoenix_profiler: profile} <- conn.private do
        duration = System.monotonic_time() - profile.start_time
        :telemetry.execute([:phxprof, :plug, :stop], %{duration: duration}, %{conn: conn})

        maybe_inject_debug_toolbar(conn)
      else
        _ ->
          conn
      end
    end)
  end

  defp maybe_inject_debug_toolbar(conn) do
    if has_resp_body?(conn) and html?(conn) do
      inject_debug_toolbar(conn)
    else
      conn
    end
  end

  defp has_resp_body?(conn), do: conn.resp_body != nil

  defp html?(conn) do
    case get_resp_header(conn, "content-type") do
      [] -> false
      [type | _] -> String.starts_with?(type, "text/html")
    end
  end

  # HTML Injection
  # Copyright (c) 2018 Chris McCord
  # https://github.com/phoenixframework/phoenix_live_reload/blob/564ab19d54f2476a6c43d43beeb3ed2807f453c0/lib/phoenix_live_reload/live_reloader.ex#L129
  defp inject_debug_toolbar(conn) do
    endpoint = conn.private.phoenix_endpoint

    resp_body = IO.iodata_to_binary(conn.resp_body)

    if has_body_tag?(resp_body) and Code.ensure_loaded?(endpoint) do
      {head, [last]} = Enum.split(String.split(resp_body, "</body>"), -1)
      head = Enum.intersperse(head, "</body>")
      body = [head, debug_toolbar_assets_tag(conn), "</body>" | last]
      put_in(conn.resp_body, body)
    else
      conn
    end
  end

  defp has_body_tag?(resp_body), do: String.contains?(resp_body, "<body")

  defp debug_toolbar_assets_tag(conn) do
    try do
      config = Utils.conn_or_socket_config(conn)

      toolbar_attrs = Keyword.get(config, :toolbar_attrs, [])
      profile = conn.private.phoenix_profiler

      attrs =
        Keyword.merge(
          toolbar_attrs,
          class: "phxprof-toolbar",
          "data-token": profile.token,
          role: "region",
          name: "Phoenix Web Debug Toolbar"
        )

      ToolbarLive.toolbar(%{
        conn: conn,
        session: %{"_phxprof" => profile},
        profile: profile,
        toolbar_attrs: attrs
      })
      |> Phoenix.HTML.Safe.to_iodata()
    catch
      {kind, reason} ->
        IO.puts(Exception.format(kind, reason, __STACKTRACE__))
        []
    end
  end

  @doc false
  def on_mount(_arg, _params, _session, socket) do
    socket =
      if Phoenix.LiveView.connected?(socket) and Profiler.enabled?(socket) do
        Profiler.enable(socket, socket_token(socket))
      else
        socket
      end

    {:cont, socket}
  end

  defp socket_token(socket) do
    socket
    |> Phoenix.LiveView.get_connect_params()
    |> Map.get(@phxprof_token_param, nil)
  end
end
