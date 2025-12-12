import gleam/dict.{type Dict}
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import iv.{type Array}
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
  let num_timelines = trace_timelines(diagram)

  io.println("Answer: " <> string.inspect(num_timelines))
  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Impl - Part 2

fn trace_timelines(diagram: Diagram(Cell)) -> Result(Int, String) {
  let dict =
    iv.index_fold(diagram.rows, dict.new(), fn(acc_dict, cur_row, y) {
      iv.index_fold(cur_row, acc_dict, fn(sub_acc_dict, cur_cell, x) {
        dict.insert(sub_acc_dict, Point(x, y), cur_cell)
      })
    })

  use start_point <- result.try({
    let y = 0
    use first_row <- result.try(
      iv.get(diagram.rows, y)
      |> set_err_msg("Invalid index: " <> string.inspect(y)),
    )
    iv.index_fold(
      first_row,
      Error("Start not found"),
      fn(res_found, cur_cell, x) {
        case res_found, cur_cell {
          Error(_), Start -> Ok(Point(x, y))
          _, _ -> res_found
        }
      },
    )
  })

  eval_beam_timelines(dict, start_point)
  |> Ok
}

fn eval_beam_timelines(dict: Dict(Point, Cell), start_beam_point: Point) -> _ {
  let step = eval_next_step(dict, start_beam_point)
  case step {
    End -> 1
    PropgateBeam(next_beam_point) -> eval_beam_timelines(dict, next_beam_point)
    SplitBeam(next_beam_point_a, next_beam_point_b) -> {
      let a_beam_count = eval_beam_timelines(dict, next_beam_point_a)
      let b_beam_count = eval_beam_timelines(dict, next_beam_point_b)
      a_beam_count + b_beam_count
    }
  }
}

fn eval_next_step(dict: Dict(Point, Cell), cur_beam_point: Point) -> Step {
  let next_point = Point(cur_beam_point.x, cur_beam_point.y + 1)
  case dict.get(dict, next_point) {
    Error(Nil) -> End
    Ok(next_cell) -> {
      case next_cell {
        Beam | Space | Start -> PropgateBeam(next_point)
        Splitter ->
          SplitBeam(
            Point(next_point.x - 1, next_point.y),
            Point(next_point.x + 1, next_point.y),
          )
      }
    }
  }
}

type Step {
  PropgateBeam(Point)
  SplitBeam(Point, Point)
  End
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

fn diagram_to_string(diagram: Diagram(Cell)) -> String {
  diagram.rows
  |> iv.map(fn(row) {
    row
    |> iv.map(cell_to_string)
    |> iv.join(with: "")
  })
  |> iv.join(with: "\n")
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
            Beam | Start -> {
              case this_cell {
                Beam | Space | Start -> [Point(i, j)]
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
}

fn cell_to_string(cell: Cell) -> String {
  case cell {
    Start -> "S"
    Beam -> "|"
    Space -> "."
    Splitter -> "^"
  }
}

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
