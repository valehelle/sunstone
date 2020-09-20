defmodule Sunstone.Repo.Migrations.CreateSocials do
  use Ecto.Migration

  def change do
    create table(:socials) do
      add :status, :string
      add :message, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:socials, [:user_id])
  end
end
