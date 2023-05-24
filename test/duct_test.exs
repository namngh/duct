defmodule DuctTest do
  use ExUnit.Case
  doctest Duct

  test "run()" do
    assert {:ok, %{"salad" => 10, "tomato" => 5, "total" => 15, "tax" => 1.5}} =
             Duct.Multi.new()
             |> Duct.Multi.run("salad", fn _ -> {:ok, 10} end)
             |> Duct.Multi.run("tomato", 5)
             |> Duct.Multi.run("total", fn %{"salad" => salad, "tomato" => tomato} ->
               salad + tomato
             end)
             |> Duct.Multi.run("tax", fn %{"total" => total} -> total * 0.1 end)
             |> Duct.run()

    assert {:error, "check_wallet", "NOT_ENOUGH_WALLET",
            %{"wallet" => 10, "salad" => 10, "tomato" => 5, "total" => 15, "tax" => 1.5}} =
             Duct.Multi.new()
             |> Duct.Multi.run("wallet", fn _ -> 10 end)
             |> Duct.Multi.run("salad", fn _ -> {:ok, 10} end)
             |> Duct.Multi.run("tomato", fn _ -> 5 end)
             |> Duct.Multi.run("total", fn %{"salad" => salad, "tomato" => tomato} ->
               salad + tomato
             end)
             |> Duct.Multi.run("tax", fn %{"total" => total} -> total * 0.1 end)
             |> Duct.Multi.run(
               "check_wallet",
               fn %{
                    "total" => total,
                    "tax" => tax,
                    "wallet" => wallet
                  } ->
                 (total + tax < wallet)
                 |> case do
                   true -> {:ok, true}
                   _ -> {:error, "NOT_ENOUGH_WALLET"}
                 end
               end
             )
             |> Duct.run()

    assert {:ok, %{"first" => 1, "second" => 2}} =
             Duct.Parallel.new()
             |> Duct.Parallel.run("first", fn ->
               Process.sleep(2000)
               IO.inspect(1)
               1
             end)
             |> Duct.Parallel.run("second", fn ->
               Process.sleep(1000)
               IO.inspect(2)
               2
             end)
             |> Duct.run()
  end
end
