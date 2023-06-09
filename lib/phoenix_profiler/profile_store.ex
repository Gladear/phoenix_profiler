defmodule PhoenixProfiler.ProfileStore do
  # Helpers for fetching profile data from local and remote nodes.
  @moduledoc false
  alias PhoenixProfiler.Profile

  @doc """
  Returns the profile for a given `token` if it exists.
  """
  def get(token) do
    case PhoenixProfiler.Server.lookup_entries(token) do
      [] ->
        nil

      entries ->
        Enum.reduce(entries, %{metrics: %{endpoint_duration: nil}}, fn
          {^token, _event, _event_ts, %{endpoint_duration: duration}}, acc ->
            %{acc | metrics: Map.put(acc.metrics, :endpoint_duration, duration)}

          {^token, _event, _event_ts, %{metrics: _} = entry}, acc ->
            {metrics, rest} = Map.pop!(entry, :metrics)
            acc = Map.merge(acc, rest)
            %{acc | metrics: Map.merge(acc.metrics, metrics)}

          {^token, _event, _event_ts, data}, acc ->
            Map.merge(acc, data)
        end)
    end
  end

  @doc """
  Fetches a profile on a remote node.
  """
  def remote_get(%Profile{} = profile) do
    :rpc.call(profile.node, __MODULE__, :get, [profile.token])
  end
end
