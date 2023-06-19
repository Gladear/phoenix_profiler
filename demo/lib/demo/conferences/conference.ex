defmodule Demo.Conferences.Conference do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conferences" do
    field :date, :naive_datetime
    field :description, :string
    field :name, :string
    field :room, :string

    timestamps()
  end

  @doc false
  def changeset(conference, attrs) do
    conference
    |> cast(attrs, [:name, :description, :room, :date])
    |> validate_required([:name, :description, :room, :date])
  end
end
