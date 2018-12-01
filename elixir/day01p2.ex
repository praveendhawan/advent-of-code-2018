defmodule Parser do
  def parse(path) do
    path
    |> read_file
    |> parse_input
  end

  defp read_file(path) do
    path
    |> File.read!
  end

  defp parse_input(file_content) do
    file_content
    |> String.trim
    |> String.split(~r/\n/)
  end
end


defmodule FrequencyCalibration do
  import Parser, only: [parse: 1]

  def calibrate(input_file) do
    get_input_list(input_file)
    |> Enum.reduce(0, fn x, acc -> perform(x, acc) end)
  end

  def frequency_achieved_twice(input_file) do
    frequecy_already_achieved = %{0 => 1, previous_frequency: 0}

    input_file
    |> get_input_list
    |> Stream.cycle
    |> Enum.reduce_while(frequecy_already_achieved, fn x, acc -> get_twice_frequncy(x, acc) end)
    |> Map.get(:previous_frequency)
  end

  defp get_twice_frequncy(input, frequecy_already_achieved) do
    previous_frequency = Map.get(frequecy_already_achieved, :previous_frequency, 0)

    current_frequency = perform(input, previous_frequency)

    frequecy_already_achieved =
      Map.put(frequecy_already_achieved, :previous_frequency, current_frequency)

    if Map.has_key?(frequecy_already_achieved, current_frequency) do
      {:halt, frequecy_already_achieved}
    else
      frequecy_already_achieved = Map.put(frequecy_already_achieved, current_frequency, 1)
      {:cont, frequecy_already_achieved}
    end
  end

  defp perform(input, previous_frequency) do
    previous_frequency + input
  end

  defp get_input_list(input_file) do
    input_file
    |> parse
    |> Enum.map(fn x -> String.to_integer(x) end)
  end
end
