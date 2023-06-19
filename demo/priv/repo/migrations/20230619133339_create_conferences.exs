defmodule Demo.Repo.Migrations.CreateConferences do
  use Ecto.Migration

  def change do
    create table(:conferences) do
      add :name, :string
      add :description, :string
      add :room, :string
      add :date, :naive_datetime

      timestamps()
    end
  end
end
