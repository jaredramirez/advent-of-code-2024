import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import help
import iv.{type Array}
import simplifile

import puzzle

// -----------------------------------------------------------------------------
// Part 1

pub fn part_1_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(part_1_input(input))

  use db <- result.try(
    input_str
    |> string.trim
    |> parse_db,
  )
  let fresh_ids = find_fresh_ids(db)

  io.println("Answer: " <> string.inspect(list.length(fresh_ids)))
  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Part 2

pub fn part_2_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(part_1_input(input))

  use db <- result.try(
    input_str
    |> string.trim
    |> parse_db,
  )
  let range_arr = iv.from_list(db.fresh_id_ranges)
  let flatted_ranges_arr = flatten_ranges(range_arr)
  let total_values_in_range =
    iv.fold(flatted_ranges_arr, 0, fn(acc_count, cur_range) {
      acc_count + { { cur_range.end + 1 } - cur_range.start }
    })

  io.println("Answer: " <> string.inspect(total_values_in_range))
  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Impl

/// A range inclusive on both ends
pub type Range {
  Range(start: Int, end: Int)
}

/// A range inclusive on both ends
type Db {
  Db(fresh_id_ranges: List(Range), ids: List(Int))
}

fn flatten_ranges(initial_ranges: Array(Range)) -> Array(Range) {
  help.loop(initial_ranges, fn(cur) {
    let cur_ranges_len = iv.length(cur)

    let flattened = flatten_ranges_help(cur)
    let flattened_len = iv.length(flattened)

    case cur_ranges_len == flattened_len {
      True -> help.Stop(flattened)
      False -> help.Continue(flattened)
    }
  })
}

fn flatten_ranges_help(ranges: Array(Range)) -> Array(Range) {
  iv.fold(ranges, iv.new(), fn(acc_ranges, cur_range) {
    let res_idx_to_update =
      acc_ranges
      |> iv.find_index(fn(acc_range) {
        compare_ranges(acc_range, cur_range) != NoOverlap
      })

    case res_idx_to_update {
      Error(Nil) -> {
        iv.append(acc_ranges, cur_range)
      }
      Ok(idx) -> {
        iv.update(acc_ranges, idx, fn(acc_range) {
          merge_ranges(acc_range, cur_range)
          |> result.lazy_unwrap(fn() { panic as "Could not merge ranges" })
        })
        |> result.lazy_unwrap(fn() {
          panic as { "Could not find idx" <> int.to_string(idx) }
        })
      }
    }
  })
}

pub type RangeCompare {
  NoOverlap

  AContainedWithinB
  BContainedWithinA

  AEndBStartOverlap
  BEndAStartOverlap
}

pub fn merge_ranges(a: Range, b: Range) -> Result(Range, Nil) {
  case compare_ranges(a, b) {
    NoOverlap -> Error(Nil)

    AContainedWithinB -> Ok(b)
    BContainedWithinA -> Ok(a)

    AEndBStartOverlap | BEndAStartOverlap ->
      Ok(Range(int.min(a.start, b.start), int.max(a.end, b.end)))
  }
}

pub fn compare_ranges(a: Range, b: Range) {
  case Nil {
    _ if a.start >= b.start && a.end <= b.end -> AContainedWithinB
    _ if b.start >= a.start && b.end <= a.end -> BContainedWithinA
    _ if a.start <= b.start && a.end >= b.start -> AEndBStartOverlap
    _ if b.start <= a.start && b.end >= a.start -> BEndAStartOverlap
    _ -> NoOverlap
  }
}

fn find_fresh_ids(db: Db) -> List(Int) {
  list.filter_map(db.ids, fn(id) {
    let is_id_fresh =
      list.any(db.fresh_id_ranges, fn(range) {
        id >= range.start && id <= range.end
      })
    case is_id_fresh {
      True -> Ok(id)
      False -> Error(Nil)
    }
  })
}

fn parse_db(str: String) -> Result(Db, String) {
  use #(ranges_str, ids_str) <- result.try(
    string.split_once(str, on: "\n\n")
    |> result.map_error(fn(_) {
      "Expected ranges & id separated by two newlines"
    }),
  )
  use ranges <- result.try(parse_ranges(ranges_str))
  use ids <- result.try(parse_ids(ids_str))
  Ok(Db(ranges, ids))
}

fn parse_ranges(str: String) -> Result(List(Range), String) {
  string.split(str, on: "\n")
  |> list.try_map(parse_range)
}

fn parse_range(str: String) -> Result(Range, String) {
  use #(lower_str, upper_str) <- result.try({
    string.split_once(str, on: "-")
    |> result.map_error(fn(_) { "Expected 2 parts in range" })
  })
  use lower_int <- result.try(
    int.parse(lower_str)
    |> result.map_error(fn(_) { "Expected " <> lower_str <> " to be an int" }),
  )
  use upper_int <- result.try(
    int.parse(upper_str)
    |> result.map_error(fn(_) { "Expected " <> upper_str <> " to be an int" }),
  )
  Ok(Range(lower_int, upper_int))
}

fn parse_ids(str: String) -> Result(List(Int), String) {
  string.split(str, on: "\n")
  |> list.try_map(fn(id_str) {
    id_str
    |> int.parse
    |> result.map_error(fn(_) { "Expected " <> id_str <> " to be an int" })
  })
}

// -----------------------------------------------------------------------------
// Inputs

fn part_1_input(input: puzzle.Input) -> Result(String, String) {
  case input {
    puzzle.Sample -> simplifile.read(from: "./src/days/day5/sample.txt")
    puzzle.Full -> simplifile.read(from: "./src/days/day5/full.txt")
  }
  |> result.map_error(string.inspect)
}
