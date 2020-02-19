defmodule SumOfItsParts do
  def call(file_stream) do
    parsed_steps =
      file_stream
      |> parse

    build_requirement_matrix(parsed_steps)
    |> determine_step_order([])
  end

  # returns the order in which we have to run the step
  # "CABDFE"
  defp determine_step_order(requirements_matrix, steps) when requirements_matrix == %{} do
    steps
    |> Enum.reverse
    |> List.to_string
  end

  defp determine_step_order(requirements_matrix, []) do
    step_to_perform = requirements_matrix |> get_step_with_no_requisite

    new_requirements_matrix = step_to_perform |> perform_step(requirements_matrix)

    determine_step_order(new_requirements_matrix, [step_to_perform])
  end

  defp determine_step_order(requirements_matrix, previous_steps) do
    step_to_perform = requirements_matrix |> get_step_with_no_requisite

    new_requirements_matrix = step_to_perform |> perform_step(requirements_matrix)

    determine_step_order(new_requirements_matrix, [step_to_perform | previous_steps])
  end

  # give the step to perform now
  # get_step_with_no_requisite(%{"A" => ["C"], "B" => ["A", "C"], "C" => [], "D" => []})
  # returns "C" as it has no requirements and alphabetically smaller than "D"
  defp get_step_with_no_requisite(requirements_matrix) do
    requirements_matrix
    |> Enum.reduce([], fn { step, requirements }, acc ->
      case requirements do
        [] -> [step | acc]
        _ -> acc
      end
    end)
    |> Enum.min
  end

  # returns new matrix with the step performed -> deletes step from matrix as key and as requirement
  # perform_step("C", %{"A" => ["C"], "B" => ["A", "C"], "C" => []}
  # returns - %{"A" => [], "B" => ["A"]}
  defp perform_step(step_to_perform, requirements_matrix) do
    requirements_matrix
    |> Map.delete(step_to_perform)
    |> Enum.reduce(%{}, fn {step, requirements}, acc ->
      new_requirements =
        if step_to_perform in requirements do
          List.delete(requirements, step_to_perform)
        else
          requirements
        end
      Map.put(acc, step, new_requirements)
    end)
  end

  # parse input to give list with two objects - step to perform and its requirement
  # ["A", "C"]
  # "C" must be performed before "A"
  defp parse(file_stream) do
    file_stream
    |> Enum.map(fn x ->
      "Step " <> <<req>> <>" must be finished before step " <> <<step>> <> " can begin." = String.trim(x)
      [<<step>>, <<req>>]
    end)
  end

  # returns a map for the requirements
  # %{"A" => ["C"], "B" => ["A"], "C" => [], "D" => ["A"], "E" => ["B", "D", "F"], "F" => ["C"]}
  defp build_requirement_matrix(parsed_steps) do
    initial_matrix =
      parsed_steps
      |> all_steps_list
      |> initial_matrix

    parsed_steps
    |> Enum.reduce(initial_matrix, fn [step, req], acc ->
      acc
      |> Map.update(step, [req], &([req | &1] |> Enum.sort))
    end)
  end

  # returns the list of all steps to perform in random order
  # ["A", "B", "C", ...]
  defp all_steps_list(parsed_steps) do
    parsed_steps
    |> Enum.reduce(MapSet.new, fn [step, req], acc -> acc |> MapSet.put(step) |> MapSet.put(req) end)
    |> MapSet.to_list
  end

  # returns empty map for all keys
  # %{"A" => [], "B" => [], ...}
  defp initial_matrix(all_steps) do
    all_steps
    |>  Enum.reduce(%{}, &(Map.put(&2, &1, [])))
  end
end

case System.argv() do
  ["--test"] ->
    ExUnit.start()

    defmodule SumOfItsPartsTest do
      use ExUnit.Case

      import SumOfItsParts
      test "call" do
        {:ok, io} = StringIO.open("""
        Step C must be finished before step A can begin.
        Step C must be finished before step F can begin.
        Step A must be finished before step B can begin.
        Step A must be finished before step D can begin.
        Step B must be finished before step E can begin.
        Step D must be finished before step E can begin.
        Step F must be finished before step E can begin.
        """)

        assert call(IO.stream(io, :line)) == "CABDFE"
      end
    end

  [input_file] ->
    input_file
    |> File.stream!([], :line)
    |> SumOfItsParts.call()
    |> IO.inspect

  _ ->
    IO.puts :stderr, "we expected --test or an input file"
    System.halt(1)
end
