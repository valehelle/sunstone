defmodule Bayaq.Repo.Migrations.CreateResets do
  use Ecto.Migration

  def change do
    create table(:resets) do
      add :token, :string
      add :has_expired, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:resets, [:user_id])
  end
end
