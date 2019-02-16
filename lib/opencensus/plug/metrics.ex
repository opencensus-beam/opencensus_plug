defmodule Opencensus.Plug.Metrics do
  @moduledoc """
  Template method for creating `Plug` to measure response times.

  ## Usage

  1. Create your own `Plug` module:

    ```elixir
    defmodule MyApp.MetricsPlug do
      use Opencensus.Plug.Metrics
    end
    ```

  2. Add it to your pipeline, ex. for Phoenix:

    ```elixir
    defmodule MyAppWeb.Endpoint do
      use Phoenix.Endpoint, otp_app: :my_app

      plug MyApp.MetricsPlug
    end
    ```

  ## Configuration

  `use` accepts `prefix` option that will be prefix of all measurements.

  And also you can use `attributes` argument in `use` which must be either list
  of attributes which are names of 1-argument functions in current module that
  must return string value of the attribute, or map/keyword list of one of:

  - `atom` - which is name of the called function
  - `{module, function}` - which will call `apply(module, function, [conn])`
  - `{module, function, args}` - which will prepend `conn` to the given arguments
    and call `apply(module, function, [conn | args])`

  ## Measurements

  - "#\{prefix}/request" - duration of requests in microseconds
  """

  defmacro __using__(opts) do
    prefix = Keyword.get(opts, :prefix, "plug")
    measure_name = "#{prefix}/requests"

    attributes = Keyword.get(opts, :attributes, [])

    quote do
      @behaviour Plug
      @measure_name unquote(measure_name)

      def setup_metrics do
        [
          :oc_stat_measure.new(
            @measure_name,
            "HTTP request duration in microseconds.",
            :usec
          )
        ]
      end

      def init(opts), do: opts

      def call(conn, _opts) do
        start = :erlang.monotonic_time()

        Plug.Conn.register_before_send(conn, fn conn ->
          stop = :erlang.monotonic_time()
          diff = stop - start

          tags =
            Map.merge(
              Opencensus.Plug.get_tags(conn, __MODULE__, unquote(attributes)),
              %{
                method: conn.method,
                host: conn.host,
                scheme: conn.scheme,
                status: conn.status
              }
            )

          :ok =
            :oc_stat.record(
              tags,
              @measure_name,
              :erlang.convert_time_unit(diff, :native, :microsecond)
            )

          conn
        end)
      end
    end
  end
end
