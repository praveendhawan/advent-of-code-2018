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
    |> Enum.filter(fn x -> contains_two_or_three_same?(x) end)
    |> find_correct_boxes
    |> find_common_letters
  end

  defp contains_two_or_three_same?(input) do
    letter_frequencies(input)
    |> Keyword.values
    |> Enum.uniq
    |> Enum.any?(fn x -> x == 2 || x == 3 end)
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

  defp find_correct_boxes(box_ids) do
    box_ids
    |> Enum.reduce_while([], fn x, _acc ->
      matched_element =
        Enum.find(box_ids, fn y ->
          myers_with_only_one_difference?(x, y)
        end)

      if matched_element do
        {:halt, [x, matched_element]}
      else
        {:cont, []}
      end
    end)
  end

  defp myers_with_only_one_difference?(id_1, id_2) do
    all_deletions =
      String.myers_difference(id_1, id_2)
      |> Keyword.get_values(:del)

    if Enum.count(all_deletions) == 1 do
      [first | _] = all_deletions
      if String.length(first) == 1 do
        true
      else
        false
      end
    else
      false
    end
  end

  defp find_common_letters([first, second]) do
    String.myers_difference(first, second)
    |> Enum.reject(fn {k, _v} -> k != :eq end)
    |> Keyword.values
    |> List.to_string
  end
end
