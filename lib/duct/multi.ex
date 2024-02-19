defmodule Duct.Multi do
  @moduledoc """
  Base on code of Ecto.Multi in here
  https://github.com/elixir-ecto/ecto/blob/b0e598926180e0788b4809dffd691bd0b5b54e81/lib/ecto/multi.ex
  """
  defstruct operations: [], names: MapSet.new()

  @type changes :: map
  @type run :: (changes -> {:ok | :error, any} | any) | any
  @typep operation :: {:run, run} | {:inspect, Keyword.t()}
  @typep operations :: [{name, operation}]
  @typep names :: MapSet.t()
  @type name :: any
  @type t :: %__MODULE__{operations: operations, names: names}

  @doc """
  Returns an empty `Duct.Multi` struct.

  ## Example
      iex> Duct.Multi.new() |> Duct.Multi.to_list()
      []
  """
  @spec new :: t
  def new do
    %__MODULE__{}
  end

  @doc """
  Adds a function to run as part of the multi.

  ## Example
      Duct.Multi.new()
      |> Duct.Multi.run("salary", fn _ -> 1_000_000 end)
      |> Duct.Multi.run("tax", fn %{"salary" => salary} -> salary * 10 / 100 end)
      |> Duct.run()
  """
  @spec run(t, name, run) :: t
  def run(%{operations: operations, names: names} = multi, name, run) when is_function(run, 1) do
    names
    |> MapSet.member?(name)
    |> case do
      true ->
        raise "#{Kernel.inspect(name)} is already a member of the Duct.Multi: \n#{Kernel.inspect(multi)}"

      _ ->
        %{multi | operations: [{name, {:run, run}} | operations], names: MapSet.put(names, name)}
    end
  end

  def run(%{operations: operations, names: names} = multi, name, run) do
    names
    |> MapSet.member?(name)
    |> case do
      true ->
        raise "#{Kernel.inspect(name)} is already a member of the Duct.Multi: \n#{Kernel.inspect(multi)}"

      _ ->
        %{
          multi
          | operations: [{name, {:run, fn _ -> run end}} | operations],
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
    |> Enum.reverse()
  end

  @spec inspect(t, Keyword.t()) :: t
  def inspect(multi, opts \\ []) do
    multi
    |> Map.update!(:operations, &[{:inspect, {:inspect, opts}} | &1])
  end

  @doc false
  def __apply__(%__MODULE__{operations: operations}) do
    operations
    |> Enum.reverse()
    |> Enum.reduce(%{}, &apply_operation/2)
    |> case do
      {name, value, acc} -> {:error, name, value, acc}
      acc -> {:ok, acc}
    end
  end

  defp apply_operation(_, {_name, _value, _acc} = acc) do
    acc
  end

  defp apply_operation({name, {:run, run}}, acc) do
    run
    |> apply([acc])
    |> case do
      {:ok, value} ->
        acc |> Map.put(name, value)

      {:error, value} ->
        {name, value, acc}

      value ->
        acc |> Map.put(name, value)
    end
  end

  defp apply_operation({_name, {:inspect, opts}}, acc) do
    log_function =
      opts[:log]
      |> case do
        nil -> &IO.inspect/2
        value -> value
      end

    opts[:only]
    |> case do
      nil -> log_function |> apply([acc, opts])
      value -> log_function |> apply([acc |> Map.take(List.wrap(value)), opts])
    end

    acc
  end
end
