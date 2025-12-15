import gleam/dict
import gleam/float
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import help
import iv
import simplifile

import puzzle

// -----------------------------------------------------------------------------
// Part 1

pub fn part_1_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(get_input(input))
  let num_to_connect = case input {
    puzzle.Sample -> 10
    puzzle.Full -> 1000
  }

  use points <- result.try(parse(input_str))
  use sorted_points_with_dist <- result.try(calc_distances_and_sort(points))

  let circuits =
    sorted_points_with_dist
    |> list.take(num_to_connect)
    |> connect_circuits
    |> list.sort(fn(a, b) { int.compare(set.size(b.set), set.size(a.set)) })
    |> list.take(3)
    |> list.fold(1, fn(acc, cur) { acc * set.size(cur.set) })

  io.println("Answer: " <> string.inspect(circuits))
  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Part 2

pub fn part_2_run(input: puzzle.Input) -> Result(Nil, String) {
  use _input_str <- result.try(get_input(input))
  io.println("Answer: " <> string.inspect(Nil))
  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Impl

type Circuit {
  Circuit(set: Set(Point))
}

fn connect_circuits(
  sorted_points_with_dist: List(#(Point, Point, Float)),
) -> List(Circuit) {
  let circuits =
    sorted_points_with_dist
    |> list.fold(iv.new(), fn(circuits, cur) {
      let r_existing_idx =
        iv.find_index(circuits, fn(circuit) {
          set.contains(circuit, cur.0) || set.contains(circuit, cur.1)
        })

      let next_circuits = case r_existing_idx {
        Error(Nil) -> iv.append(circuits, set.from_list([cur.0, cur.1]))
        Ok(existing_idx) -> {
          iv.try_update(circuits, existing_idx, fn(circuit) {
            circuit
            |> set.insert(cur.0)
            |> set.insert(cur.1)
          })
        }
      }
      next_circuits
    })

  let connected =
    circuits
    |> iv.to_list
    |> list.map(Circuit)

  help.loop(connected, fn(cur_connected) {
    let next_connected = flatten_circuits(cur_connected)
    case list.length(next_connected) == list.length(cur_connected) {
      True -> help.Stop(next_connected)
      False -> help.Continue(next_connected)
    }
  })
}

fn flatten_circuits(circuits: List(Circuit)) -> List(Circuit) {
  list.fold(circuits, iv.new(), fn(acc_flattened, cur) {
    let r_existing_idx =
      iv.find_index(acc_flattened, fn(flattened) {
        !set.is_disjoint(flattened, cur.set)
      })

    case r_existing_idx {
      Error(Nil) -> iv.append(acc_flattened, cur.set)
      Ok(existing_idx) -> {
        iv.try_update(acc_flattened, existing_idx, fn(flattened) {
          set.union(flattened, cur.set)
        })
      }
    }
  })
  |> iv.to_list
  |> list.map(Circuit)
}

fn calc_distances_and_sort(
  points: List(Point),
) -> Result(List(#(Point, Point, Float)), String) {
  use points_with_dist <- result.try(
    list.index_map(points, fn(point_a, i) {
      let points_after_i = list.drop(points, i + 1)
      list.try_map(points_after_i, fn(point_b) {
        get_distance(point_a, point_b)
        |> result.map(fn(dist) { #(point_a, point_b, dist) })
        |> help.set_err_msg(
          "Coueld not calc dist for: ("
          <> string.inspect(point_a)
          <> ", "
          <> string.inspect(point_b)
          <> ")",
        )
      })
    })
    |> list.try_map(function.identity)
    |> result.map(list.flatten),
  )

  points_with_dist
  |> list.sort(fn(a, b) { float.compare(a.2, b.2) })
  |> Ok
}

// -----------------------------------------------------------------------------
// Helpers

pub fn get_distance(a: Point, b: Point) -> Result(Float, Nil) {
  use x_squared <- result.try(int.power(a.x - b.x, 2.0))
  use y_squared <- result.try(int.power(a.y - b.y, 2.0))
  use z_squared <- result.try(int.power(a.z - b.z, 2.0))
  float.square_root(x_squared +. y_squared +. z_squared)
}

pub fn max(a: Point, b: Point) -> Point {
  let max_a = a.x + a.y + a.z
  let max_b = b.x + b.y + b.z

  case max_a > max_b {
    True -> a
    False -> b
  }
}

pub fn min(a: Point, b: Point) -> Point {
  let min_a = a.x - a.y - a.z
  let min_b = b.x - b.y - b.z

  case min_a > min_b {
    True -> a
    False -> b
  }
}

// -----------------------------------------------------------------------------
// Parse

pub type Point {
  Point(x: Int, y: Int, z: Int)
}

fn parse(str: String) -> Result(List(Point), String) {
  str
  |> string.split(on: "\n")
  |> list.try_map(fn(line) {
    use triple <- result.try(case string.split(line, on: ",") {
      [x, y, z] -> Ok(#(x, y, z))
      _ -> Error("Expected 3 numbers, got: " <> line)
    })

    use point <- result.try(
      case int.parse(triple.0), int.parse(triple.1), int.parse(triple.2) {
        Error(Nil), _, _ | _, Error(Nil), _ | _, _, Error(Nil) ->
          Error("Expected 3 numbers, got: " <> line)
        Ok(x), Ok(y), Ok(z) -> Ok(Point(x, y, z))
      },
    )

    Ok(point)
  })
}

// -----------------------------------------------------------------------------
// Inputs

fn get_input(input: puzzle.Input) -> Result(String, String) {
  case input {
    puzzle.Sample -> simplifile.read(from: "./src/days/day8/sample.txt")
    puzzle.Full -> simplifile.read(from: "./src/days/day8/full.txt")
  }
  |> result.map_error(string.inspect)
  |> result.map(string.trim)
}
