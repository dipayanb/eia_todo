defmodule Todo.Server do
  use GenServer, restart: :temporary

  alias Todo.List, as: TodoList

  @expiry_idle_timeout :timer.seconds(10)

  def start_link(todo_list_name) do
    GenServer.start_link(__MODULE__, todo_list_name, name: via_tuple(todo_list_name))
  end

  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  def delete_entry(todo_server, entry_id) do
    GenServer.cast(todo_server, {:delete_entry, entry_id})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  def init(name) do
    IO.puts("Starting to-do server for #{name}")
    send(self(), :real_init)
    {:ok, {name, Todo.Database.get(name) || Todo.List.new()}, @expiry_idle_timeout}
  end

  def handle_cast({:add_entry, new_entry}, {name, state}) do
    new_list = TodoList.add_entry(state, new_entry)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}, @expiry_idle_timeout}
  end

  def handle_cast({:delete_entry, entry_id}, {name, state}) do
    new_list = TodoList.delete_entry(state, entry_id)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}, @expiry_idle_timeout}
  end

  def handle_call({:entries, date}, _from, {name, state}) do
    {:reply, TodoList.entries(state, date), {name, state}, @expiry_idle_timeout}
  end

  def handle_info(:real_init, {name, _}) do
    {:noreply, {name, Todo.Database.get(name) || Todo.List.new()}, @expiry_idle_timeout}
  end

  def handle_info(:timeout, {name, todo_list}) do
    IO.puts("Stopping todo server for #{name}.")
    {:stop, :normal, {name, todo_list}}
  end

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end
end
