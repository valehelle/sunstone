defmodule Sunstone.Accounts.Social do
  use Ecto.Schema
  import Ecto.Changeset
  alias Sunstone.Accounts.User

  schema "socials" do
    field :message, :string
    field :status, :string
    belongs_to :user, User


    timestamps()
  end

  @doc false
  def changeset(social, attrs, user) do
    social
    |> cast(attrs, [:status, :message])
    |> put_assoc(:user, user)
  end
end
