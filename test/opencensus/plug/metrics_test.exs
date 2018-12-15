defmodule Opencensus.Plug.MetricsTest do
  use ExUnit.Case
  use Plug.Test

  alias Opencensus.Plug.Metrics, as: Subject

  doctest Subject

  describe "__using__/1" do
    defmodule SamplePlug do
      use Subject
    end

    setup do
      [metric] = SamplePlug.setup_metrics()

      [conn: conn(:get, "/"), metric: metric]
    end

    test "do not fail when no view defined", %{conn: conn} do
      assert %Plug.Conn{} =
               conn
               |> SamplePlug.call([])
               |> send_resp(200, "")
    end

    test "report request value to view", %{conn: conn, metric: metric} do
      {:ok, view} =
        :oc_stat_view.subscribe(%{
          measure: metric,
          name: "test_metric",
          aggregation: :oc_stat_aggregation_distribution,
          description: "Test"
        })

      %Plug.Conn{} =
        conn
        |> SamplePlug.call([])
        |> send_resp(200, "")

      assert [%{value: %{count: 1}}] = :oc_stat_view.export(view).data.rows
    end
  end
end
