defmodule Sunstone.Chats do
  @moduledoc """
  The Chats context.
  """

  import Ecto.Query, warn: false
  alias Sunstone.Repo

  alias Sunstone.Chats.Table
  alias Sunstone.Accounts.User
  @doc """
  Returns the list of tables.

  ## Examples

      iex> list_tables()
      [%Table{}, ...]

  """
  def list_tables(office_id) do
    user_query = from u in User, 
                  order_by: u.id,
                  preload: [:socials]
                  
    query = from t in Table,
            join: u in assoc(t, :users),
            group_by: t.id,
            where: u.is_active == true,
            where: t.office_id == ^office_id,
            preload: [:broadcast, users: ^user_query],
            order_by: t.id
    Repo.all query
  end

  @doc """
  Gets a single table.

  Raises `Ecto.NoResultsError` if the Table does not exist.

  ## Examples

      iex> get_table!(123)
      %Table{}

      iex> get_table!(456)
      ** (Ecto.NoResultsError)

  """
  def get_table!(id) do
   query = from t in Table,
           where: t.id == ^id,
           preload: [:users, :broadcast]
   Repo.one!(query)
  end

  @doc """
  Creates a table.

  ## Examples

      iex> create_table(%{field: value})
      {:ok, %Table{}}

      iex> create_table(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_table(attrs \\ %{}, office) do
    %Table{}
    |> Table.changeset(attrs, office)
    |> Repo.insert()
  end

  @doc """
  Updates a table.

  ## Examples

      iex> update_table(table, %{field: new_value})
      {:ok, %Table{}}

      iex> update_table(table, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_table(%Table{} = table, attrs) do
    table
    |> Table.changeset(attrs)
    |> Repo.update()
  end

  def broadcast_on_table(table, user, office_id) do
    case true do
      true ->
        table
        |> Table.broadcast_changeset(user)
        |> Repo.update()
        |> broadcast(:table_updated, office_id)
      false ->
        {:error}
    end

  end
  def broadcast_reset_table(%Table{} = table, user, office_id) do
    case true do
      true ->
        Ecto.Changeset.change( Sunstone.Repo.get_by(Table, id: table.id), %{broadcast_id: nil}) |> Sunstone.Repo.update() |> broadcast(:table_updated, office_id)
      false ->
        {:error}
    end
  end

  @doc """
  Deletes a table.

  ## Examples

      iex> delete_table(table)
      {:ok, %Table{}}

      iex> delete_table(table)
      {:error, %Ecto.Changeset{}}

  """
  def delete_table(%Table{} = table) do
    Repo.delete(table)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking table changes.

  ## Examples

      iex> change_table(table)
      %Ecto.Changeset{data: %Table{}}

  """
  def change_table(%Table{} = table, attrs \\ %{}) do
    Table.changeset(table, attrs)
  end

  alias Sunstone.Chats.Office

  @doc """
  Returns the list of offices.

  ## Examples

      iex> list_offices()
      [%Office{}, ...]

  """
  def list_offices do
    Repo.all(Office)
  end

  @doc """
  Gets a single office.

  Raises `Ecto.NoResultsError` if the Office does not exist.

  ## Examples

      iex> get_office!(123)
      %Office{}

      iex> get_office!(456)
      ** (Ecto.NoResultsError)

  """
  def get_office!(id) do 
    Repo.get!(Office, id) |> Repo.preload([:owner, :users, :tables, users: [:table, :socials]])
    
  end


  @doc """
  Creates a office.

  ## Examples

      iex> create_office(%{field: value})
      {:ok, %Office{}}

      iex> create_office(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_office(attrs \\ %{}, user) do
    %Office{}
    |> Office.changeset(attrs, user)
    |> Repo.insert()
  end

  def user_is_listed_in_office(office, user) do
    case Enum.find(office.users, fn o_user -> o_user.id == user.id end) do
      nil -> false
      _ -> true
    end
  end

  def add_user_to_office(office, user, invite) do
    office
    |> Office.add_user_changeset(user)
    |> Repo.update()
    delete_invite(invite) 

  end

  @doc """
  Updates a office.

  ## Examples

      iex> update_office(office, %{field: new_value})
      {:ok, %Office{}}

      iex> update_office(office, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_office(%Office{} = office, attrs) do
    office
    |> Office.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a office.

  ## Examples

      iex> delete_office(office)
      {:ok, %Office{}}

      iex> delete_office(office)
      {:error, %Ecto.Changeset{}}

  """
  def delete_office(%Office{} = office) do
    Repo.delete(office)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking office changes.

  ## Examples

      iex> change_office(office)
      %Ecto.Changeset{data: %Office{}}

  """
  def change_office(%Office{} = office, attrs \\ %{}) do
    Office.changeset(office, attrs)
  end

  alias Sunstone.Chats.Invite

  @doc """
  Returns the list of invites.

  ## Examples

      iex> list_invites()
      [%Invite{}, ...]

  """
  def list_invites_from_email(email) do
    query = from i in Invite,
           where: i.email == ^email,
           preload: [office: :owner]
    Repo.all(query)
  end

  def list_invites_from_office(office) do
    query = from i in Invite,
           where: i.office_id == ^office.id
    Repo.all(query)
  end

  @doc """
  Gets a single invite.

  Raises `Ecto.NoResultsError` if the Invite does not exist.

  ## Examples

      iex> get_invite!(123)
      %Invite{}

      iex> get_invite!(456)
      ** (Ecto.NoResultsError)

  """
  def get_invite!(id), do: Repo.get!(Invite, id)
  def get_invite_from_email!(email, office), do: Repo.get_by(Invite,  [email: email, office_id: office.id])

  @doc """
  Creates a invite.

  ## Examples

      iex> create_invite(%{field: value})
      {:ok, %Invite{}}

      iex> create_invite(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_invite(attrs \\ %{}, office) do
    %Invite{}
    |> Invite.changeset(attrs, office)
    |> Repo.insert()
  end

  @doc """
  Updates a invite.

  ## Examples

      iex> update_invite(invite, %{field: new_value})
      {:ok, %Invite{}}

      iex> update_invite(invite, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_invite(%Invite{} = invite, attrs) do
    invite
    |> Invite.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a invite.

  ## Examples

      iex> delete_invite(invite)
      {:ok, %Invite{}}

      iex> delete_invite(invite)
      {:error, %Ecto.Changeset{}}

  """
  def delete_invite(%Invite{} = invite) do
    Repo.delete(invite)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invite changes.

  ## Examples

      iex> change_invite(invite)
      %Ecto.Changeset{data: %Invite{}}

  """
  def change_invite(%Invite{} = invite, attrs \\ %{}) do
    Invite.changeset(invite, attrs)
  end


   defp broadcast({:ok, user}, event, office_id) do
    Phoenix.PubSub.broadcast(Sunstone.PubSub, "users:#{office_id}", {event})
    {:ok, user}
  end

  
end
