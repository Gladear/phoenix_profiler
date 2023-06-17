defmodule PhoenixProfiler.Elements.MemoryUsage do
  use PhoenixProfiler.Element

  @impl PhoenixProfiler.Element
  def render(assigns) do
    ~H"""
    <div>
      <.element :if={@memory} aria-label={"Memory, #{@memory.phrase}"}>
        <:item>
          <%= @memory.value %>
          <.label><%= @memory.label %></.label>
        </:item>

        <:details>
          <.item>
            <:label>Memory</:label>
            <:value><%= @memory.value %> <%= @memory.label %></:value>
          </.item>
        </:details>
      </.element>
    </div>
    """
  end

  @impl PhoenixProfiler.Element
  def subscribed_events, do: [[:phxprof, :plug, :stop]]

  @impl PhoenixProfiler.Element
  def collect([:phxprof, :plug, :stop], _measurements, _metadata) do
    %{memory: process_memory(self())}
  end

  @kB 1_024
  defp process_memory(pid) when is_pid(pid) do
    {:memory, bytes} = Process.info(pid, :memory)
    div(bytes, @kB)
  end

  @impl PhoenixProfiler.Element
  def entries_assigns([], current_assigns) do
    Enum.into(current_assigns, %{memory: nil})
  end

  def entries_assigns(entries, _current_assigns) do
    [%{memory: memory} | _] = entries

    %{memory: formatted_memory(memory)}
  end

  defp formatted_memory(memory) do
    if memory > 1024 do
      value = memory |> div(1024) |> Integer.to_string()
      %{value: value, label: "MiB", phrase: "#{value} mebibytes"}
    else
      value = Integer.to_string(memory)
      %{value: value, label: "KiB", phrase: "#{value} kibibytes"}
    end
  end
end
