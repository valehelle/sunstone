defmodule Sunstone.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Comeonin.Bcrypt
  alias Sunstone.Chats.Table
  alias Sunstone.Chats.Office
  alias Sunstone.Accounts.Notification
  alias Sunstone.Accounts.Social


schema "users" do
    field :email, :string
    field :password, :string
    field :name, :string
    field :peer_id, :string
    field :is_active, :boolean, default: false
    field :retype_password, :string, virtual: true
    field :is_muted, :boolean, default: false
    field :remember_me, :string, virtual: true
    has_one :notifications, Notification
    has_one :socials, Social
    has_one :broadcasting, Table, on_replace: :mark_as_invalid
    belongs_to :table, Table
    belongs_to :active_office, Office, foreign_key: :active_office_id
    has_many :own_offices, Office, foreign_key: :owner_id
    many_to_many(
      :offices,
      Office,
      join_through: "user_office",
      on_replace: :delete
    )
    timestamps()
  end

  @doc false
  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:email, :password, :retype_password, :name])
    |> check_password()
    |> validate_required([:email, :password, :retype_password, :name])
    |> validate_format(:email, ~r/@/)
    |> unsafe_validate_unique([:email], Sunstone.Repo, message: "Email is already in use")
    |> unique_constraint(:email, [name: :users_email_index])
    |> put_pass_hash()
  end
  
  @doc false
  def login_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:email, :password])
    |> check_password()
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/@/)
  end
  def update_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:table_id, :is_muted])
  end
  def update_user_active_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:is_active, :peer_id, :table_id, :is_muted])
    |> validate_required([:is_active])
  end

  defp check_password(%Ecto.Changeset{changes: %{password: password, retype_password: retype_password}} = changeset) do
    case password == retype_password do
    true -> changeset
    false -> add_error(changeset, :password, "Password does not match")
    end
  end
  defp check_password(changeset), do: changeset
  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password: Bcrypt.hashpwsalt(password))
  end
  defp put_pass_hash(changeset), do: changeset
end
