defmodule PhoenixProfiler.Profiler do
  @moduledoc false
  alias PhoenixProfiler.Profile
  alias PhoenixProfiler.Server
  alias PhoenixProfiler.Utils

  @doc """
  Verifies if the profiler is enabled on a given `conn` or `socket`.
  """
  @spec enabled?(receiver) :: boolean() when receiver: Plug.Conn.t() | Phoenix.Socket.t()
  def enabled?(conn_or_socket) do
    config = Utils.conn_or_socket_config(conn_or_socket)
    Keyword.get(config, :enabled?,  true)
  end

  @doc """
  Enables the profiler on a given `conn` or `socket`.

  For a LiveView socket, raises if the socket is not connected.
  """
  @spec enable(receiver, token :: String.t()) :: receiver
        when receiver: Plug.Conn.t() | Phoenix.Socket.t()
  def enable(conn_or_socket, token \\ nil) do
    ensure_connected_socket!(conn_or_socket)

    if profile_set?(conn_or_socket) do
      conn_or_socket
    else
      observable_token = Server.add_observable(token)
      new_profile(conn_or_socket, observable_token)
    end
  end

  defp ensure_connected_socket!(%Phoenix.LiveView.Socket{} = socket) do
    if Phoenix.LiveView.connected?(socket) do
      :ok
    else
      raise """
      attempted to enable profiling on a disconnected socket

      In your LiveView mount callback, do the following:

          socket =
            if connected?(socket) do
              PhoenixProfiler.enable(socket)
            else
              socket
            end

      """
    end
  end

  defp ensure_connected_socket!(_), do: :ok

  defp profile_set?(conn_or_socket) do
    match?(%{:phoenix_profiler => %Profile{}}, conn_or_socket.private)
  end

  defp new_profile(conn_or_socket, token) do
    profile = Profile.new(token)

    Utils.put_private(conn_or_socket, :phoenix_profiler, profile)
  end
end
