# Opencensus.Plug

[![CircleCI](https://circleci.com/gh/opencensus-beam/opencensus_plug.svg?style=svg)](https://circleci.com/gh/opencensus-beam/opencensus_plug)
[![CodeCov](https://codecov.io/gh/opencensus-beam/opencensus_plug/branch/master/graph/badge.svg)](https://codecov.io/gh/opencensus-beam/opencensus_plug)
[![Inline docs](http://inch-ci.org/github/opencensus-beam/opencensus_plug.svg)](http://inch-ci.org/github/opencensus-beam/opencensus_plug)

[Plug][plug] integration for [OpenCensus][oc]. It provides tracer and metrics
integration.

## Installation

The package can be installed by adding `opencensus_plug` to your list
of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:opencensus_plug, "~> 0.3"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/opencensus\_plug](https://hexdocs.pm/opencensus_plug).

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
