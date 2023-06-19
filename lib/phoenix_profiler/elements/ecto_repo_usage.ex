if Code.ensure_loaded?(Ecto) do
  defmodule PhoenixProfiler.Elements.EctoRepoUsage do
    use PhoenixProfiler.Element

    @impl PhoenixProfiler.Element
    def render(assigns) do
      ~H"""
      <.element aria-label={"Queries, #{@duration.phrase}"}>
        <:item>
          <%= @count %>
          <.label>in</.label>
          <%= @duration.value %>
          <.label><%= @duration.label %></.label>
        </:item>

        <:details>
          <.item>
            <:label>Database Queries</:label>
            <:value><%= @count %></:value>
          </.item>
          <.item>
            <:label>Different statements</:label>
            <:value><%= @unique_queries %></:value>
          </.item>
          <.item>
            <:label>Total time</:label>
            <:value><%= @duration.value %> <%= @duration.label %></:value>
          </.item>
          <.item>
            <:label>Source</:label>
            <:value><span title={@source.long}><%= @source.compact %>, &hellip;</span></:value>
          </.item>
          <.item>
            <:label>Repo</:label>
            <:value><span title={@repo.long}><%= @repo.compact %>, &hellip;</span></:value>
          </.item>
        </:details>
      </.element>
      """
    end

    @impl PhoenixProfiler.Element
    def subscribed_events do
      Application.get_env(:phoenix_profiler, :ecto_repos, [])
      |> Enum.map(&telemetry_event/1)
    end

    defp telemetry_event(repo) do
      telemetry_prefix =
        Keyword.get_lazy(repo.config(), :telemetry_prefix, fn -> telemetry_prefix(repo) end)

      telemetry_prefix ++ [:query]
    end

    defp telemetry_prefix(repo) do
      repo
      |> Module.split()
      |> Enum.map(&(&1 |> Macro.underscore() |> String.to_atom()))
    end

    @impl PhoenixProfiler.Element
    def collect([_app, _repo, :query], measurements, metadata) do
      # Available metrics in `measurements`:
      # :idle_time - the time the connection spent waiting before being checked out for the query
      # :queue_time - the time spent waiting to check out a database connection
      # :query_time - the time spent executing the query
      # :decode_time - the time spent decoding the data received from the database
      # :total_time - the sum of (queue_time, query_time, and decode_time)️

      %{
        measurements: measurements,
        query: metadata.query,
        source: metadata.source,
        repo: metadata.repo
      }
    end

    @impl PhoenixProfiler.Element
    def entries_assigns(entries) do
      count = Enum.count(entries)
      unique_queries = entries |> Stream.uniq_by(& &1.query) |> Enum.count()
      total_duration = entries |> Stream.map(& &1.measurements.total_time) |> Enum.sum()

      %{
        count: count,
        unique_queries: unique_queries,
        duration: formatted_duration(total_duration),
        source: format_frequencies(entries, & &1.source),
        repo: format_frequencies(entries, & &1.repo)
      }
    end

    defp formatted_duration(nil), do: nil

    defp formatted_duration(duration) when is_integer(duration) do
      duration = System.convert_time_unit(duration, :native, :microsecond)

      if duration > 1000 do
        value = duration |> div(1000) |> Integer.to_string()
        %{value: value, label: "ms", phrase: "#{value} milliseconds"}
      else
        value = Integer.to_string(duration)
        %{value: value, label: "µs", phrase: "#{value} microseconds"}
      end
    end

    defp format_frequencies(entries, callback) do
      entries_count =
        entries
        |> Enum.frequencies_by(callback)
        |> Enum.sort_by(&elem(&1, 1), :desc)

      long_label =
        Enum.map_join(entries_count, ", ", fn {key, value} -> "#{inspect(key)} (#{value})" end)

      compact_label =
        if first = List.first(entries_count) do
          first
          |> elem(0)
          |> inspect()
        else
          "N/A"
        end


      %{long: long_label, compact: compact_label}
    end
  end
end
