defmodule Sunstone.Chats.Office do
  use Ecto.Schema
  import Ecto.Changeset
  alias Sunstone.Accounts.User
  alias Sunstone.Chats.Table
  schema "offices" do
    field :name, :string
    belongs_to :owner, User, foreign_key: :owner_id
    has_many :tables, Table
    has_many :active_users, User, foreign_key: :active_office_id
    many_to_many(
      :users,
      User,
      join_through: "user_office",
      on_replace: :delete
    )
    timestamps()
  end

  @doc false
  def changeset(office, attrs, user) do
    users = [user]
    office
    |> cast(attrs, [:name])
    |> put_assoc(:owner, user)
    |> validate_required([:name, :owner])
    |> put_assoc(:users, users)
  end

  def add_user_changeset(office, user) do
    users = [user | office.users]
    office
    |> change(users: users)
  end
  
end
