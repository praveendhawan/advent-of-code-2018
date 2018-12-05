# This solution is not optimum
# It takes too log to compute the polymer reduction
# like 1-2 min the 1 reduction
defmodule AlchemyReduce do
  def call(file_stream) do
    file_stream
    |> parse_stream
    |> reduce("")
    |> String.length
    |> IO.inspect
  end

  def shortest_polymer(file_stream) do
    {_, shortest_length } =
      file_stream
      |> parse_stream
      |> reduced_faulty_unit_removed_polymers
      |> Enum.min_by(fn {_x, polymer_length } -> polymer_length end)
      |> IO.inspect(label: "minimum found")
    shortest_length
  end

  defp reduced_faulty_unit_removed_polymers(parsed_stream) do
    65..90
    |> Enum.reduce(%{}, fn x, acc ->
      reduced_polymer_length =
        parsed_stream
        |> String.replace(<< x >>, "")
        |> String.replace(<< x + 32 >>, "")
        |> reduce("")
        |> String.length
        |> IO.inspect(label: "reduced length for #{x}")

      Map.put(acc, x, reduced_polymer_length)
    end)
  end

  defp parse_stream(file_stream) do
    file_stream
    |> Enum.map(fn x -> x |> String.trim end)
    |> List.to_string
  end

  defp reduce(<< current, next >> <> "", reduced) do
    if reducable?(current, next) do
      reduced
    else
      reduced <> << current, next >>
    end
  end

  defp reduce(<< current, next >> <> rest, reduced) do
    if reducable?(current, next) do
      reduce(reduced <> rest, "")
    else
      reduce(<< next >> <> rest, reduced <> << current >>)
    end
  end

  defp reducable?(first, second), do: absolute_difference(first, second) == 32

  defp absolute_difference(first, second) when first >= second, do: first - second

  defp absolute_difference(first, second) when second > first, do: second - first
end

case System.argv() do
  ["--test"] ->
    ExUnit.start()

    defmodule AlchemyReduceTest do
      use ExUnit.Case

      import AlchemyReduce

      test "call" do
        {:ok, io} = StringIO.open("""
          dabAcCaCBAcCcaDA
        """)

        assert call(IO.stream(io, 10)) == 10
      end

      test "shortest_polymer" do
        {:ok, io} = StringIO.open("""
          dabAcCaCBAcCcaDA
        """)

        assert shortest_polymer(IO.stream(io, 10)) == 4
      end
    end

  [input_file] ->
    input_file
    |> File.stream!([], :line)
    |> AlchemyReduce.shortest_polymer()

  _ ->
    IO.puts :stderr, "we expected --test or an input file"
    System.halt(1)
end
