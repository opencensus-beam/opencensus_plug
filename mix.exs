defmodule Opencensus.Plug.MixProject do
  use Mix.Project

  def project do
    [
      app: :opencensus_plug,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.html": :test, "coveralls.json": :test]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.7"},
      {:opencensus, "~> 0.6.0"},

      # Documentation
      {:ex_doc, ">= 0.0.0", only: [:dev, :doc]},

      # Testing
      {:excoveralls, "~> 0.10.3", only: [:test]},
      {:dialyxir, ">= 0.0.0", runtime: false},
      {:junit_formatter, ">= 0.0.0", only: [:test]}
    ]
  end
end
