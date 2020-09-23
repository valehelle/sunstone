defmodule Sunstone.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Sunstone.Repo

  alias Sunstone.Accounts.User
  alias Comeonin.Bcrypt
  alias Sunstone.Chats.Office
  alias Sunstone.Accounts.Notification
  alias Sunstone.Accounts.Social
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
              :socials,
              :active_office,
              notifications: ^from( n in Notification, order_by: [desc: n.id]),
              offices: ^from( o in Office,order_by: [desc: o.inserted_at])
              
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
    new_attrs = Map.merge(attrs, %{is_active: true, table_id: table.id, active_office: office_id, is_muted: false})
    user
    |> User.update_user_active_changeset(new_attrs)
    |> Repo.update()
    |> broadcast(:user_updated, office_id)
  end

  def update_user_mute(%User{} = user, attrs, office_id) do
    user
    |> User.update_user_active_changeset(attrs)
    |> Repo.update()
    |> broadcast(:user_updated, office_id)
  end


  def update_user_inactive(%User{} = user, office_id) do
    user
    |> User.update_user_active_changeset(%{is_active: false, peer_id: "", table_id: 1, is_muted: false})
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






  def create_update_notifications(%{ "endpoint" => endpoint, "keys" => %{ "auth" => auth, "p256dh" => p256dh} }, user) do
    
    %Notification{}
    |> Notification.changeset(%{"endpoint" => endpoint, "auth" => auth, "p256dh" => p256dh}, user)
    |> Repo.insert()

  end


  def list_notifications() do
    
    Repo.all(Notification)

  end


  def subscribe(office_id) do
    Phoenix.PubSub.subscribe(Sunstone.PubSub, "users:#{office_id}")
  end

  defp broadcast({:ok, user}, event, office_id) do
    Phoenix.PubSub.broadcast(Sunstone.PubSub, "users:#{office_id}", {event})
    {:ok, user}
  end



  @doc """
  Returns the list of socials.

  ## Examples

      iex> list_socials()
      [%Social{}, ...]

  """
  def list_socials do
    Repo.all(Social)
  end

  @doc """
  Gets a single social.

  Raises `Ecto.NoResultsError` if the Social does not exist.

  ## Examples

      iex> get_social!(123)
      %Social{}

      iex> get_social!(456)
      ** (Ecto.NoResultsError)

  """
  def get_social!(id), do: Repo.get!(Social, id)  |> Repo.preload([:user])

  @doc """
  Creates a social.

  ## Examples

      iex> create_social(%{field: value})
      {:ok, %Social{}}

      iex> create_social(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_social(attrs \\ %{}) do
    %Social{}
    |> Social.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a social.

  ## Examples

      iex> update_social(social, %{field: new_value})
      {:ok, %Social{}}

      iex> update_social(social, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_social(%Social{} = social, attrs) do
    social
    |> Social.changeset(attrs)
    |> Repo.update()
  end


  def create_update_social(attr, user, office_id) do

    social = 
      case user.socials do
        nil -> %Social{}
        socials -> get_social!(user.socials.id)
      end

    social
    |> Social.changeset(attr, user)
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: :user_id
    )
    |> broadcast(:user_updated, office_id)

  end



  @doc """
  Deletes a social.

  ## Examples

      iex> delete_social(social)
      {:ok, %Social{}}

      iex> delete_social(social)
      {:error, %Ecto.Changeset{}}

  """
  def delete_social(%Social{} = social) do
    Repo.delete(social)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking social changes.

  ## Examples

      iex> change_social(social)
      %Ecto.Changeset{data: %Social{}}

  """
  def change_social(%Social{} = social, attrs \\ %{}) do
    Social.changeset(social, attrs)
  end
end
