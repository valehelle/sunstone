defmodule Sunstone.Repo.Migrations.AddUserOfficeTable do
  use Ecto.Migration

  def change do
    create table(:user_office, primary_key: false) do
    add :office_id,  references(:offices, on_delete: :delete_all, primary_key: true)
    add :user_id, references(:users, on_delete: :delete_all, primary_key: true)
    end

    create(index(:user_office, [:office_id]))
    create(index(:user_office, [:user_id]))

    create(
      unique_index(:user_office, [:user_id, :office_id], name: :user_id_office_id_unique_index)
    )

  end
end
