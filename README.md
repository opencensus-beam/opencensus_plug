# Opencensus.Plug

[![CircleCI](https://circleci.com/gh/opencensus-beam/plug.svg?style=svg)](https://circleci.com/gh/opencensus-beam/plug)
[![CodeCov](https://img.shields.io/codecov/c/github/opencensus-beam/plug.svg)](https://codecov.io/gh/opencensus-beam/plug)

[Plug][plug] integration for [OpenCensus][oc]. It provides tracer and metrics
integration.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `opencensus_plug` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:opencensus_plug, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/opencensus\_plug](https://hexdocs.pm/opencensus_plug).

## Usage

### Tracing

Create tracing module:

```elixir
defmodule MyApp.TracePlug do
  use Opencensus.Plug.Trace
end
```

And then add it on the beginning of your pipeline (the sooner the better):

```elixir
plug MyApp.TracePlug
```

This will extract parent trace from the headers accordingly
to [Tracing Context](https://github.com/w3c/trace-context) proposal and it will
create new span. By default span name will match request path, you can configure
that by defining `span_name/2` method that will receive `Plug.Conn.t` as a first
argument and plug options as a second.

### Metrics

Create metrics module:

```elixir
defmodule MyApp.MetricsPlug do
  use Opencensus.Plug.Metrics
end
```

And then add it on the beginning of your pipeline (the sooner the better):

```elixir
plug MyApp.MetricsPlug
```

You also need to define metrics that will be measured, fortunately there is
helper method for you, just call `MyApp.MetricsPlug.setup_metrics()` **before**
running pipeline.

Available metrics:

- `"plug/requests/duration"` - request duration in microseconds
- `"plug/requests/count"` - requests count

**WARNING!** This defines only metrics, not views. You need to define views on
your own to be able to see them in the exporters.

## License

See [LICENSE](LICENSE) file.

[plug]: https://github.com/elixir-plug/plug
[oc]: https://opencensus.io
