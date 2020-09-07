defmodule Sunstone.Repo.Migrations.AddTableToOffice do
  use Ecto.Migration

  def change do
    alter table(:tables) do
      add :office_id, references(:offices, on_delete: :nothing)
    end
    create index(:tables, [:office_id])
  end
end
