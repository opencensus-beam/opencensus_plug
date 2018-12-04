defmodule Opencensus.Plug do
  @moduledoc """
  Documentation for Opencensus.Plug.
  """

  @doc false
  def get_tags(conn, module, tags) do
    for {key, {m, f, a}} <- normalise_tags(module, tags), into: %{} do
      {key, apply(m, f, [conn | a])}
    end
  end

  defp normalise_tags(module, tags) do
    Enum.map(tags, fn
      {key, {m, f, a}} -> {key, {m, f, a}}
      {key, {m, f}} -> {key, {m, f, []}}
      {key, f} -> {key, {module, f, []}}
      key -> {key, {module, key, []}}
    end)
  end
end
