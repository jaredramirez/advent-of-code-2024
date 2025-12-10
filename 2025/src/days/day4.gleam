import gleam/dict
import gleam/function
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import help
import simplifile

import puzzle

// -----------------------------------------------------------------------------
// Part 1

const max_roll_count: Int = 4

pub fn part_1_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(part_1_input(input))

  use map <- result.try(parse_map(input_str))
  let accessible_rolls = get_accessible_rolls(map)

  io.println("Answer: " <> string.inspect(list.length(accessible_rolls)))
  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Part 2

pub fn part_2_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(part_1_input(input))

  use initial_map <- result.try(parse_map(input_str))

  let total_rolls_removed =
    help.loop(#(0, initial_map), fn(acc) {
      let #(cur_rolls_removed, cur_map) = acc
      let accessible_rolls = get_accessible_rolls(cur_map)
      let num_accessible_rolls = list.length(accessible_rolls)

      case num_accessible_rolls > 0 {
        True -> {
          let map_with_accessible_rolls_removed =
            list.fold(
              accessible_rolls,
              cur_map,
              fn(acc_map, accessible_roll_point) {
                dict.delete(acc_map, accessible_roll_point)
              },
            )
          help.Continue(#(
            cur_rolls_removed + num_accessible_rolls,
            map_with_accessible_rolls_removed,
          ))
        }
        False -> help.Stop(cur_rolls_removed)
      }
    })

  io.println("Answer: " <> string.inspect(total_rolls_removed))
  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Impl

type Obj {
  Empty
  Roll
}

type Point {
  Point(x: Int, y: Int)
}

/// Get acceptible rolls
fn get_accessible_rolls(map: dict.Dict(Point, Obj)) -> List(Point) {
  map
  |> dict.to_list
  |> list.filter_map(fn(key_val) {
    case key_val {
      #(_, Empty) -> Error(Nil)
      #(point, Roll) -> {
        let nearby_points = get_nearby_points(point)
        let roll_count =
          list.fold_until(nearby_points, 0, fn(roll_count, nearby_point) {
            let obj =
              dict.get(map, nearby_point)
              |> result.unwrap(Empty)
            let next_roll_count = case obj {
              Roll -> roll_count + 1
              Empty -> roll_count
            }
            case next_roll_count < max_roll_count {
              True -> list.Continue(next_roll_count)
              False -> list.Stop(next_roll_count)
            }
          })

        case roll_count < max_roll_count {
          True -> Ok(key_val)
          False -> Error(Nil)
        }
      }
    }
  })
  |> list.map(fn(t) { t.0 })
}

fn parse_map(str: String) -> Result(dict.Dict(Point, Obj), String) {
  str
  |> string.trim
  |> string.split(on: "\n")
  |> list.index_map(fn(row_str, i) {
    row_str
    |> string.to_graphemes
    |> list.index_map(fn(cell, j) {
      let point = Point(i, j)
      case cell {
        "." -> Ok(#(point, Empty))
        "@" -> Ok(#(point, Roll))
        _ -> Error("Invalid object at point " <> string.inspect(point))
      }
    })
  })
  |> list.flatten
  |> list.try_map(function.identity)
  |> result.map(dict.from_list)
}

fn get_nearby_points(point: Point) -> List(Point) {
  [
    Point(point.x - 1, point.y - 1),
    Point(point.x - 1, point.y),
    Point(point.x - 1, point.y + 1),
    Point(point.x, point.y - 1),
    Point(point.x, point.y + 1),
    Point(point.x + 1, point.y - 1),
    Point(point.x + 1, point.y),
    Point(point.x + 1, point.y + 1),
  ]
}

// -----------------------------------------------------------------------------
// Inputs

fn part_1_input(input: puzzle.Input) -> Result(String, String) {
  case input {
    puzzle.Sample -> simplifile.read(from: "./src/days/day4/sample.txt")
    puzzle.Full -> simplifile.read(from: "./src/days/day4/full.txt")
  }
  |> result.map_error(string.inspect)
}
