defmodule MaxWeightMatching.Viz.EdgeParserTest do
  use ExUnit.Case, async: true

  alias MaxWeightMatching.Viz.EdgeParser

  describe "parse/1" do
    test "parses comma-separated lines" do
      assert {:ok, [{0, 1, 7}, {2, 3, 5}]} = EdgeParser.parse("0, 1, 7\n2, 3, 5")
    end

    test "parses space-separated lines" do
      assert {:ok, [{0, 1, 7}]} = EdgeParser.parse("0 1 7")
    end

    test "parses mixed delimiters" do
      assert {:ok, [{0, 1, 7}]} = EdgeParser.parse("0,  1,  7")
    end

    test "skips blank lines" do
      assert {:ok, [{0, 1, 7}]} = EdgeParser.parse("\n0, 1, 7\n\n")
    end

    test "returns error for non-integer values" do
      assert {:error, "Invalid number in: " <> _} = EdgeParser.parse("0, 1, abc")
    end

    test "returns error for wrong number of values" do
      assert {:error, "Expected 3 values per line" <> _} = EdgeParser.parse("0, 1")
    end

    test "returns first error when multiple lines are bad" do
      assert {:error, _} = EdgeParser.parse("0, 1\n2, 3")
    end
  end

  describe "format/1" do
    test "formats edges as comma-separated lines" do
      assert EdgeParser.format([{0, 1, 7}, {2, 3, 5}]) == "0, 1, 7\n2, 3, 5"
    end

    test "round-trips through parse" do
      edges = [{0, 1, 7}, {2, 3, 5}, {3, 4, 6}]
      assert {:ok, ^edges} = edges |> EdgeParser.format() |> EdgeParser.parse()
    end
  end

  describe "encode/1" do
    test "encodes edges as pipe-separated string" do
      assert EdgeParser.encode([{0, 1, 10}, {2, 3, 8}]) == "0,1,10|2,3,8"
    end

    test "single edge" do
      assert EdgeParser.encode([{0, 1, 5}]) == "0,1,5"
    end
  end

  describe "decode/1" do
    test "decodes pipe-separated string" do
      assert {:ok, [{0, 1, 10}, {2, 3, 8}]} = EdgeParser.decode("0,1,10|2,3,8")
    end

    test "single edge" do
      assert {:ok, [{0, 1, 5}]} = EdgeParser.decode("0,1,5")
    end

    test "returns error for invalid segment" do
      assert {:error, _} = EdgeParser.decode("0,1,abc")
    end

    test "returns error for wrong number of values" do
      assert {:error, _} = EdgeParser.decode("0,1")
    end

    test "returns error for empty string" do
      assert {:error, _} = EdgeParser.decode("")
    end

    test "returns error for nil" do
      assert {:error, _} = EdgeParser.decode(nil)
    end

    test "round-trips through encode" do
      edges = [{0, 1, 10}, {2, 3, 8}, {4, 5, 6}]
      assert {:ok, ^edges} = edges |> EdgeParser.encode() |> EdgeParser.decode()
    end
  end
end
