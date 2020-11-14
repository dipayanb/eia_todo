defmodule TodoCacheTest do
  use ExUnit.Case

  test "server_procee" do
    bob_pid = Todo.Cache.server_process("bob")
    assert bob_pid != Todo.Cache.server_process("alice")
    assert bob_pid == Todo.Cache.server_process("bob")
  end

  test "to-do operation" do
    alice = Todo.Cache.server_process("alice")
    Todo.Server.add_entry(alice, %{date: ~D[2018-12-19], title: "Dentist"})
    entries = Todo.Server.entries(alice, ~D[2018-12-19])
    assert [%{date: ~D[2018-12-19], title: "Dentist", id: 1}] == entries
  end
end
