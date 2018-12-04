defmodule Opencensus.Plug.Metrics do
  defmacro __using__(opts) do
    prefix = Keyword.get(opts, :prefix, "plug")
    count_name = "#{prefix}/requests/count"
    duration_name = "#{prefix}/requests/duration"

    quote bind_quoted: [count_name: count_name, duration_name: duration_name] do
      @behaviour Plug

      def setup_metrics do
        :oc_stat_measure.new(
          count_name,
          "Total number of HTTP requests made.",
          :requests
        )

        :oc_stat_measure.new(
          duration_name,
          "HTTP request duration in microseconds.",
          :usec
        )
      end

      def init(opts), do: opts

      def call(conn, _opts) do
        start = :erlang.monotonic_time(:microsecond)

        Plug.Conn.register_before_send(conn, fn conn ->
          stop = :erlang.monotonic_time(:microsecond)
          diff = stop - start

          tags = %{
            method: conn.method,
            host: conn.host,
            scheme: conn.scheme
          }

          :ok = :oc_stat.record(tags, duration_name, diff)
          :ok = :oc_stat.record(tags, count_name, 1)

          conn
        end)
      end
    end
  end
end
