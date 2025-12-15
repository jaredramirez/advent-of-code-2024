import gleam/function
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import iv.{type Array}
import non_empty_list
import simplifile

import help.{set_err_msg}
import puzzle

// -----------------------------------------------------------------------------
// Part 1

pub fn part_1_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(part_1_input(input))

  use diagram <- result.try(parse(input_str))
  use evaled_diagram <- result.try(eval_diagram(diagram))
  let num_splits = count_splits(evaled_diagram)

  // io.println("evaled:\n" <> diagram_to_string(evaled_diagram))

  io.println("Answer: " <> string.inspect(num_splits))

  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Part 2

pub fn part_2_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(part_1_input(input))

  use diagram <- result.try(parse(input_str))
  use evaled_diagram <- result.try(eval_diagram(diagram))
  let num_timelines = trace_timelines(evaled_diagram)

  io.println("Answer: " <> string.inspect(num_timelines))
  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Impl - Part 2

/// Starting from the bottom, trace the beams up towards the root adding together
/// beams each time a splitter is hit
/// 
/// This could stand to be cleaned up a loott
fn trace_timelines(solved_diagram: Diagram(Cell)) -> Result(Int, String) {
  let max_idx = iv.length(solved_diagram.rows) - 1

  let traced_diagram =
    solved_diagram.rows
    |> iv.index_fold_right(iv.new(), fn(acc_rows, cur_row, row_idx) {
      let next_row =
        iv.index_map(cur_row, fn(cell, cell_idx) {
          case cell {
            Beam if row_idx == max_idx -> NumTimeline(1)
            Beam | Start -> {
              let r_last_row = iv.first(acc_rows)
              let r_last_cell =
                result.try(r_last_row, fn(last_row) {
                  iv.get(last_row, cell_idx)
                })
              case r_last_cell {
                Ok(NumTimeline(num)) -> NumTimeline(num)
                Ok(Splitter) -> {
                  let r_left_cell =
                    r_last_row
                    |> result.try(fn(last_row) {
                      iv.get(last_row, cell_idx - 1)
                    })
                    |> result.try(fn(cell) {
                      case cell {
                        NumTimeline(num) -> Ok(num)
                        _ -> Error(Nil)
                      }
                    })
                    |> result.unwrap(0)

                  let r_right_cell =
                    r_last_row
                    |> result.try(fn(last_row) {
                      iv.get(last_row, cell_idx + 1)
                    })
                    |> result.try(fn(cell) {
                      case cell {
                        NumTimeline(num) -> Ok(num)
                        _ -> Error(Nil)
                      }
                    })
                    |> result.unwrap(0)

                  NumTimeline(r_left_cell + r_right_cell)
                }
                Error(Nil) | Ok(_) -> cell
              }
            }
            _ -> cell
          }
        })
      iv.prepend(acc_rows, next_row)
    })

  use first_row_timelines <- result.try(
    traced_diagram
    |> iv.first
    |> result.map(fn(first_row) {
      iv.filter_map(first_row, fn(cell) {
        case cell {
          NumTimeline(n) -> Ok(n)
          _ -> Error(Nil)
        }
      })
    })
    |> result.map(iv.to_list)
    |> result.try(non_empty_list.from_list)
    |> set_err_msg("No timeline nums in first row"),
  )

  assert non_empty_list.length(first_row_timelines) == 1

  Ok(non_empty_list.first(first_row_timelines))
}

// -----------------------------------------------------------------------------
// Impl - Part 1

fn count_splits(diagram: Diagram(Cell)) -> Int {
  diagram.rows
  |> iv.index_map(fn(row, i) {
    iv.index_map(row, fn(cell, j) {
      case cell {
        Splitter -> {
          case get_at(diagram, Point(i - 1, j)) {
            Ok(Beam) -> 1
            _ -> 0
          }
        }
        _ -> 0
      }
    })
  })
  |> iv.flatten
  |> iv.fold(0, fn(acc, cur) { acc + cur })
}

