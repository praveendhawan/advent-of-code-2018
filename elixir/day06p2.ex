defmodule ChronalCoordinates do
  def call(file_stream, max_limit) do
    given_coordinates = parse_stream(file_stream)
    [min_x, max_x, min_y, max_y] = min_max_x_y(given_coordinates)
    all_points = [min_x, max_x, min_y, max_y] |> all_coordinates

    all_points
    |> Enum.map(fn point ->
      given_coordinates
      |> Enum.map(fn given_point ->
        manhattan_distance(point, given_point)
      end)
      |> Enum.sum
    end)
    |> Enum.filter(fn x -> x < max_limit end)
    |> length
    |> IO.inspect
  end

  defp parse_stream(file_stream) do
    file_stream
    |> Enum.map(fn x ->
      x
      |> String.trim
      |> String.split(", ")
      |> Enum.map(&String.to_integer/1)
    end)
    |> Enum.map(&List.to_tuple/1)
  end

  defp manhattan_distance({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end

  defp all_coordinates([min_x, max_x, min_y, max_y]) do
    for x <- min_x..max_x do
      for y <- min_y..max_y do
        {x, y}
      end
    end
    |> Enum.flat_map(&(&1))
  end

  defp min_max_x_y(parsed_coordinates) do
    parsed_coordinates
    |> Enum.reduce([10, 0, 10, 0], fn { x, y }, [min_x, max_x, min_y, max_y] ->
      min_x = if x < min_x, do: x, else: min_x
      max_x = if x > max_x, do: x, else: max_x
      min_y = if y < min_y, do: y, else: min_y
      max_y = if y > max_y, do: y, else: max_y
      [min_x, max_x, min_y, max_y]
    end)
  end
end

case System.argv() do
  ["--test"] ->
    ExUnit.start()

    defmodule ChronalCoordinatesTest do
      use ExUnit.Case

      import ChronalCoordinates

      test "parse_stream" do
        {:ok, io} = StringIO.open("""
        1, 1
        1, 6
        8, 3
        3, 4
        5, 5
        8, 9
        """)

    assert call(IO.stream(io, :line), 32) == 16
      end
    end

  [input_file] ->
    input_file
    |> File.stream!([], :line)
    |> ChronalCoordinates.call(10000)

  _ ->
    IO.puts :stderr, "we expected --test or an input file"
    System.halt(1)
end
