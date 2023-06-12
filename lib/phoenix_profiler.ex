defmodule PhoenixProfiler do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.fetch!(1)

  @behaviour Plug

  @impl Plug
  defdelegate init(opts), to: PhoenixProfiler.Plug

  @impl Plug
  defdelegate call(conn, opts), to: PhoenixProfiler.Plug

  @doc false
  defdelegate on_mount(args, params, session, socket), to: PhoenixProfiler.Plug
end
