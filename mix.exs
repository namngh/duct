defmodule Duct.MixProject do
  use Mix.Project

  def project do
    [
      app: :duct,
      version: "1.0.3",
      description: "A clean pipeline pattern",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      source_url: "https://github.com/namngh/duct",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["namngh"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/namngh/duct"
      }
    ]
  end

  defp docs do
    [
      main: "Duct",
      extras: ["README.md"]
    ]
  end
end
