import gleam/dict
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/order
import gleam/result
import gleam/string
import non_empty_list.{type NonEmptyList}
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

  use top_joltages <- result.try(
    banks
    |> list.zip(list.range(0, banks_len))
    |> list.try_map(fn(tuple) { get_max_joltage(tuple.0, 12) })
    |> result.map_error(fn(_) { "Could not find highest combo" }),
  )

  let answer = int.sum(top_joltages)

  io.println("Answer: " <> string.inspect(answer))
  Ok(Nil)
}

pub fn get_max_joltage(str: String, target_length: Int) -> Result(Int, Nil) {
  get_max_joltage_help(string.to_graphemes(str), "", target_length)
  |> result.try(fn(r) { int.parse(r) })
}

pub fn get_max_joltage_help(
  graphemes: List(String),
  str_so_far: String,
  slots_remaining: Int,
) -> Result(String, Nil) {
  case slots_remaining > 0 {
    True -> {
      use best_picks <- result.try(pick_best_number(graphemes, slots_remaining))
      let next_str_so_far = str_so_far <> best_picks.0

      // For each candidate digit, finish calcuating joltage but only keep the
      // highest one
      let next_best =
        best_picks.1
        |> non_empty_list.map(fn(index) {
          let next_graphemes = list.drop(graphemes, index + 1)
          get_max_joltage_help(
            next_graphemes,
            next_str_so_far,
            slots_remaining - 1,
          )
        })
        |> non_empty_list.to_list
        |> list.filter_map(function.identity)
        |> list.map(fn(str) {
          #(str, int.parse(str) |> result.lazy_unwrap(fn() { panic }))
        })
        |> list.sort(fn(a, b) { int.compare(b.1, a.1) })
        |> list.first
        |> result.map(fn(tuple) { tuple.0 })

      next_best
    }
    False -> Ok(str_so_far)
  }
}

// Picks the highest digit in the list, and returns a list of all the indexes
// where it occurs. Does not include the indexes where we would not have enough
// extra digits to fill the desired slots.
pub fn pick_best_number(
  graphemes: List(String),
  slots_remaining: Int,
) -> Result(#(String, NonEmptyList(Int)), Nil) {
  let max_index = list.length(graphemes) - slots_remaining
  graphemes
  // First, pair each graphemes with an index
  |> list.zip(list.range(0, list.length(graphemes)))
  // Then, filter out any indexes that would result in us not having enough
  // graphemes to fill later slots
  |> list.filter(fn(tuple) { tuple.1 <= max_index })
  // Bucket each grapheme into a dict where the key is the grapheme and th values
  // are the list of indexes
  |> list.fold(dict.new(), fn(acc, cur) {
    dict.upsert(acc, cur.0, fn(opt) {
      case opt {
        option.Some(existing) -> non_empty_list.prepend(existing, cur.1)
        option.None -> non_empty_list.new(cur.1, [])
      }
    })
  })
  // Bucket each grapheme into a dictio
  |> dict.to_list
  // Then sort the list by graphemes decending
  |> list.sort(fn(a, b) { string.compare(b.0, a.0) })
  // Get the first elem of the sorted list
  |> list.first
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
