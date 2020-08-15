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
end
