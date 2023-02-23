defmodule Duct do
  def run(%Duct.Multi{} = multi) do
    Duct.Multi.__apply__(multi)
  end

  def run(%Duct.Parallel{} = multi) do
    Duct.Parallel.__apply__(multi)
  end
end
