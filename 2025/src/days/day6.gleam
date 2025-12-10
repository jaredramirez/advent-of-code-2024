import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import iv.{type Array}
import simplifile

import puzzle

// -----------------------------------------------------------------------------
// Part 1

pub fn part_1_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(part_1_input(input))

  use worksheet <- result.try(parse(input_str))
  let solved = solve(worksheet)

  io.println("Answer: " <> string.inspect(solved))
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
// Impl

type Worksheet {
  Worksheet(cols: Array(Array(Int)), operations: Array(Operation))
}

type Operation {
  Add
  Mul
}

fn solve(worksheet: Worksheet) -> Int {
  let col_solutions =
    iv.map2(worksheet.cols, worksheet.operations, fn(col_of_numbers, op) {
      case op {
        Add -> iv.fold(col_of_numbers, 0, fn(acc, cur) { acc + cur })
        Mul -> iv.fold(col_of_numbers, 1, fn(acc, cur) { acc * cur })
      }
    })

  col_solutions
  |> iv.fold(0, fn(acc, cur) { acc + cur })
}

fn parse(str: String) -> Result(Worksheet, String) {
  // First, split the lines discarding spaces inbetween
  let lines =
    string.split(str, on: "\n")
    |> list.map(fn(line) {
      string.split(line, on: " ")
      |> list.filter(fn(str) { !string.is_empty(str) })
      |> iv.from_list
    })
    |> iv.from_list

  // Then, parse the operations
  use operation_strs <- result.try(
    iv.last(lines)
    |> result.map_error(fn(_) { "Input list is empty" }),
  )
  use operations <- result.try(
    operation_strs
    |> iv.try_map(fn(op_str) {
      case op_str {
        "+" -> Ok(Add)
        "*" -> Ok(Mul)
        _ -> Error("Invalid operation " <> op_str)
      }
    }),
  )

  // Then, parse the operations
  let rows_cols_strs = iv.drop_last(lines, 1)
  use rows_cols <- result.try(
    rows_cols_strs
    |> iv.try_map(fn(rows) {
      iv.try_map(rows, fn(cell_str) {
        int.parse(cell_str)
        |> result.map_error(fn(_) { "Invalid cell number: " <> cell_str })
      })
    }),
  )
  use cols_rows <- result.try(rotate_arrays(rows_cols))

  Ok(Worksheet(cols_rows, operations:))
}

/// Rotate arrays. Rows must have the same number of cells.
/// 
/// 
// [ [ 1, 2, 3 ]
// , [ 4, 5, 6 ]
// ]
// 
// --->
// 
// [ [ 1, 4 ]
// , [ 2, 5 ]
// , [ 3, 6 ]
// ]
// 
pub fn rotate_arrays(
  rows_cols: Array(Array(a)),
) -> Result(Array(Array(a)), String) {
  let num_cols =
    iv.get(rows_cols, 0) |> result.map(iv.length) |> result.unwrap(0)
  let initial_arr = iv.repeat(iv.new(), num_cols)

  iv.try_fold(rows_cols, initial_arr, fn(acc_arr, cur_row) {
    // Assert that this row has the number of columns we expect
    use _ <- result.try(case iv.length(cur_row) == num_cols {
      True -> Ok(Nil)
      False ->
        Error(
          "Expected "
          <> int.to_string(num_cols)
          <> " columnms but got "
          <> string.inspect(cur_row),
        )
    })

    iv.index_fold(cur_row, acc_arr, fn(sub_acc_arr, cur_cell, cell_idx) {
      iv.try_update(sub_acc_arr, at: cell_idx, with: fn(prev_vals) {
        iv.append(prev_vals, cur_cell)
      })
    })
    |> Ok
  })
}

// -----------------------------------------------------------------------------
// Inputs

fn part_1_input(input: puzzle.Input) -> Result(String, String) {
  case input {
    puzzle.Sample -> simplifile.read(from: "./src/days/day6/sample.txt")
    puzzle.Full -> simplifile.read(from: "./src/days/day6/full.txt")
  }
  |> result.map(string.trim)
  |> result.map_error(string.inspect)
}
