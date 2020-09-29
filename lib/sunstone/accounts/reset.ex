defmodule Sunstone.Accounts.Reset do
  use Ecto.Schema
  import Ecto.Changeset
  alias Bayaq.Accounts.User

  schema "resets" do
    field :has_expired, :boolean, default: false
    field :token, :string
    belongs_to :user, User


    timestamps()
  end

  @doc false
  def changeset(reset, attrs) do
    reset
    |> cast(attrs, [:token, :has_expired, :user_id])
    |> validate_required([:token, :has_expired, :user_id])
  end
end
