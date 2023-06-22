defmodule PhoenixProfiler.Profile do
  # An internal data structure for a request profile.
  @moduledoc false
  defstruct [:token]

  @type t :: %__MODULE__{
          :token => String.t()
        }

  @doc """
  Returns a new profile.
  """
  def new(token) when is_binary(token) do
    %__MODULE__{token: token}
  end
end
