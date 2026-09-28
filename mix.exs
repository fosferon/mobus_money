defmodule MobusMoney.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/fosferon/mobus_money"

  def project do
    [
      app: :mobus_money,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: @source_url,
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ex_money, "~> 6.2"},
      # Ecto is optional: consumers needing only the value type and arithmetic
      # are not forced onto it, and MobusMoney.Schema compiles to a stub when
      # it is absent (design.md D5).
      {:ecto, "~> 3.10", optional: true},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Currency-aware money for the fosferon ecosystem: a value type that carries its currency, explicit rounding, and an amount+currency storage pair"
  end

  defp package do
    [
      name: "mobus_money",
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      maintainers: ["Leonidas"],
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
