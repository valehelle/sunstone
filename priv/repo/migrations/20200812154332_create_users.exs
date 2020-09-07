defmodule Sunstone.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :password, :string
      add :name, :string
      add :peer_id, :string
      add :is_active, :boolean
      add :table_id, references(:tables, on_delete: :nothing)
      add :active_office_id, references(:offices, on_delete: :nothing)
      timestamps()
    end
    create unique_index(:users, [:email])
  end
end
