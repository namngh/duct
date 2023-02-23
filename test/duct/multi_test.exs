defmodule Duct.MultiTest do
  use ExUnit.Case
  doctest Duct.Multi

  test "Multi.new()" do
    assert [] = Duct.Multi.new() |> Duct.Multi.to_list()
  end
end
