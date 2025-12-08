import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import help
import simplifile

import puzzle

// -----------------------------------------------------------------------------
// Part 1

pub fn part_1_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(part_1_input(input))

  use ranges <- result.try(
    input_str
    |> string.trim
    |> string.split(on: ",")
    |> list.try_map(fn(str) {
      use tuple <- result.try(
        string.split_once(str, "-")
        |> result.map_error(fn(_) { "Invalid range: " <> str }),
      )
      use lower_bound <- result.try(
        int.parse(tuple.0)
        |> result.map_error(fn(_) { "Invalid upper bound: '" <> tuple.0 <> "'" }),
      )
      use upper_bound <- result.try(
        int.parse(tuple.1)
        |> result.map_error(fn(_) { "Invalid upper bound: '" <> tuple.1 <> "'" }),
      )
      Ok(list.range(lower_bound, upper_bound))
    }),
  )

  let sum_of_invalids =
    list.fold(ranges, 0, fn(acc, cur_range) {
      let invalid_ids =
        cur_range
        |> list.filter_map(fn(cur_id) {
          case is_number_palindrome(cur_id) {
            True -> Ok(cur_id)
            False -> Error(Nil)
          }
        })
      acc + int.sum(invalid_ids)
    })

  io.println("Answer: " <> int.to_string(sum_of_invalids))

  Ok(Nil)
}

/// Check if a number is a plaindrome
pub fn is_number_palindrome(num: Int) -> Bool {
  let str = int.to_string(num)
  let str_len = string.length(str)

  case Nil {
    _ if str_len == 0 -> False
    _ if str_len % 2 == 0 -> {
      let first_half = string.slice(from: str, at_index: 0, length: str_len / 2)
      string.ends_with(str, first_half)
    }
    _ -> {
      // If the string length is odd, then it cannot be a plaindrome
      False
    }
  }
}

// -----------------------------------------------------------------------------
// Part 2

pub fn part_2_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(part_1_input(input))

  use ranges <- result.try(
    input_str
    |> string.trim
    |> string.split(on: ",")
    |> list.try_map(fn(str) {
      use tuple <- result.try(
        string.split_once(str, "-")
        |> result.map_error(fn(_) { "Invalid range: " <> str }),
      )
      use lower_bound <- result.try(
        int.parse(tuple.0)
        |> result.map_error(fn(_) { "Invalid upper bound: '" <> tuple.0 <> "'" }),
      )
      use upper_bound <- result.try(
        int.parse(tuple.1)
        |> result.map_error(fn(_) { "Invalid upper bound: '" <> tuple.1 <> "'" }),
      )
      Ok(list.range(lower_bound, upper_bound))
    }),
  )

  let sum_of_invalids =
    list.fold(ranges, 0, fn(acc, cur_range) {
      let invalid_ids =
        cur_range
        |> list.filter_map(fn(cur_id) {
          case only_looping_substr(cur_id) {
            True -> Ok(cur_id)
            False -> Error(Nil)
          }
        })
      acc + int.sum(invalid_ids)
    })

  io.println("Answer: " <> int.to_string(sum_of_invalids))

  Ok(Nil)
}

/// Check if a number is a plaindrome
pub fn only_looping_substr(num: Int) -> Bool {
  let str = int.to_string(num)
  let str_len = string.length(str)

  help.loop(0, fn(index) {
    let needle = string.slice(from: str, at_index: 0, length: index + 1)
    let haystack = string.slice(from: str, at_index: index + 1, length: str_len)

    assert needle <> haystack == str

    let splits =
      haystack
      |> string.split(on: needle)
    let is_invalid = list.all(splits, fn(str) { string.is_empty(str) })

    let needle_longer_than_haystack =
      string.length(needle) > string.length(haystack)
    case Nil {
      _ if needle_longer_than_haystack -> help.Stop(False)
      _ if is_invalid -> help.Stop(True)
      _ -> help.Continue(index + 1)
    }
  })
}

// -----------------------------------------------------------------------------
// Inputs

fn part_1_input(input: puzzle.Input) -> Result(String, String) {
  case input {
    puzzle.Sample -> simplifile.read(from: "./src/days/day2/sample.txt")
    puzzle.Full -> simplifile.read(from: "./src/days/day2/full.txt")
  }
  |> result.map_error(string.inspect)
}
