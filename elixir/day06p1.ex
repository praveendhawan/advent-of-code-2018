defmodule ChronalCoordinates do
  def call(file_stream) do
    given_coordinates = parse_stream(file_stream)
    [min_x, max_x, min_y, max_y] = min_max_x_y(given_coordinates)
    all_points = [min_x, max_x, min_y, max_y] |> all_coordinates
    # boundary_points = min_max_x_y(given_coordinates) |> boundary_coordinates

    all_points_min_dist_details =
      all_points
      |> Enum.reduce(%{}, fn x, all_point_details ->
        given_details =
          given_coordinates
          |> Enum.reduce(%{}, fn y, given_distance_details ->
            Map.put(given_distance_details, y, manhattan_distance(x , y))
          end)

        { _, min_distance } =
          given_details
          |> Enum.min_by(fn {_p2, dist} -> dist end)

        given_details_with_min_filter =
          given_details
          |> Enum.filter(fn {_p2, dist} -> dist == min_distance end)
        Map.put(all_point_details, x, given_details_with_min_filter)
      end)

    area_details =
      all_points_min_dist_details
      |> Enum.reduce(%{}, fn {{x, y}, dist_details}, acc ->
        if length(dist_details) > 1 do
          acc
        else
          { point, _ } = hd(dist_details)
          if x in [min_x, max_x] || y in [min_y, max_y] do
            already_rejected = Map.get(acc, :rejected_points, MapSet.new)
            Map.put(acc, :rejected_points, MapSet.put(already_rejected, point))
          else
            current_count = Map.get(acc, point, 0)
            Map.put(acc, point, current_count + 1)
          end
        end
      end)

    { rejected_points, area_details } = Map.pop(area_details, :rejected_points, MapSet.new)

    rejected_points = MapSet.to_list(rejected_points)

    {_p, dist} =
      area_details
      |> Enum.filter(fn {p, _area} -> !(p in rejected_points)end)
      |> IO.inspect(label: "rejected points filtered areas")
      |> Enum.max_by(fn {_p, dist} -> dist end)
      |> IO.inspect(label: "maximum")
    dist
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

  # defp boundary_coordinates([min_x, max_x, min_y, max_y] = min_max_x_y_details) do
  #   min_max_x_y_details
  #   |> all_coordinates
  #   |> Enum.filter(fn {x, y} ->
  #     x in [min_x, max_x] || y in [min_y, max_y]
  #   end)
  # end

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

    assert call(IO.stream(io, :line)) == 17
      end
    end

  [input_file] ->
    input_file
    |> File.stream!([], :line)
    |> ChronalCoordinates.call()

  _ ->
    IO.puts :stderr, "we expected --test or an input file"
    System.halt(1)
end
