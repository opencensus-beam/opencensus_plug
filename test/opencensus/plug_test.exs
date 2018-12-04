defmodule Opencensus.PlugTest do
  use ExUnit.Case

  alias Opencensus.Plug, as: Subject

  doctest Subject

  defmodule Foo do
    def foo(_), do: "foo"

    def bar(%{bar: value}), do: value
  end

  defmodule Bar do
    def foo(_), do: "boo"

    def bar(_, value), do: value
  end

  describe "get_tags/3" do
    test "for empty list, returns empty map" do
      assert %{} == Subject.get_tags(%{}, Foo, [])
    end

    test "for single atom returns function return value" do
      assert %{foo: "foo"} == Subject.get_tags(%{}, Foo, [:foo])
    end

    test "for tag with atom alias return aliased tag" do
      assert %{quux: "foo"} == Subject.get_tags(%{}, Foo, quux: :foo)
    end

    test "for {m, f} tuple, return function return value" do
      assert %{foo: "boo"} == Subject.get_tags(%{}, Foo, foo: {Bar, :foo})
    end

    test "for {m, f, a} tuple, return function return value" do
      assert %{foo: "baz"} == Subject.get_tags(%{}, Foo, foo: {Bar, :bar, ["baz"]})
    end

    test "given function can access first argument" do
      assert %{bar: "bar"} == Subject.get_tags(%{bar: "bar"}, Foo, [:bar])
    end
  end
end
