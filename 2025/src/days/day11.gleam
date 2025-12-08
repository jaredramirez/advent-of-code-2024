import gleam/io
import gleam/result
import gleam/string
import simplifile

import puzzle

// -----------------------------------------------------------------------------
// Part 1

pub fn part_1_run(input: puzzle.Input) -> Result(Nil, String) {
  use _input_str <- result.try(part_1_input(input))
  io.println("Answer: " <> string.inspect(Nil))
  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Part 2

pub fn part_2_run(input: puzzle.Input) -> Result(Nil, String) {
  use _input_str <- result.try(part_1_input(input))
  io.println("Answer: " <> string.inspect(Nil))
  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Inputs

fn part_1_input(input: puzzle.Input) -> Result(String, String) {
  case input {
    puzzle.Sample -> simplifile.read(from: "./src/days/day11/sample.txt")
    puzzle.Full -> simplifile.read(from: "./src/days/day11/full.txt")
  }
  |> result.map_error(string.inspect)
}
