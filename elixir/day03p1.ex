defmodule ClaimArea do
  def find_common(file_stream) do
    file_stream
    |> parse_stream
    |> Enum.reduce(%{}, & mark_claim(&1, &2))
    |> Map.values
    |> Enum.count(fn x -> x == "x" end)
  end

  # marks the area claimed
  def mark_claim([[left, top], [breadth, length]], map_list) do
    compute_inches_points(left, top, breadth, length)
    |> Enum.reduce(map_list, fn inch_point, acc ->
      if acc[inch_point] do
        put_in acc[inch_point], "x"
      else
        put_in(acc, [inch_point], 1)
      end
    end)
  end

  # gives x,y coordinates for the area covered by claim
  defp compute_inches_points(left, top, breadth, length) do
    1..length
    |> Enum.map(fn x ->
      1..breadth
      |> Enum.map(fn y ->
        "#{left + y},#{top + x}"
      end)
    end)
    |> Enum.concat
  end

  # parses output to integers
  defp parse_stream(file_stream) do
    file_stream
    |> Enum.map(fn x ->
      [_, _, h_l, lxb] = String.split(x, " ")

      [
        String.replace_trailing(h_l, ":", "")
        |> String.split(",")
        |> Enum.map(&(String.to_integer(&1))),
        String.replace_trailing(lxb, "\n", "")
        |> String.split("x")
        |> Enum.map(&(String.to_integer(&1)))
      ]
    end)
  end
end

case System.argv() do
  ["--test"] ->
    ExUnit.start()

    defmodule ClaimAreaTest do
      use ExUnit.Case

      import ClaimArea

      test "final_frequency" do
        {:ok, io} = StringIO.open("""
        #1 @ 1,3: 4x4
        #2 @ 3,1: 4x4
        #3 @ 5,5: 2x2
        """)

        assert find_common(IO.stream(io, :line)) == 4
      end
    end

  [input_file] ->
    input_file
    |> File.stream!([], :line)
    |> ClaimArea.find_common()
    |> IO.puts

  _ ->
    IO.puts :stderr, "we expected --test or an input file"
    System.halt(1)
end
