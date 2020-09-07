defmodule Sunstone.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Sunstone.Repo

  alias Sunstone.Accounts.User
  alias Comeonin.Bcrypt
  alias Sunstone.Chats.Office

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
  def get_user!(id) do
    query = from u in User,
            where: u.id == ^id,
            select: u,
            preload: [
              :active_office,
              offices: ^from( o in Office,
                       order_by: [desc: o.inserted_at])
            ]

    Repo.one!(query)
  end
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
    result = %User{}
    |> User.changeset(attrs)
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
  def update_user(%User{} = user, attrs, office_id) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
    |> broadcast(:user_updated, office_id)
  end

  def update_user_active(%User{} = user, attrs, office_id) do
    office = Chats.get_office!(office_id)
    {_, table} = Chats.create_table(%{}, office)
    new_attrs = Map.merge(attrs, %{is_active: true, table_id: table.id, active_office: office_id})
    user
    |> User.update_user_active_changeset(new_attrs)
    |> Repo.update()
    |> broadcast(:user_updated, office_id)
  end

  def update_user_inactive(%User{} = user, office_id) do
    user
    |> User.update_user_active_changeset(%{is_active: false, peer_id: "", table_id: 1})
    |> Repo.update()
    |> broadcast(:user_inactive, office_id)

  end


  def leave_table(%User{} = user, office_id) do
    office = Chats.get_office!(office_id)
    {_, table} = Chats.create_table(%{}, office)
    attrs = %{table_id: table.id}
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
    |> broadcast(:user_updated, office_id)
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

      false -> 
      {_, changeset} = Ecto.Changeset.apply_action(changeset, :update)
      {:error, changeset}
    end

  end

  defp check_password(nil, changeset, _) do
    {_, changeset} = 
    Ecto.Changeset.add_error(changeset, :generic, "Invalid email or password") 
    |> Ecto.Changeset.apply_action(:update)
    {:error, changeset}
  end

  defp check_password(user, changeset, plain_text_password) do
    case Bcrypt.checkpw(plain_text_password, user.password) do
      true -> {:ok, user}
      false -> 
        {_, changeset} = 
        Ecto.Changeset.add_error(changeset, :generic, "Invalid email or password") 
        |> Ecto.Changeset.apply_action(:update)
      {:error, changeset}
    end
  end

  def subscribe(office_id) do
    Phoenix.PubSub.subscribe(Sunstone.PubSub, "users:#{office_id}")
  end

  defp broadcast({:ok, user}, event, office_id) do
    Phoenix.PubSub.broadcast(Sunstone.PubSub, "users:#{office_id}", {event})
    {:ok, user}
  end




end


 