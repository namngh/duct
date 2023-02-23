defmodule Duct.MixProject do
  use Mix.Project

  def project do
    [
      app: :duct,
      version: "1.0.0",
      description: "A clean pipeline pattern",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
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
      licenses: ["MIT"]
    ]
  end
end
