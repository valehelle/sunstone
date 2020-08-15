defmodule Sunstone.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Sunstone.Repo

  alias Sunstone.Accounts.User
  alias Comeonin.Bcrypt

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  alias Sunstone.Chats

  def create_user(attrs \\ %{}) do
    {_, table} = Chats.create_table()
    attrs_with_table = Map.merge(attrs, %{"table_id" => table.id})
    result = %User{}
    |> User.changeset(attrs_with_table)
    |> Repo.insert()
    case result do 
    {:ok, user} -> 
      {:ok, user}
    {:error, changeset} -> result
    end
  end
  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
    |> broadcast(:user_updated)
  end

  def update_user_active(%User{} = user, attrs) do
  {_, table} = Chats.create_table()
    new_attrs = Map.merge(attrs, %{is_active: true, table_id: table.id})
    user
    |> User.update_user_active_changeset(new_attrs)
    |> Repo.update()
    |> broadcast(:user_updated)
  end

  def update_user_inactive(%User{} = user) do
    user
    |> User.update_user_active_changeset(%{is_active: false, peer_id: "slfkjsf", table_id: 1})
    |> Repo.update()
    |> broadcast(:user_inactive)

  end


  def leave_table(%User{} = user) do
    {_, table} = Chats.create_table()
    attrs = %{table_id: table.id}
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
    |> broadcast(:user_updated)
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def authenticate_user(%{"email" => email, "password" => password} = attrs) do
    
    changeset = User.login_changeset(%User{}, attrs)
    case changeset.valid? do 
      true ->     
      query = from u in User, where: u.email == ^email
      Repo.one(query)
      |> check_password(changeset, password)

      false -> {:error, changeset}
    end

  end

  defp check_password(nil, changeset, _) do
    {:error, Ecto.Changeset.add_error(changeset, :generic, "Invalid Email")}
  end

  defp check_password(user, changeset, plain_text_password) do
    case Bcrypt.checkpw(plain_text_password, user.password) do
      true -> {:ok, user}
      false -> {:error, Ecto.Changeset.add_error(changeset, :generic, "Invalid Email")}
    end
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Sunstone.PubSub, "users")
  end

  defp broadcast({:ok, user}, event) do
    Phoenix.PubSub.broadcast(Sunstone.PubSub, "users", {event})
    {:ok, user}
  end


end


 