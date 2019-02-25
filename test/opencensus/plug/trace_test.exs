defmodule Opencensus.Plug.TraceTest do
  use ExUnit.Case
  use Plug.Test

  alias Opencensus.Plug.Trace, as: Subject

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

    test "sets 'traceparent' response header", %{conn: conn} do
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

      headers =
        for {k, v} <- :oc_propagation_http_tracecontext.to_headers(ctx) do
          {k, List.to_string(v)}
        end

      _ =
        List.foldl(headers, conn, fn {k, v}, acc -> Plug.Conn.put_req_header(acc, k, v) end)
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
      conn = Subject.put_ctx_resp_header(conn, ctx)

      assert [_] = get_resp_header(conn, "traceparent")
    end
  end
end
