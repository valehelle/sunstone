defmodule Sunstone.Repo.Migrations.AddVideoToTables do
  use Ecto.Migration

  def change do
    alter table(:tables) do
      add :is_locked, :boolean, default: false
    end
  end
end

