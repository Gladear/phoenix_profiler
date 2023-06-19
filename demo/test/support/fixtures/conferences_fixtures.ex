defmodule Demo.ConferencesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Demo.Conferences` context.
  """

  @doc """
  Generate a conference.
  """
  def conference_fixture(attrs \\ %{}) do
    {:ok, conference} =
      attrs
      |> Enum.into(%{
        date: ~N[2023-06-18 13:33:00],
        description: "some description",
        name: "some name",
        room: "some room"
      })
      |> Demo.Conferences.create_conference()

    conference
  end
end
