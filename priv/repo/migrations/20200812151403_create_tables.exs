defmodule Sunstone.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table(:tables) do
      timestamps()
    end

  end
end
