defmodule PhoenixProfiler.Server do
  @moduledoc false
  use GenServer

  alias PhoenixProfiler.Utils

  # token -> event, data
  @entry_table __MODULE__.Entry

  @doc """
  Starts a telemetry server linked to the current process.
  """
  def start_link(_opts) do
    config = %{
      filter: &PhoenixProfiler.Telemetry.collect/4,
      events: PhoenixProfiler.Telemetry.events()
    }

    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @process_dict_key :phoenix_profiler_token

  @doc """
  Returns the profile for a given `token` if it exists.
  """
  def get_profile(token) do
    case :ets.lookup(@entry_table, token) do
      [] ->
        nil

      entries ->
        Enum.reduce(entries, %{metrics: %{endpoint_duration: nil}}, fn
          {^token, _event, %{endpoint_duration: duration}}, acc ->
            %{acc | metrics: Map.put(acc.metrics, :endpoint_duration, duration)}

          {^token, _event, %{metrics: _} = entry}, acc ->
            {metrics, rest} = Map.pop!(entry, :metrics)
            acc = Map.merge(acc, rest)
            %{acc | metrics: Map.merge(acc.metrics, metrics)}

          {^token, _event, data}, acc ->
            Map.merge(acc, data)
        end)
    end
  end

  @doc """
  Makes the caller observable by listeners.
  """
  @spec observe(owner :: pid()) :: token :: binary()
  def observe(owner) when is_pid(owner) do
    token = GenServer.call(__MODULE__, {:observe, owner})
    Process.put(@process_dict_key, token)
    token
  end

  @impl GenServer
  def init(%{events: events, filter: filter}) do
    :ets.new(@entry_table, [:named_table, :public, :duplicate_bag])

    :telemetry.attach_many(
      {__MODULE__, self()},
      events,
      &__MODULE__.handle_execute/4,
      %{filter: filter}
    )

    {:ok, %{observers: %{}}}
  end

  @impl GenServer
  def handle_call({:observe, owner}, _from, state) do
    token =
      if found_token = Map.get(state.observers, owner),
        do: found_token,
        else: Utils.generate_token()

    {:reply, token, put_in(state.observers[owner], token)}
  end

  # Insert the event into the entry table
  def handle_execute(event, measurements, metadata, %{filter: filter}) do
    with token when not is_nil(token) <- Process.get(@process_dict_key),
         {:keep, data} <- filter_event(filter, _arg = nil, event, measurements, metadata) do
      :ets.insert(@entry_table, {token, event, data})
    else
      _ -> :ok
    end
  end

  defp filter_event(filter, arg, event, measurements, metadata) do
    # todo: rescue/catch, detach telemetry, and warn on error
    case filter.(arg, event, measurements, metadata) do
      :keep -> {:keep, nil}
      {:keep, %{}} = keep -> keep
      :skip -> :skip
    end
  end

  @impl GenServer
  def terminate(_reason, _state) do
    :telemetry.detach({__MODULE__, self()})
    :ok
  end
end
