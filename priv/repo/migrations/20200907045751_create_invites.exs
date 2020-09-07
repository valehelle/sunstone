defmodule Sunstone.Repo.Migrations.CreateInvites do
  use Ecto.Migration

  def change do
    create table(:invites) do
      add :email, :string
      add :office_id, references(:offices, on_delete: :nothing)

      timestamps()
    end

    create index(:invites, [:office_id])
  end
end
