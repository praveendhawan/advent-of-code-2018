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
    |> String.split(~r/\n/)
  end
end


defmodule FrequencyCalibration do
  import Parser, only: [parse: 1]

  def calibrate(input_file) do
    initital_frequency = 0

    input_file
    |> parse
    |> Enum.reduce(initital_frequency, fn x, acc -> perform(x, acc) end)
  end

  defp perform("", previous_frequency) do
    previous_frequency
  end

  defp perform(input, previous_frequency) do
    input_integer = String.to_integer(input)
    previous_frequency + input_integer
  end
end
