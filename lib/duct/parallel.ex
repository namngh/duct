defmodule Duct.Parallel do
  defstruct operations: [], names: MapSet.new()

  @type run :: (() -> {:ok | :error, any} | any) | any
  @typep operation :: {:run, run} | {:inspect, Keyword.t()}
  @typep operations :: [{name, operation}]
  @typep names :: MapSet.t()
  @type name :: any
  @type t :: %__MODULE__{operations: operations, names: names}

  @default_timeout 5000

  @doc """
  Returns an empty `Duct.Parallel` struct.

  ## Example
      iex> Duct.Parallel.new() |> Duct.Parallel.to_list()
      []
  """
  @spec new :: t
  def new do
    %__MODULE__{}
  end

  @doc """
  Adds a function to run parallel.

  ## Example
      Duct.Parallel.new()
      |> Duct.Parallel.run("facebook", fn -> post(:facebook) end)
      |> Duct.Parallel.run("twitter", fn -> post(:twitter) end)
      |> Duct.run()
  """
  @spec run(t, name, run) :: t
  def run(%{operations: operations, names: names} = multi, name, run) when is_function(run, 0) do
    names
    |> MapSet.member?(name)
    |> case do
      true ->
        raise "#{Kernel.inspect(name)} is already a member of the Duct.Parallel: \n#{Kernel.inspect(multi)}"

      _ ->
        %{multi | operations: [{name, {:run, run}} | operations], names: MapSet.put(names, name)}
    end
  end

  def run(%{operations: operations, names: names} = multi, name, run) do
    names
    |> MapSet.member?(name)
    |> case do
      true ->
        raise "#{Kernel.inspect(name)} is already a member of the Duct.Parallel: \n#{Kernel.inspect(multi)}"

      _ ->
        %{
          multi
          | operations: [{name, {:run, fn -> run end}} | operations],
            names: MapSet.put(names, name)
        }
    end
  end

  @doc """
  Returns the list of operations stored in `multi`.

  Always use this function when you need to access the operations you
  have defined in `Duct.Multi`. Inspecting the `Duct.Multi` struct internals
  directly is discouraged.
  """
  @spec to_list(t) :: [{name, term}]
  def to_list(%__MODULE__{operations: operations}) do
    operations
  end

  @doc false
  def __apply__(%__MODULE__{operations: operations}, opts \\ []) do
    operations
    |> Enum.map(fn {name, {:run, f}} -> {name, Task.async(f)} end)
    |> yield_many(opts |> Keyword.get(:timeout, @default_timeout))
    |> Enum.map(fn {task, res} ->
      res || Task.shutdown(task, :brutal_kill)
    end)
    |> Enum.reduce({[], []}, fn
      {:ok, v}, {ok, error} ->
        {[v | ok], error}

      {:error, e}, {ok, error} ->
        {ok, [e | error]}
    end)
    |> case do
      {ok, []} -> {:ok, ok |> Map.new()}
      {ok, error} -> {:error, error |> Map.new(), ok |> Map.new()}
    end
  end

  # Credit https://github.com/elixir-lang/elixir/blob/a64d42f5d3cb6c32752af9d3312897e8cd5bb7ec/lib/elixir/lib/task.ex#L980
  defguardp is_timeout(timeout)
            when timeout == :infinity or (is_integer(timeout) and timeout >= 0)

  @doc false
  @spec yield_many([t], number | :infinity) :: [{t, {:ok, term} | {:exit, term} | nil}]
  def yield_many(tasks, timeout \\ 5000) when is_timeout(timeout) do
    timeout_ref = make_ref()

    timer_ref =
      if timeout != :infinity do
        Process.send_after(self(), timeout_ref, timeout)
      end

    try do
      yield_many(tasks, timeout_ref, :infinity)
    catch
      {:noconnection, reason} ->
        exit({reason, {__MODULE__, :yield_many, [tasks, timeout]}})
    after
      timer_ref && Process.cancel_timer(timer_ref)
      receive do: (^timeout_ref -> :ok), after: (0 -> :ok)
    end
  end

  defp yield_many([{name, %Task{ref: ref, owner: owner} = task} | rest], timeout_ref, timeout) do
    if owner != self() do
      raise ArgumentError, invalid_owner_error(task)
    end

    receive do
      {^ref, reply} ->
        Process.demonitor(ref, [:flush])
        [{task, {:ok, {name, reply}}} | yield_many(rest, timeout_ref, timeout)]

      {:DOWN, ^ref, _, proc, :noconnection} ->
        throw({:noconnection, {:nodedown, monitor_node(proc)}})

      {:DOWN, ^ref, _, _, reason} ->
        [{task, {:error, {name, reason}}} | yield_many(rest, timeout_ref, timeout)]

      ^timeout_ref ->
        [{task, {:error, {name, :timeout}}} | yield_many(rest, timeout_ref, 0)]
    after
      timeout ->
        [{task, {:error, {name, :timeout}}} | yield_many(rest, timeout_ref, 0)]
    end
  end

  defp yield_many([], _timeout_ref, _timeout) do
    []
  end

  defp invalid_owner_error(task) do
    "task #{inspect(task)} must be queried from the owner but was queried from #{inspect(self())}"
  end

  defp monitor_node(pid) when is_pid(pid), do: node(pid)
  defp monitor_node({_, node}), do: node
end
