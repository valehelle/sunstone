defmodule Sunstone.Accounts.Notification do
  use Ecto.Schema
  import Ecto.Changeset
  alias Sunstone.Accounts.User

  schema "notifications" do
    field :endpoint, :string
    field :auth, :string
    field :p256dh, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(notification, attrs, user) do
    notification
    |> cast(attrs, [:endpoint, :auth, :p256dh])
    |> put_assoc(:user, user)
  end
end
