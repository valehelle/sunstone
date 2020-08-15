defmodule Sunstone.Chats.Table do
  use Ecto.Schema
  import Ecto.Changeset
  alias Sunstone.Accounts.User
  schema "tables" do
    has_many :users, User
    timestamps()
  end

  @doc false
  def changeset(table, attrs) do
    table
    |> cast(attrs, [])
    |> validate_required([])
  end
end
