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
    elements = Utils.elements()

    config = %{
      modules_by_event:
        elements
        |> Map.new(&{&1, &1.subscribed_events()})
        |> modules_by_event()
    }

    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  # Reverse the map so we can look up module by events.
  #
  # Example:
  #
  #     iex> modules_by_event(%{MyModule => [[:phxprof, :plug, :stop]]})
  #     %{[:phxprof, :plug, :stop] => [MyModule]}
  #
  defp modules_by_event(events) do
    Enum.reduce(events, %{}, fn {key, values}, acc ->
      Enum.reduce(values, acc, fn value, acc ->
        Map.update(acc, value, [key], fn list -> [key | list] end)
      end)
    end)
  end

  @doc """
  Makes the caller observable by listeners.
  """
  @spec observe(owner :: pid()) :: token :: binary()
  def observe(owner) when is_pid(owner) do
    token = GenServer.call(__MODULE__, {:observe, owner})
    put_token(token)
    token
  end

  @doc """
  Returns all entries for the given token.
  """
  @spec get_entries(token :: binary()) :: [{token :: binary(), module :: module(), data :: any()}]
  def get_entries(token) do
    :ets.lookup(@entry_table, token)
  end

  # Insert entries into the entry table.
  # The entries must be a tuple starting with the token.
  defp put_entries(entries) do
    :ets.insert(@entry_table, entries)
  end

  @process_token_key :phoenix_profiler_token

  defp put_token(token) do
    Process.put(@process_token_key, token)
  end

  defp fetch_token do
    if token = Process.get(@process_token_key),
      do: {:ok, token},
      else: :not_found
  end

  @impl GenServer
  def init(%{modules_by_event: modules_by_event}) do
    events = Map.keys(modules_by_event)

    :ets.new(@entry_table, [:named_table, :public, :duplicate_bag])

    :telemetry.attach_many(
      {__MODULE__, self()},
      events,
      &__MODULE__.handle_execute/4,
      %{modules_by_event: modules_by_event}
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
  def handle_execute(event, measurements, metadata, %{modules_by_event: modules_by_event}) do
    modules = modules_by_event[event]

    with {:ok, token} <- fetch_token() do
      entries =
        Enum.map(modules, fn module ->
          {token, module, module.collect(event, measurements, metadata)}
        end)

      put_entries(entries)
    end
  end

  @impl GenServer
  def terminate(_reason, _state) do
    :telemetry.detach({__MODULE__, self()})
    :ok
  end
end
