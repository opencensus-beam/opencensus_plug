defmodule Opencensus.Plug.Trace do
  @moduledoc """
  Template method for creating `Plug` to trace your `Plug` requests.

  ## Usage

  1. Create your own `Plug` module:

    ```elixir
    defmodule MyApp.TracingPlug do
      use Opencensus.Plug.Trace
    end
    ```

  2. Add it to your pipeline, ex. for Phoenix:

    ```elixir
    defmodule MyAppWeb.Endpoint do
      use Phoenix.Endpoint, otp_app: :my_app

      plug MyApp.TracingPlug
    end
    ```

  ## Configuration

  This module creates 2 callback modules, which allows you to configure your
  span and also provides a way to add custom attributes assigned to span.

  - `c:span_name/1`
  - `c:span_status/1`

  And also you can use `attributes` argument in `use` which must be either list
  of attributes which are names of 1-argument functions in current module that
  must return string value of the attribute, or map/keyword list of one of:

  - `atom` - which is name of the called function
  - `{module, function}` - which will call `apply(module, function, [conn])`
  - `{module, function, args}` - which will prepend `conn` to the given arguments
    and call `apply(module, function, [conn | args])`


  Example:

  ```elixir
  defmodule MyAppWeb.TraceWithCustomAttribute do
    use Opencensus.Plug.Trace, attributes: [:method]

    def method(conn), do: conn.method
  end
  ```
  """

  @enforce_keys [:span_name, :tags, :conn_fields]
  defstruct @enforce_keys

  @doc """
  Return name for current span. By defaut returns `"plug"`
  """
  @callback span_name(Plug.Conn.t()) :: String.t()

  @doc """
  Return tuple containing span status and message. By default return value
  status assigned by [default mapping](https://opencensus.io/tracing/span/status/)
  and empty message.
  """
  @callback span_status(Plug.Conn.t()) :: {integer(), String.t()}

  defmacro __using__(opts) do
    attributes = Keyword.get(opts, :attributes, [])

    quote bind_quoted: [mod: __MODULE__, attributes: attributes] do
      @behaviour Plug
      @behaviour mod

      def init(opts), do: opts

      def call(conn, _opts) do
        conn = mod.load_ctx(conn)

        attributes = Opencensus.Plug.get_attributes(conn, __MODULE__, attributes)

        :ocp.with_child_span(span_name(conn), attributes)

        Plug.Conn.register_before_send(conn, fn conn ->
          {status, msg} = span_status(conn)

          :ocp.set_status(status, msg)

          :ocp.finish_span()

          conn
        end)
      end

      defoverridable span_name: 1, span_status: 1

      def span_name(_conn), do: "plug"

      def span_status(conn),
        do: {:opencensus.http_status_to_trace_status(conn.status), ""}
    end
  end

  @doc false
  def load_ctx(conn) do
    header = :oc_span_ctx_header.field_name()

    with [val] <- Plug.Conn.get_req_header(conn, header),
         ctx when ctx != :undefined <- :oc_span_ctx_header.decode(val) do
      :ocp.with_span_ctx(ctx)
    end

    encoded =
      :ocp.current_span_ctx()
      |> :oc_span_ctx_header.encode()
      |> :erlang.iolist_to_binary()

    Logger.metadata(tracespan: encoded)

    Plug.Conn.put_resp_header(conn, header, encoded)
  end
end
