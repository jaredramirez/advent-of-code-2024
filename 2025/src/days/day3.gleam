import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import simplifile

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
  use input_str <- result.try(part_1_input(input))

  let banks =
    input_str
    |> string.trim
    |> string.split(on: "\n")
  let banks_len = list.length(banks)

  io.println("Checking " <> int.to_string(banks_len) <> " banks...")

  use top_joltages <- result.try(
    banks
    |> list.zip(list.range(0, banks_len))
    |> list.try_map(fn(tuple) {
      io.println("Checking bank " <> int.to_string(tuple.1) <> "...")
      get_max_joltage(tuple.0)
    })
    |> result.map_error(fn(_) { "Could not find highest combo" }),
  )

  let answer = int.sum(top_joltages)

  io.println("Answer: " <> string.inspect(answer))
  Ok(Nil)
}

pub fn get_max_joltage(str: String) -> Result(Int, Nil) {
  use int_combos <- result.try(
    str
    |> build_combinations
    |> list.filter(fn(combo) { string.length(combo) == 12 })
    |> list.try_map(int.parse),
  )

  int_combos
  |> list.sort(fn(a, b) { int.compare(b, a) })
  |> list.first
}

pub fn build_combinations(str: String) -> List(String) {
  build_combinations_help("", string.to_graphemes(str))
}

fn build_combinations_help(
  prefix: String,
  graphemes: List(String),
) -> List(String) {
  case graphemes {
    [] -> []
    [first, ..rest] -> {
      // First, get this combo
      let this_combo = prefix <> first

      case string.length(this_combo) > 12 {
        True -> []
        False -> {
          // Then get all nested combos with this prefix
          let others_with_this_combo = build_combinations_help(this_combo, rest)

          // Get other combos for the rest of this list
          let other_combos = build_combinations_help(prefix, rest)

          list.flatten([
            [this_combo],
            others_with_this_combo,
            other_combos,
          ])
        }
      }
    }
  }
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
