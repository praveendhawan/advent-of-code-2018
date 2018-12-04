defmodule NightShift do
  def sleeping_guard_minute(file_stream) do
    file_stream
    |> parse_stream
    |> sort_stream_by_time
    |> transform_to_sleep_data
    |> get_checksum
  end

  def parse_stream(file_stream) do
    file_stream
    |> Enum.reduce([], fn schedule, acc ->
      [date_time, desc] =
        schedule
        |> String.split(["[", "]"], trim: true)

      desc = String.trim(desc)
      { :ok, date_time } = NaiveDateTime.from_iso8601(date_time <> ":00")
      [[date_time, desc] | acc]
    end)
  end

  def sort_stream_by_time(parsed_stream) do
    parsed_stream
    |> Enum.sort_by(fn [naive_date | _] ->
      {naive_date.year, naive_date.month, naive_date.day, naive_date.hour, naive_date.minute}
    end)
  end

  def transform_to_sleep_data(sorted_stream) do
    sorted_stream
    |> Enum.reduce(%{}, fn [date_time, desc], acc ->
      cond do
        Regex.run(~r/#(\d+)/, desc) ->
          guard_id = Regex.run(~r/#(\d+)/, desc) |> hd
          Map.put(acc, :current_guard_id, guard_id)
        Regex.run(~r/falls asleep/, desc) ->
          guard_id = Map.get(acc, :current_guard_id)
          minute = date_time.minute

          guard_details =
            Map.get(acc, guard_id, %{})
            |> Map.put(:sleep_starts_at, minute)
            |> Map.put_new(:total_slept, 0)
            |> Map.put_new(:minute_frequency, %{})
          Map.put(acc, guard_id, guard_details)
        Regex.run(~r/wakes up/, desc) ->
          minute = date_time.minute
          guard_id = Map.get(acc, :current_guard_id)
          guard_details = Map.get(acc, guard_id)
          minute_frequency = Map.get(guard_details, :minute_frequency)
          sleep_starts_at = Map.get(guard_details, :sleep_starts_at)

          {_, guard_details } =
            Map.get_and_update(guard_details, :total_slept, fn x ->
              {x, x + minute - sleep_starts_at}
            end)

          minute_frequency =
            Enum.reduce(sleep_starts_at..(minute-1), minute_frequency, fn min, acc ->
              {_, acc} =
                Map.get_and_update(acc, min, fn x ->
                  {x, (x || 0) + 1}
                end)
              acc
            end)
          guard_details =
            Map.put(guard_details, :minute_frequency, minute_frequency)
            |>  Map.put(:sleep_starts_at, nil)
          Map.put(acc, guard_id, guard_details)
      end
    end)
    |> Map.drop([:current_guard_id])
    |> Enum.max_by(fn { _guard_id, guard_details } ->
      Map.get(guard_details, :total_slept, 0)
    end)
  end

  def get_checksum({guard_id, %{ minute_frequency: minute_frequency }}) do
    { max_min_freq, _ } =
      minute_frequency
      |> Enum.max_by(fn { _, frequency } -> frequency end)

    guard_id =
      guard_id
      |> String.replace("#", "")
      |> String.to_integer

    max_min_freq * guard_id
  end
end

case System.argv() do
  ["--test"] ->
    ExUnit.start()

    defmodule NightShiftTest do
      use ExUnit.Case

      import NightShift

      test "parse_stream" do
        {:ok, io} = StringIO.open("""
        [1518-11-01 00:00] Guard #10 begins shift
        """)

        assert parse_stream(IO.stream(io, :line)) ==
          [[~N[1518-11-01 00:00:00], "Guard #10 begins shift"]]
      end

      test "sort_stream_by_time" do
        {:ok, io} = StringIO.open("""
        [1518-11-01 00:00] Guard #10 begins shift
        [1518-11-01 00:55] wakes up
        [1518-11-01 00:25] wakes up
        [1518-11-01 00:05] falls asleep
        """)

        parsed_stream = parse_stream(IO.stream(io, :line))

        assert sort_stream_by_time(parsed_stream)  ==
          [
            [~N[1518-11-01 00:00:00], "Guard #10 begins shift"],
            [~N[1518-11-01 00:05:00], "falls asleep"],
            [~N[1518-11-01 00:25:00], "wakes up"],
            [~N[1518-11-01 00:55:00], "wakes up"]
          ]
      end

      test "transform_to_sleep_data" do
        {:ok, io} = StringIO.open("""
        [1518-11-05 00:03] Guard #99 begins shift
        [1518-11-01 00:05] falls asleep
        [1518-11-04 00:46] wakes up
        [1518-11-01 00:25] wakes up
        [1518-11-01 00:30] falls asleep
        [1518-11-01 00:55] wakes up
        [1518-11-01 23:58] Guard #99 begins shift
        [1518-11-02 00:50] wakes up
        [1518-11-03 00:05] Guard #10 begins shift
        [1518-11-03 00:24] falls asleep
        [1518-11-02 00:40] falls asleep
        [1518-11-03 00:29] wakes up
        [1518-11-01 00:00] Guard #10 begins shift
        [1518-11-04 00:02] Guard #99 begins shift
        [1518-11-04 00:36] falls asleep
        [1518-11-05 00:45] falls asleep
        [1518-11-05 00:55] wakes up
        """)

        sorted_stream_data =
          IO.stream(io, :line)
          |> parse_stream
          |> sort_stream_by_time

        assert transform_to_sleep_data(sorted_stream_data) == {"#10", %{sleep_starts_at: 24, total_slept: 50, minute_frequency: %{48 => 1, 11 => 1, 39 => 1, 34 => 1, 26 => 1, 52 => 1, 15 => 1, 20 => 1, 50 => 1, 17 => 1, 25 => 1, 13 => 1, 44 => 1, 8 => 1, 36 => 1, 7 => 1, 32 => 1, 37 => 1, 35 => 1, 45 => 1, 6 => 1, 49 => 1, 41 => 1, 33 => 1, 42 => 1, 43 => 1, 10 => 1, 9 => 1, 19 => 1, 51 => 1, 14 => 1, 5 => 1, 54 => 1, 18 => 1, 31 => 1, 22 => 1, 21 => 1, 27 => 1, 24 => 2, 47 => 1, 40 => 1, 30 => 1, 23 => 1, 28 => 1, 46 => 1, 53 => 1, 16 => 1, 38 => 1, 12 => 1}}}
      end

      test "sleeping_guard_minute" do
        {:ok, io} = StringIO.open("""
        [1518-11-01 00:00] Guard #10 begins shift
        [1518-11-01 00:05] falls asleep
        [1518-11-01 00:25] wakes up
        [1518-11-01 00:30] falls asleep
        [1518-11-01 00:55] wakes up
        [1518-11-01 23:58] Guard #99 begins shift
        [1518-11-02 00:40] falls asleep
        [1518-11-02 00:50] wakes up
        [1518-11-03 00:05] Guard #10 begins shift
        [1518-11-03 00:24] falls asleep
        [1518-11-03 00:29] wakes up
        [1518-11-04 00:02] Guard #99 begins shift
        [1518-11-04 00:36] falls asleep
        [1518-11-04 00:46] wakes up
        [1518-11-05 00:03] Guard #99 begins shift
        [1518-11-05 00:45] falls asleep
        [1518-11-05 00:55] wakes up
        """)

        assert sleeping_guard_minute(IO.stream(io, :line)) == 240
      end
    end

  [input_file] ->
    input_file
    |> File.stream!([], :line)
    |> NightShift.sleeping_guard_minute()
    |> IO.puts

  _ ->
    IO.puts :stderr, "we expected --test or an input file"
    System.halt(1)
end
