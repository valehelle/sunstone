defmodule Sunstone.Repo.Migrations.AddOfficeToUser do
  use Ecto.Migration

  def change do
    alter table(:offices) do
      add :owner_id, references(:users, on_delete: :nothing)
    end
    create index(:offices, [:owner_id])
  end
end
