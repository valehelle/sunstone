defmodule Sunstone.Repo.Migrations.AddMutedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_muted, :boolean, default: false
      add :video_peer_id, :string
    end
  end
end
