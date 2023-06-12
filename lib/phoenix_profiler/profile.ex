defmodule PhoenixProfiler.Profile do
  # An internal data structure for a request profile.
  @moduledoc false
  defstruct [
    :endpoint,
    :start_time,
    :system,
    :token
  ]

  @type system :: %{
          :otp => String.t(),
          :elixir => String.t(),
          :phoenix => String.t(),
          :phoenix_profiler => String.t(),
          required(atom()) => nil | String.t()
        }

  @type t :: %__MODULE__{
          :endpoint => module(),
          :token => String.t(),
          :start_time => integer(),
          :system => system()
        }

  @doc """
  Returns a new profile.
  """
  def new(endpoint, token) when is_atom(endpoint) and is_binary(token) do
    %__MODULE__{
      token: token,
      endpoint: endpoint,
      system: system(),
      start_time: System.monotonic_time()
    }
  end

  # Returns a map of system version metadata.
  defp system do
    system_versions = %{
      elixir: System.version(),
      otp: System.otp_release()
    }

    deps_versions =
      for app <- [:phoenix, :phoenix_live_view, :phoenix_profiler], into: %{} do
        {app, Application.spec(app)[:vsn]}
      end

    Map.merge(system_versions, deps_versions)
  end
end
