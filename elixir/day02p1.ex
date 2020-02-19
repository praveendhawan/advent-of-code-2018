defmodule Parser do

  def parse(path) do
    path
    |> read_file
    |> parse_input
  end

  defp read_file(path) do
    path
    |> File.read!
    |> String.trim
  end

  defp parse_input(file_content) do
    file_content
    |> String.split(~r/\n/)
  end
end


defmodule InventoryManagement do
  import Parser, only: [parse: 1]

  def scan_ids(input_file) do
    input_file
    |> parse
    |> Enum.map(fn x -> perform(x) end)
    |> Enum.reduce({0, 0}, fn [two_count, three_count], {twos, threes} ->
      { twos + two_count, threes + three_count }
    end)
    |> rudimentary_checksum
  end

  defp perform(input) do
    letter_frequencies(input)
    |> Keyword.values
    |> Enum.uniq
    |> Enum.reduce([0, 0], fn x, [two, three] ->
      case x do
        1 ->
          [two, three]
        2 ->
          [1, three]
        3 ->
          [two, 1]
      end
    end)
  end

  defp letter_frequencies(input) do
    input
    |> String.codepoints
    |> Enum.map(fn x -> String.to_atom(x) end)
    |> Enum.reduce(Keyword.new, fn x, acc ->
      current_frequency = Keyword.get(acc, x, 0)
      Keyword.put(acc, x, current_frequency + 1)
    end)
  end

  defp rudimentary_checksum({two_letter_count, three_letter_count}) do
    two_letter_count * three_letter_count
  end
end
