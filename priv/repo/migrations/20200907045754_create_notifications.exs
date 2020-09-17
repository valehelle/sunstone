defmodule Sunstone.Repo.Migrations.CreatePush do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :endpoint, :string
      add :auth, :string
      add :p256dh, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:notifications, [:user_id])
  end
end
