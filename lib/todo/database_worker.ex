defmodule Todo.DatabaseWorker do
  use GenServer

  def start_link(db_folder) do
    IO.puts("Starting database worker.")
    GenServer.start_link(__MODULE__, db_folder)
  end

  def store(pid, key, data) do
    GenServer.cast(pid, {:store, key, data})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def init(db_folder) do
    File.mkdir_p!(db_folder)
    {:ok, %{db_folder: db_folder, content: nil}}
  end

  def handle_cast({:store, key, data}, %{db_folder: db_folder} = state) do
    key
    |> file_name(db_folder)
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, state}
  end

  def handle_call({:get, key}, _, %{db_folder: db_folder} = state) do
    data =
      case File.read(file_name(key, db_folder)) do
        {:ok, content} -> :erlang.binary_to_term(content)
        _ -> nil
      end

    {:reply, data, state}
  end

  defp file_name(key, db_folder) do
    Path.join(db_folder, to_string(key))
  end
end
