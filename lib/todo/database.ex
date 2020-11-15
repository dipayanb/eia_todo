defmodule Todo.Database do
  @pool_size 3
  @db_folder "./persist"

  def child_spec(_) do
    node_name = node_name()
    File.mkdir_p!(@db_folder <> "/" <> node_name)

    :poolboy.child_spec(
      __MODULE__,
      [
        name: {:local, __MODULE__},
        worker_module: Todo.DatabaseWorker,
        size: @pool_size
      ],
      [@db_folder <> "/" <> node_name]
    )
  end

  def store(key, data) do
    {_results, bad_nodes} =
      :rpc.multicall(__MODULE__, :store_local, [key, data], :timer.seconds(5))

    Enum.each(bad_nodes, &IO.puts("Store failed on node #{&1}"))
    :ok
  end

  def store_local(key, data) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        Todo.DatabaseWorker.store(worker_pid, key, data)
      end
    )
  end

  def get(key) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        Todo.DatabaseWorker.get(worker_pid, key)
      end
    )
  end

  defp node_name() do
    node() |> Atom.to_string()
  end
end
