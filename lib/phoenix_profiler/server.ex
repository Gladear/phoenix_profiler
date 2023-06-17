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
      elements_by_event:
        elements
        |> Map.new(&{&1, &1.subscribed_events()})
        |> elements_by_event()
    }

    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  # Reverse the map so we can look up module by events.
  #
  # Example:
  #
  #     iex> elements_by_event(%{MyModule => [[:phxprof, :plug, :stop]]})
  #     %{[:phxprof, :plug, :stop] => [MyModule]}
  #
  defp elements_by_event(events) do
    Enum.reduce(events, %{}, fn {key, values}, acc ->
      Enum.reduce(values, acc, fn value, acc ->
        Map.update(acc, value, [key], fn list -> [key | list] end)
      end)
    end)
  end

  @doc """
  Makes the caller observable by listeners.
  """
  @spec add_observable(token | nil) :: token when token: binary()
  def add_observable(token \\ nil) do
    token = token || Utils.generate_token()
    put_token(token)
    token
  end

  @doc """
  Subscribes the `owner` to the given token.
  """
  @spec subscribe(owner :: pid(), token :: binary()) :: :ok
  def subscribe(owner, token) when is_pid(owner) do
    GenServer.cast(__MODULE__, {:subscribe, owner, token})
  end

  defp subscribers(token) do
    GenServer.call(__MODULE__, {:subscribers, token})
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
  def init(%{elements_by_event: elements_by_event}) do
    events = Map.keys(elements_by_event)

    :ets.new(@entry_table, [:named_table, :public, :duplicate_bag])

    :telemetry.attach_many(
      {__MODULE__, self()},
      events,
      &__MODULE__.handle_execute/4,
      %{elements_by_event: elements_by_event}
    )

    {:ok, %{subscribers: %{}}}
  end

  @impl GenServer
  def handle_call({:subscribers, token}, _from, state) do
    {:reply, Map.get(state.subscribers, token, []), state}
  end

  @impl GenServer
  def handle_cast({:subscribe, owner, token}, state) do
    new_subscribers = Map.update(state.subscribers, token, [owner], fn list -> [owner | list] end)

    {:noreply, %{state | subscribers: new_subscribers}}
  end

  # Insert the event into the entry table
  def handle_execute(event, measurements, metadata, %{elements_by_event: elements_by_event}) do
    with false <- library_event?(event, metadata),
         {:ok, token} <- fetch_token() do
      elements = elements_by_event[event]

      entries =
        Enum.map(elements, fn element ->
          {token, element, element.collect(event, measurements, metadata)}
        end)

      put_entries(entries)
      notify_subscribers(token, entries)
    end
  end

  defp library_event?([:phoenix, :live_view | _], metadata) do
    match?(%{session: %{"_phxprof" => _}}, metadata)
  end

  defp library_event?(_event, _metadata), do: false

  defp notify_subscribers(token, new_entries) do
    subscribers(token)
    |> Enum.each(fn subscriber ->
      send(subscriber, {:entries, new_entries})
    end)
  end

  @impl GenServer
  def terminate(_reason, _state) do
    :telemetry.detach({__MODULE__, self()})
    :ok
  end
end
