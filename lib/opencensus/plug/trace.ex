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

  - `c:span_name/1` - defaults to request path
  - `c:span_status/1` - defaults to mapping of reponse code to OpenCensus span
    value, see `:opencensus.http_status_to_trace_status/1`.

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
  @callback span_name(Plug.Conn.t(), options :: term()) :: String.t()

  @doc """
  Return tuple containing span status and message. By default return value
  status assigned by [default mapping](https://opencensus.io/tracing/span/status/)
  and empty message.
  """
  @callback span_status(Plug.Conn.t(), options :: term()) :: {integer(), String.t()}

  defmacro __using__(opts) do
    attributes = Keyword.get(opts, :attributes, [])

    quote do
      @behaviour Plug
      @behaviour unquote(__MODULE__)

      def init(opts), do: opts

      def call(conn, opts) do
        apply(
          &unquote(__MODULE__).call_with_module_and_attributes/4,
          [conn, opts, __MODULE__, unquote(attributes)]
        )
      end

      def span_name(conn, _opts), do: conn.request_path

      def span_status(conn, _opts),
        do: {:opencensus.http_status_to_trace_status(conn.status), ""}

      defoverridable span_name: 2, span_status: 2
    end
  end

  ## PRIVATE

  require Record

  Record.defrecordp(
    :ctx,
    Record.extract(:span_ctx, from_lib: "opencensus/include/opencensus.hrl")
  )

  @doc false
  def call_with_module_and_attributes(conn, opts, module, attributes) do
    parent_span_ctx = :oc_propagation_http_tracecontext.from_headers(conn.req_headers)
    _ = :ocp.with_span_ctx(parent_span_ctx)

    user_agent =
      conn
      |> Plug.Conn.get_req_header("user-agent")
      |> List.first()

    default_attributes = %{
      "http.host" => conn.host,
      "http.method" => conn.method,
      "http.path" => conn.request_path,
      "http.user_agent" => user_agent,
      "http.url" => Plug.Conn.request_url(conn)

      # TODO: How do we get this?
      # "http.route" => ""
    }

    attributes = Opencensus.Plug.get_tags(conn, module, attributes)

    _ =
      :ocp.with_child_span(
        apply(&module.span_name/2, [conn, opts]),
        Map.merge(default_attributes, attributes)
      )

    span_ctx = :ocp.current_span_ctx()

    :ok = __MODULE__.set_logger_metadata(span_ctx)

    conn
    |> Plug.Conn.put_private(:opencensus_span_ctx, span_ctx)
    |> __MODULE__.put_ctx_resp_header(span_ctx)
    |> Plug.Conn.register_before_send(fn conn ->
      {status, msg} = apply(&module.span_status/2, [conn, opts])

      :oc_trace.put_attribute("http.status_code", Integer.to_string(conn.status), span_ctx)

      :oc_trace.set_status(status, msg, span_ctx)
      :oc_trace.finish_span(span_ctx)
      _ = :ocp.with_span_ctx(parent_span_ctx)

      conn
    end)
  end

  @doc false
  def set_logger_metadata(span) do
    trace_id = List.to_string(:io_lib.format("~32.16.0b", [ctx(span, :trace_id)]))
    span_id = List.to_string(:io_lib.format("~16.16.0b", [ctx(span, :span_id)]))

    Logger.metadata(
      trace_id: trace_id,
      span_id: span_id,
      trace_options: ctx(span, :trace_options)
    )

    :ok
  end

  @doc false
  def put_ctx_resp_header(conn, span_ctx) do
    headers =
      for {k, v} <- :oc_propagation_http_tracecontext.to_headers(span_ctx) do
        {k, List.to_string(v)}
      end

    Plug.Conn.prepend_resp_headers(conn, headers)
  end
end
