defmodule Opencensus.Plug.TraceTest do
  use ExUnit.Case
  use Plug.Test

  alias Opencensus.Plug.Trace, as: Subject

  @trace_version "00"
  @trace_id "00000000000000000000000000000001"
  @span_id "0000000000000001"
  @trace_options "01"

  @encoded Enum.join([@trace_version, @trace_id, @span_id, @trace_options], "-")

  doctest Subject

  setup do
    on_exit(fn ->
      :ocp.finish_span()

      :ok
    end)
  end

  describe "__using__/1" do
    defmodule SamplePlug do
      use Subject
    end

    setup do: [conn: conn(:get, "/")]

    test "sets 'traceparent' response header", %{module: module, conn: conn} do
      assert Code.compile_quoted(module)

      conn = SamplePlug.call(conn, [])

      assert [_] = get_resp_header(conn, "traceparent")
    end

    test "span longs as long as request", %{conn: conn} do
      conn = SamplePlug.call(conn, [])
      refute :undefined == :ocp.current_span_ctx()

      _ = send_resp(conn, 200, "")
      assert :undefined == :ocp.current_span_ctx()
    end

    test "after response the parent span continues", %{conn: conn} do
      ctx = :oc_trace.start_span("span", :undefined, %{})

      header =
        ctx
        |> :oc_span_ctx_header.encode()
        |> List.to_string()

      _ =
        conn
        |> put_req_header(:oc_span_ctx_header.field_name(), header)
        |> SamplePlug.call([])
        |> send_resp(200, "")

      assert ctx == :ocp.current_span_ctx()
    end
  end

  describe "set_logger_metadata/1" do
    setup do
      :ocp.with_child_span("example")

      [ctx: :ocp.current_span_ctx()]
    end

    for key <- ~w[trace_id span_id trace_options]a do
      test "#{key} is present", %{ctx: ctx} do
        assert :ok = Subject.set_logger_metadata(ctx)
        assert Keyword.has_key?(Logger.metadata(), unquote(key))
      end
    end
  end

  describe "put_ctx_resp_header/3" do
    setup do
      :ocp.with_child_span("example")

      [conn: conn(:get, "/"), ctx: :ocp.current_span_ctx()]
    end

    test "sets response header", %{conn: conn, ctx: ctx} do
      conn = Subject.put_ctx_resp_header(conn, "trace-header", ctx)

      assert [_] = get_resp_header(conn, "trace-header")
    end

    test "response header is always lowercased", %{conn: conn, ctx: ctx} do
      conn = Subject.put_ctx_resp_header(conn, "Trace-Header", ctx)

      assert [_] = get_resp_header(conn, "trace-header")
    end
  end

  describe "load_ctx/2" do
    setup do: [conn: conn(:get, "/")]

    test "sets current span context when header is present", %{conn: conn} do
      conn =
        conn
        |> put_req_header("trace-header", @encoded)

      assert :ok = Subject.load_ctx(conn, "trace-header")
      assert :undefined != :ocp.current_span_ctx()
    end

    test "do not set context when header is empty", %{conn: conn} do
      assert :ok = Subject.load_ctx(conn, "trace-header")
      assert :undefined = :ocp.current_span_ctx()
    end

    test "do not set context when header is invalid", %{conn: conn} do
      conn = put_req_header(conn, "trace-header", "foo-bar")

      assert :ok = Subject.load_ctx(conn, "trace-header")
      assert :undefined = :ocp.current_span_ctx()
    end
  end
end
