# Duct

A clean pipeline pattern for new Elixir project. Base on excellent `Ecto.Multi` data structure.

## Usage

### Multi

```elixir
Duct.Multi.new()
|> Duct.Multi.run("salad", fn _ -> {:ok, 10} end) # Return {:ok, value} or {:error, error}
|> Duct.Multi.run("tomato", fn _ -> 5 end) # Default is {:ok, value}
|> Duct.Multi.run("total", fn %{"salad" => salad, "tomato" => tomato} ->
  salad + tomato
end)
|> Duct.Multi.run("tax", fn %{"total" => total} -> total * 0.1 end)
|> Duct.run() # {:ok, %{"salad" => 10, "tomato" => 5, "total" => 15, "tax" => 1.5}}
```

### Parallel

```elixir
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
|> Duct.run() # {:ok, %{"first" => 1, "second" => 2}}
```

## Installation

```elixir
def deps do
  [
    {:duct, "~> 1.0.0"}
  ]
end
```

## Contributing

Pull requests are welcome. For major changes,
please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mi