fn eval_diagram(initial_diagram: Diagram(Cell)) -> Result(Diagram(Cell), String) {
  list.range(0, iv.length(initial_diagram.rows) - 1)
  |> list.try_fold(initial_diagram, fn(acc_diagram, i) {
    let next_diagram = eval_row(acc_diagram, i)
    next_diagram
  })
}

fn eval_row(diagram: Diagram(Cell), i: Int) -> Result(Diagram(Cell), String) {
  case i == 0 {
    True -> Ok(diagram)
    False -> {
      use row <- result.try(
        iv.get(diagram.rows, i)
        |> result.map_error(fn(_) { "Invalid index: " <> string.inspect(i) }),
      )

      // Calculate all beams to propgate to this row
      let beam_to_propgate_to_this_row =
        row
        |> iv.index_map(fn(this_cell, j) {
          // First, get the cell above this one
          use above_cell <- result.try(get_at(diagram, Point(i - 1, j)))

          // Then, if the above cell is a beam, determine if the beam should
          // pass through this cell or split
          case above_cell {
            Beam | Start | NumTimeline(_) -> {
              case this_cell {
                Beam | Space | Start | NumTimeline(_) -> [Point(i, j)]
                Splitter -> [Point(i, j - 1), Point(i, j + 1)]
              }
              |> Ok
            }
            Space | Splitter -> Error(Nil)
          }
        })
        |> iv.filter_map(function.identity)
        |> iv.to_list
        |> list.flatten
        |> set.from_list

      // Then, update this row with beams
      let next_row =
        row
        |> iv.index_map(fn(this_cell, j) {
          case set.contains(beam_to_propgate_to_this_row, Point(i, j)) {
            True -> Beam
            False -> this_cell
          }
        })

      use next_rows <- result.try(
        iv.set(diagram.rows, i, next_row)
        |> result.map_error(fn(_) { "Invalid index: " <> string.inspect(i) }),
      )

      Ok(Diagram(next_rows))
    }
  }
}

type Point {
  Point(x: Int, y: Int)
}

type Diagram(a) {
  Diagram(rows: Array(Array(a)))
}

fn get_at(diagram: Diagram(cell), point: Point) -> Result(cell, Nil) {
  use row <- result.try(iv.get(diagram.rows, point.x))
  iv.get(row, point.y)
}

type Cell {
  Start
  Beam
  Space
  Splitter
  NumTimeline(Int)
}

// fn diagram_to_string(diagram: Diagram(Cell)) -> String {
//   diagram.rows
//   |> iv.map(fn(row) {
//     row
//     |> iv.map(cell_to_string)
//     |> iv.join(with: "")
//   })
//   |> iv.join(with: "\n")
// }

// fn cell_to_string(cell: Cell) -> String {
//   case cell {
//     Start -> "S"
//     Beam -> "|"
//     Space -> "."
//     Splitter -> "^"
//     NumTimeline(num) if num > 10 -> "x"
//     NumTimeline(num) -> int.to_string(num)
//   }
// }

/// Parse input string into a dict of points & cells
fn parse(str: String) -> Result(Diagram(Cell), String) {
  str
  |> string.trim
  |> string.split(on: "\n")
  |> list.try_map(fn(line) {
    line
    |> string.to_graphemes
    |> list.try_map(fn(grapheme) {
      case grapheme {
        "S" -> Ok(Start)
        "." -> Ok(Space)
        "^" -> Ok(Splitter)
        _ -> Error("Invalid cell: " <> grapheme)
      }
    })
  })
  |> result.map(fn(lines) {
    lines
    |> list.map(iv.from_list)
    |> iv.from_list
    |> Diagram
  })
}

// -----------------------------------------------------------------------------
// Inputs

fn part_1_input(input: puzzle.Input) -> Result(String, String) {
  case input {
    puzzle.Sample -> simplifile.read(from: "./src/days/day7/sample.txt")
    puzzle.Full -> simplifile.read(from: "./src/days/day7/full.txt")
  }
  |> result.map(string.trim)
  |> result.map_error(string.inspect)
}
