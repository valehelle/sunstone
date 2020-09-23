defmodule Sunstone.Repo.Migrations.AddVideoToTables do
  use Ecto.Migration

  def change do
    alter table(:tables) do
      add :broadcast_id, references(:users, on_delete: :nothing)
    end
  end
end

