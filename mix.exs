defmodule Opencensus.Plug.MixProject do
  use Mix.Project

  @description "Integration between OpenCensus and Plug"

  def project do
    [
      app: :opencensus_plug,
      version: "0.1.1",
      elixir: "~> 1.5",
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
        docs: :docs,
        "inchci.add": :docs,
        "inch.report": :docs
      ],
      description: @description,
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/opencensus-beam/opencensus_plug",
        "OpenCensus" => "https://opencensus.io",
        "OpenCensus Erlang" => "https://github.com/census-instrumentation/opencensus-erlang",
        "OpenCensus BEAM" => "https://github.com/opencensus-beam"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.7"},
      {:opencensus, "~> 0.6.0 or ~> 0.7.0"},

      # Documentation
      {:ex_doc, ">= 0.0.0", only: [:docs]},
      {:inch_ex, "~> 1.0", only: [:docs]},

      # Testing
      {:excoveralls, "~> 0.10.3", only: [:test]},
      {:dialyxir, ">= 0.0.0", runtime: false, only: [:dev, :test]},
      {:junit_formatter, ">= 0.0.0", only: [:test]}
    ]
  end
end
