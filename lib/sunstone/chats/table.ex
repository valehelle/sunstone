defmodule Sunstone.Chats.Table do
  use Ecto.Schema
  import Ecto.Changeset
  alias Sunstone.Accounts.User
  alias Sunstone.Chats.Office
  schema "tables" do
    has_many :users, User
    belongs_to :office, Office

    timestamps()
  end

  @doc false
  def changeset(table, attrs, office) do
    table
    |> cast(attrs, [])
    |> put_assoc(:office, office)
    |> validate_required([])
  end
end
