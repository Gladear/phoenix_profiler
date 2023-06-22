defmodule PhoenixProfiler.Server do
  @moduledoc false
  use GenServer

  alias PhoenixProfiler.Utils

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
  #     iex> elements_by_event(%{MyModule => [[:phoenix, :endpoint, :stop]]})
  #     %{[:phoenix, :endpoint, :stop] => [MyModule]}
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

  @doc """
  Returns all entries for the given token.
  """
  @spec get_entries(token :: binary()) :: [{token :: binary(), module :: module(), data :: any()}]
  def get_entries(token) do
    GenServer.call(__MODULE__, {:get_entries, token})
  end

  @process_token_key :phoenix_profiler_token

  defp put_token(token) do
    Process.put(@process_token_key, token)
  end

  # Find the token in the call stack
  #
  # The main process may have spawned another process or task that won't have the token
  # in its dictionary. This function will traverse the "process call stack" to find the
  # original token.
  defp fetch_token do
    callers = [self() | Process.get(:"$callers", [])]

    Enum.find_value(callers, :not_found, fn caller ->
      with {:dictionary, dict} <- Process.info(caller, :dictionary),
           token when is_binary(token) <- dict[@process_token_key] do
        {:ok, token}
      end
    end)
  end

  # Telemetry event handler
  @doc false
  def handle_execute(event, measurements, metadata, _config) do
    with false <- library_event?(event, metadata),
         {:ok, token} <- fetch_token() do
      GenServer.cast(__MODULE__, {:store_event, token, event, measurements, metadata})
    end
  end

  defp library_event?([:phoenix, :live_view | _], metadata) do
    match?(%{session: %{"_phxprof" => _}}, metadata)
  end

  defp library_event?(_event, _metadata), do: false

  @impl GenServer
  def init(%{elements_by_event: elements_by_event}) do
    events = Map.keys(elements_by_event)

    :telemetry.attach_many(
      {__MODULE__, self()},
      events,
      &__MODULE__.handle_execute/4,
      nil
    )

    {:ok, %{elements_by_event: elements_by_event, subscribers: %{}, entries: %{}}}
  end

  @impl GenServer
  def handle_call({:get_entries, token}, _from, state) do
    {:reply, Map.get(state.entries, token, []), state}
  end

  @impl GenServer
  def handle_cast({:subscribe, owner, token}, state) do
    new_subscribers = Map.update(state.subscribers, token, [owner], fn list -> [owner | list] end)

    {:noreply, %{state | subscribers: new_subscribers}}
  end

  def handle_cast({:store_event, token, event, measurements, metadata}, state) do
    elements = Map.fetch!(state.elements_by_event, event)

    event_entries =
      Enum.map(elements, fn element ->
        {element, element.collect(event, measurements, metadata)}
      end)

    {entries, updated_state} =
      get_and_update_in(state.entries[token], fn entries ->
        all_entries = (entries || []) ++ event_entries
        {all_entries, all_entries}
      end)

    Map.get(state.subscribers, token, [])
    |> notify_subscribers(entries)

    {:noreply, updated_state}
  end

  defp notify_subscribers(subscribers, entries) do
    Enum.each(subscribers, fn subscriber ->
      send(subscriber, {:entries, entries})
    end)
  end

  @impl GenServer
  def terminate(_reason, _state) do
    :telemetry.detach({__MODULE__, self()})
    :ok
  end
end
