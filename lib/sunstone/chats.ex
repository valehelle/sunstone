defmodule Sunstone.Chats do
  @moduledoc """
  The Chats context.
  """

  import Ecto.Query, warn: false
  alias Sunstone.Repo

  alias Sunstone.Chats.Table

  @doc """
  Returns the list of tables.

  ## Examples

      iex> list_tables()
      [%Table{}, ...]

  """
  def list_tables(office_id) do
    query = from t in Table,
            join: u in assoc(t, :users),
            group_by: t.id,
            where: u.is_active == true,
            where: t.office_id == ^office_id,
            preload: [:users]
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
           preload: [:users]
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
    Repo.get!(Office, id) |> Repo.preload([:users, :tables])
    
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

  def add_user_to_office(office, user) do
    office
    |> Office.add_user_changeset(user)
    |> Repo.update()
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
end
