defmodule Sunstone.Chats.Table do
  use Ecto.Schema
  import Ecto.Changeset
  alias Sunstone.Accounts.User
  alias Sunstone.Chats.Office
  schema "tables" do
    has_many :users, User
    belongs_to :office, Office
    belongs_to :broadcast, User, foreign_key: :broadcast_id, on_replace: :update
    field :is_locked, :boolean, default: false
    timestamps()
  end

  @doc false
  def changeset(table, attrs, office) do
    table
    |> cast(attrs, [])
    |> put_assoc(:office, office)
    |> validate_required([])
  end
  @doc false
  def broadcast_changeset(table, user) do
    table
    |> cast(%{}, [])
    |> put_assoc(:broadcast, user)
    |> validate_required([])
  end
  @doc false
  def broadcast_reset_changeset(table) do
    table
    |> change(broadcast: nil)
  end
  
  def locked_changeset(table, attrs) do
    table
    |> cast(attrs, [:is_locked])
    |> validate_required([:is_locked])
  end

end
