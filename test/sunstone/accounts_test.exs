defmodule Sunstone.AccountsTest do
  use Sunstone.DataCase

  alias Sunstone.Accounts

  describe "users" do
    alias Sunstone.Accounts.User

    @valid_attrs %{email: "some email", password: "some password"}
    @update_attrs %{email: "some updated email", password: "some updated password"}
    @invalid_attrs %{email: nil, password: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "some email"
      assert user.password == "some password"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.email == "some updated email"
      assert user.password == "some updated password"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end

  describe "socials" do
    alias Sunstone.Accounts.Social

    @valid_attrs %{message: "some message", status: "some status"}
    @update_attrs %{message: "some updated message", status: "some updated status"}
    @invalid_attrs %{message: nil, status: nil}

    def social_fixture(attrs \\ %{}) do
      {:ok, social} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_social()

      social
    end

    test "list_socials/0 returns all socials" do
      social = social_fixture()
      assert Accounts.list_socials() == [social]
    end

    test "get_social!/1 returns the social with given id" do
      social = social_fixture()
      assert Accounts.get_social!(social.id) == social
    end

    test "create_social/1 with valid data creates a social" do
      assert {:ok, %Social{} = social} = Accounts.create_social(@valid_attrs)
      assert social.message == "some message"
      assert social.status == "some status"
    end

    test "create_social/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_social(@invalid_attrs)
    end

    test "update_social/2 with valid data updates the social" do
      social = social_fixture()
      assert {:ok, %Social{} = social} = Accounts.update_social(social, @update_attrs)
      assert social.message == "some updated message"
      assert social.status == "some updated status"
    end

    test "update_social/2 with invalid data returns error changeset" do
      social = social_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_social(social, @invalid_attrs)
      assert social == Accounts.get_social!(social.id)
    end

    test "delete_social/1 deletes the social" do
      social = social_fixture()
      assert {:ok, %Social{}} = Accounts.delete_social(social)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_social!(social.id) end
    end

    test "change_social/1 returns a social changeset" do
      social = social_fixture()
      assert %Ecto.Changeset{} = Accounts.change_social(social)
    end
  end
end
