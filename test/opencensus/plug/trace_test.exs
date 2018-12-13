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
    setup do
      module =
        quote do
          defmodule SamplePlug do
            use Subject
          end
        end

      [module: module]
    end

    test "code compiles when using module", %{module: module} do
      assert Code.compile_quoted(module)
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
      conn = Subject.put_ctx_resp_header(conn, "tracespan", ctx)

      assert [_] = get_resp_header(conn, "tracespan")
    end

    test "response header is always lowercased", %{conn: conn, ctx: ctx} do
      conn = Subject.put_ctx_resp_header(conn, "TraceSpan", ctx)

      assert [_] = get_resp_header(conn, "tracespan")
    end
  end

  describe "load_ctx/2" do
    setup do: [conn: conn(:get, "/")]

    test "sets current span context when header is present", %{conn: conn} do
      conn =
        conn
        |> put_req_header("tracespan", @encoded)

      assert :ok = Subject.load_ctx(conn, "tracespan")
      assert :undefined != :ocp.current_span_ctx()
    end

    test "do not set context when header is empty", %{conn: conn} do
      assert :ok = Subject.load_ctx(conn, "tracespan")
      assert :undefined = :ocp.current_span_ctx()
    end

    test "do not set context when header is invalid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("tracespan", "foo-bar")

      assert :ok = Subject.load_ctx(conn, "tracespan")
      assert :undefined = :ocp.current_span_ctx()
    end
  end
end
