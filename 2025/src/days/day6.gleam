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

  use worksheet_str <- result.try(parse(input_str))
  use worksheet_int <- result.try(worksheet_str_to_int(worksheet_str))
  let solved = solve(worksheet_int)

  io.println("Answer: " <> string.inspect(solved))
  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Part 2

pub fn part_2_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(part_1_input(input))

  use worksheet_str <- result.try(parse(input_str))
  use worksheet_int <- result.try(worksheet_str_to_cephalopod_num(worksheet_str))
  let solved = solve(worksheet_int)

  io.println("Answer: " <> string.inspect(solved))
  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Impl

type Worksheet(cell) {
  Worksheet(cols: Array(Array(cell)), operations: Array(Operation))
}

fn worksheet_str_to_int(
  worksheet: Worksheet(String),
) -> Result(Worksheet(Int), String) {
  use int_cols <- result.try(
    worksheet.cols
    |> iv.try_map(fn(col) {
      iv.try_map(col, fn(cell_str) {
        cell_str
        |> string.trim
        |> int.parse
        |> result.map_error(fn(_) {
          "Invalid cell number: '" <> cell_str <> "'"
        })
      })
    }),
  )

  Ok(Worksheet(int_cols, worksheet.operations))
}

fn worksheet_str_to_cephalopod_num(
  worksheet: Worksheet(String),
) -> Result(Worksheet(Int), String) {
  use int_cols <- result.try(
    worksheet.cols
    |> iv.try_map(fn(col) { str_to_cephalopod_nums(col) }),
  )

  Ok(Worksheet(int_cols, worksheet.operations))
}

pub fn str_to_cephalopod_nums(arr: Array(String)) -> Result(Array(Int), String) {
  use rotated_arr <- result.try(
    arr
    |> iv.map(fn(v) {
      v
      |> string.to_graphemes
      |> iv.from_list
    })
    |> rotate_arrays
    |> result.map(iv.reverse),
  )

  use cephalopod_nums <- result.try(
    rotated_arr
    |> iv.try_map(fn(digits) {
      digits
      |> iv.join("")
      |> string.trim
      |> int.parse
      |> result.map_error(fn(_) {
        string.inspect(digits) <> " was a not a valid int"
      })
    }),
  )

  Ok(cephalopod_nums)
}

type Operation {
  Add
  Mul
}

fn solve(worksheet: Worksheet(Int)) -> Int {
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

fn parse(str: String) -> Result(Worksheet(String), String) {
  // First, split the lines discarding spaces inbetween
  let lines =
    string.split(str, on: "\n")
    |> iv.from_list
    |> iv.drop_last(1)
  // drop last newline

  // Then, parse the operations
  use operations_line <- result.try(
    iv.last(lines)
    |> result.map_error(fn(_) { "Input list is empty" }),
  )
  use #(operations, col_lens) <- result.try({
    let graphemes =
      operations_line
      |> string.to_graphemes
      |> iv.from_list

    use first_op <- result.try(
      iv.get(graphemes, 0)
      |> result.map_error(fn(_) { "Grapheme operations empty" })
      |> result.try(parse_op),
    )

    let #(acc_ops, last_op, last_len) =
      iv.fold(
        iv.drop_first(graphemes, 1),
        #([], first_op, 0),
        fn(acc, cur_grapheme) {
          case parse_op(cur_grapheme) {
            Error(_) -> #(acc.0, acc.1, acc.2 + 1)
            Ok(next_op) -> #([#(acc.1, acc.2), ..acc.0], next_op, 0)
          }
        },
      )

    let #(ops, lens) =
      [#(last_op, last_len), ..acc_ops]
      |> list.reverse
      |> list.unzip

    Ok(#(iv.from_list(ops), iv.from_list(lens)))
  })

  // Then, rotate the rows and cols
  let rows = lines |> iv.drop_last(1)
  use cols_rows <- result.try(
    rows
    |> iv.map(fn(initial_row) {
      let strs =
        help.loop(#([], initial_row, 0), fn(state) {
          let #(acc_digits, cur_row, col_idx) = state

          let col_len =
            iv.get(col_lens, col_idx)
            |> result.lazy_unwrap(fn() { panic })

          let cur_digits = string.slice(cur_row, at_index: 0, length: col_len)
          let next_row = string.drop_start(cur_row, col_len + 1)

          let next_digits = [cur_digits, ..acc_digits]

          case string.is_empty(next_row) {
            True -> help.Stop(next_digits)
            False -> help.Continue(#(next_digits, next_row, col_idx + 1))
          }
        })

      iv.from_reverse_list(strs)
    })
    |> rotate_arrays,
  )

  Ok(Worksheet(cols_rows, operations:))
}

fn parse_op(str: String) -> Result(Operation, String) {
  case str {
    "+" -> Ok(Add)
    "*" -> Ok(Mul)
    _ -> Error("Invalid operation " <> str)
  }
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
  |> result.map_error(string.inspect)
}
