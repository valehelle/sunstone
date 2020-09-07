defmodule Sunstone.Chats.Invite do
  use Ecto.Schema
  import Ecto.Changeset
  alias Sunstone.Chats.Office

  schema "invites" do
    field :email, :string
    belongs_to :office, Office

    timestamps()
  end

  @doc false
  def changeset(invite, attrs, office) do
    invite
    |> cast(attrs, [:email])
    |> put_assoc(:office, office)
    |> validate_required([:email])
  end
end
