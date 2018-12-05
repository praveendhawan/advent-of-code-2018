defmodule AlchemyReduce do
  def call(file_stream) do
    file_stream
    |> parse_stream
    |> IO.inspect
    |> reduce("")
    |> IO.inspect(label: 'reduced polymer')
    |> String.length
    |> IO.inspect
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

      test "parse_stream" do
        {:ok, io} = StringIO.open("""
          dabAcCaCBAcCcaDA
        """)

        assert call(IO.stream(io, 10)) == 10
      end
    end

  [input_file] ->
    input_file
    |> File.stream!([], :line)
    |> AlchemyReduce.call()

  _ ->
    IO.puts :stderr, "we expected --test or an input file"
    System.halt(1)
end
