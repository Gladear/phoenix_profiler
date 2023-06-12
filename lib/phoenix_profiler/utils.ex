defmodule PhoenixProfiler.Utils do
  @moduledoc false
  alias Phoenix.LiveView

  @doc "Returns the owner pid of a given `conn` or `socket`."
  def owner_pid(%Plug.Conn{} = conn), do: conn.owner
  def owner_pid(%LiveView.Socket{} = socket), do: socket.transport_pid

  @doc "Returns the endpoint for a given `conn` or `socket`."
  def conn_or_socket_endpoint(%Plug.Conn{} = conn), do: conn.private.phoenix_endpoint
  def conn_or_socket_endpoint(%LiveView.Socket{endpoint: endpoint}), do: endpoint

  @doc "Get the config of a given `conn` or `socket`."
  def conn_or_socket_config(conn_or_socket) do
    conn_or_socket
    |> conn_or_socket_endpoint()
    |> profiler_config()
  end

  @doc "Get the config of a given Phoenix endpoint."
  def profiler_config(endpoint) do
    endpoint.config(:phoenix_profiler, [])
  end

  @doc """
  Assigns a new private key and value in the socket.
  """
  def put_private(%Plug.Conn{} = conn, key, value) when is_atom(key) do
    Plug.Conn.put_private(conn, key, value)
  end

  def put_private(%LiveView.Socket{private: private} = socket, key, value) when is_atom(key) do
    %{socket | private: Map.put(private, key, value)}
  end

  # Unique ID generation
  # Copyright (c) 2013 Plataformatec.
  # https://github.com/elixir-plug/plug/blob/fb6b952cf93336dc79ec8d033e09a424d522ce56/lib/plug/request_id.ex
  def generate_token do
    binary =
      <<System.system_time(:nanosecond)::64, :erlang.phash2({node(), self()}, 16_777_216)::24,
        :erlang.unique_integer()::32>>

    Base.url_encode64(binary)
  end
end
