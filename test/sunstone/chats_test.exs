defmodule Sunstone.ChatsTest do
  use Sunstone.DataCase

  alias Sunstone.Chats

  describe "tables" do
    alias Sunstone.Chats.Table

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def table_fixture(attrs \\ %{}) do
      {:ok, table} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Chats.create_table()

      table
    end

    test "list_tables/0 returns all tables" do
      table = table_fixture()
      assert Chats.list_tables() == [table]
    end

    test "get_table!/1 returns the table with given id" do
      table = table_fixture()
      assert Chats.get_table!(table.id) == table
    end

    test "create_table/1 with valid data creates a table" do
      assert {:ok, %Table{} = table} = Chats.create_table(@valid_attrs)
    end

    test "create_table/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chats.create_table(@invalid_attrs)
    end

    test "update_table/2 with valid data updates the table" do
      table = table_fixture()
      assert {:ok, %Table{} = table} = Chats.update_table(table, @update_attrs)
    end

    test "update_table/2 with invalid data returns error changeset" do
      table = table_fixture()
      assert {:error, %Ecto.Changeset{}} = Chats.update_table(table, @invalid_attrs)
      assert table == Chats.get_table!(table.id)
    end

    test "delete_table/1 deletes the table" do
      table = table_fixture()
      assert {:ok, %Table{}} = Chats.delete_table(table)
      assert_raise Ecto.NoResultsError, fn -> Chats.get_table!(table.id) end
    end

    test "change_table/1 returns a table changeset" do
      table = table_fixture()
      assert %Ecto.Changeset{} = Chats.change_table(table)
    end
  end

  describe "offices" do
    alias Sunstone.Chats.Office

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def office_fixture(attrs \\ %{}) do
      {:ok, office} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Chats.create_office()

      office
    end

    test "list_offices/0 returns all offices" do
      office = office_fixture()
      assert Chats.list_offices() == [office]
    end

    test "get_office!/1 returns the office with given id" do
      office = office_fixture()
      assert Chats.get_office!(office.id) == office
    end

    test "create_office/1 with valid data creates a office" do
      assert {:ok, %Office{} = office} = Chats.create_office(@valid_attrs)
      assert office.name == "some name"
    end

    test "create_office/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chats.create_office(@invalid_attrs)
    end

    test "update_office/2 with valid data updates the office" do
      office = office_fixture()
      assert {:ok, %Office{} = office} = Chats.update_office(office, @update_attrs)
      assert office.name == "some updated name"
    end

    test "update_office/2 with invalid data returns error changeset" do
      office = office_fixture()
      assert {:error, %Ecto.Changeset{}} = Chats.update_office(office, @invalid_attrs)
      assert office == Chats.get_office!(office.id)
    end

    test "delete_office/1 deletes the office" do
      office = office_fixture()
      assert {:ok, %Office{}} = Chats.delete_office(office)
      assert_raise Ecto.NoResultsError, fn -> Chats.get_office!(office.id) end
    end

    test "change_office/1 returns a office changeset" do
      office = office_fixture()
      assert %Ecto.Changeset{} = Chats.change_office(office)
    end
  end
end
