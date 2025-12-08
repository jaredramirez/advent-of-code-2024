import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import simplifile

import help
import puzzle

// -----------------------------------------------------------------------------
// Part 1

pub fn part_1_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(part_1_input(input))

  let banks =
    input_str
    |> string.trim
    |> string.split(on: "\n")

  use top_combos <- result.try(
    banks
    |> list.try_map(get_highest_combo)
    |> result.map_error(fn(_) { "Could not find highest combo" }),
  )

  use top_combo_ints <- result.try(
    top_combos
    |> list.try_map(int.parse)
    |> result.map_error(fn(_) { "Some combo not  number" }),
  )

  io.println("Answer: " <> string.inspect(int.sum(top_combo_ints)))
  Ok(Nil)
}

/// Check if a number is a plaindrome
pub fn get_highest_combo(string: String) -> Result(String, Nil) {
  let graphemes =
    string
    |> string.to_graphemes

  assert list.all(graphemes, fn(g) {
    list.contains(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"], g)
  })

  let pairs =
    graphemes
    |> list.index_map(fn(g, i) {
      let rest_of_list = list.drop(graphemes, i + 1)
      list.map(rest_of_list, fn(sub_g) { g <> sub_g })
    })
    |> list.flatten

  let sorted =
    list.sort(pairs, fn(a, b) { string.compare(a, b) |> order.negate })

  case sorted {
    [head, ..] -> Ok(head)
    _ -> Error(Nil)
  }
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
    puzzle.Sample -> simplifile.read(from: "./src/days/day3/sample.txt")
    puzzle.Full -> simplifile.read(from: "./src/days/day3/full.txt")
  }
  |> result.map_error(string.inspect)
}
