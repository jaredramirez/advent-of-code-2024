import gleam/dict
import gleam/float
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set.{type Set}
import gleam/string
import help
import iv.{type Array}
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
    |> connect_circuits(points, num_to_connect)
    |> list.take(3)
    |> list.fold(1, fn(acc, cur) { acc * set.size(cur.set) })

  io.println("Answer: " <> string.inspect(circuits))
  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Part 2

pub fn part_2_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(get_input(input))

  use points <- result.try(parse(input_str))
  use sorted_points_with_dist <- result.try(calc_distances_and_sort(points))

  let circuits =
    sorted_points_with_dist
    |> connect_circuits_until_single(points)
    |> option.map(fn(points) { { points.0 }.x * { points.1 }.x })

  io.println("Answer: " <> string.inspect(circuits))
  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Impl - Part 2

fn connect_circuits_until_single(
  sorted_connected_points_with_dist: List(#(Point, Point, Float)),
  all_points: List(Point),
) -> option.Option(#(Point, Point)) {
  let initial_circuits =
    all_points
    |> list.index_fold(dict.new(), fn(acc, point, idx) {
      dict.insert(acc, point, idx)
    })

  let #(_points_to_circuits, opt_final_point) =
    sorted_connected_points_with_dist
    |> list.fold_until(#(initial_circuits, option.None), fn(acc, cur) {
      let #(acc_points_to_circuits, _) = acc

      let left_point = cur.0
      let right_point = cur.1

      let r_left_ext_circuit_idx = dict.get(acc_points_to_circuits, left_point)
      let r_right_ext_circuit_idx =
        dict.get(acc_points_to_circuits, right_point)

      let #(next_circuits, distinct_circuit_ids) = case
        r_left_ext_circuit_idx,
        r_right_ext_circuit_idx
      {
        Error(Nil), _ | _, Error(Nil) -> {
          // Since we create initial circuits based on all points, this should
          // never be the case
          panic
        }
        Ok(left_existing_idx), Ok(right_existing_id) -> {
          // Iterate over all points, updating the entire right circuit to 
          // be part of the left circuit
          // 
          // Also builds a set of distincte circuit IDs encountered, to check
          // if we've completed the circuit
          acc_points_to_circuits
          |> dict.fold(
            #(dict.new(), set.new()),
            fn(acc, cur_point, cur_circuit_id) {
              let #(sub_acc_points_to_circuits, sub_acc_distinct_circuit_ids) =
                acc
              let next_circuit_id = case right_existing_id == cur_circuit_id {
                True -> left_existing_idx
                False -> cur_circuit_id
              }
              #(
                dict.insert(
                  sub_acc_points_to_circuits,
                  cur_point,
                  next_circuit_id,
                ),
                set.insert(sub_acc_distinct_circuit_ids, next_circuit_id),
              )
            },
          )
        }
      }

      case set.size(distinct_circuit_ids) == 1 {
        True ->
          list.Stop(#(next_circuits, option.Some(#(left_point, right_point))))
        False -> list.Continue(#(next_circuits, option.None))
      }
    })

  opt_final_point
}

// -----------------------------------------------------------------------------
// Impl - Part 1

type Circuit {
  Circuit(set: Set(Point))
}

fn connect_circuits(
  sorted_connected_points_with_dist: List(#(Point, Point, Float)),
  all_points: List(Point),
  num_to_connect: Int,
) -> List(Circuit) {
  let initial_circuits =
    all_points
    |> list.index_fold(dict.new(), fn(acc, point, idx) {
      dict.insert(acc, point, idx)
    })

  let points_to_circuits =
    sorted_connected_points_with_dist
    |> list.take(num_to_connect)
    |> list.fold(initial_circuits, fn(acc_points_to_circuits, cur) {
      let left_point = cur.0
      let right_point = cur.1

      let r_left_ext_circuit_idx = dict.get(acc_points_to_circuits, left_point)
      let r_right_ext_circuit_idx =
        dict.get(acc_points_to_circuits, right_point)

      let next_circuits = case r_left_ext_circuit_idx, r_right_ext_circuit_idx {
        Error(Nil), _ | _, Error(Nil) -> {
          // Since we create initial circuits based on all points, this should
          // never be the case
          panic
        }
        Ok(left_existing_idx), Ok(right_existing_id) -> {
          // Iterate over all points, updating the entire right circuit to 
          // be part of the left circuit
          acc_points_to_circuits
          |> dict.map_values(fn(_key, cur_id) {
            case right_existing_id == cur_id {
              True -> left_existing_idx
              False -> cur_id
            }
          })
        }
      }

      circuits_dict_to_list(next_circuits)

      next_circuits
    })

  points_to_circuits
  |> circuits_dict_to_list
  |> list.map(Circuit)
}

fn circuits_dict_to_list(points_to_circuits: dict.Dict(a, b)) -> List(Set(a)) {
  points_to_circuits
  |> dict.to_list
  |> list.fold(dict.new(), fn(acc, cur) {
    let #(point, circuit_idx) = cur
    dict.upsert(acc, circuit_idx, fn(opt_existing) {
      case opt_existing {
        option.None -> set.from_list([point])
        option.Some(existing_points_in_circuit) ->
          set.insert(existing_points_in_circuit, point)
      }
    })
  })
  |> dict.values
  |> list.sort(fn(a, b) { int.compare(set.size(b), set.size(a)) })
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
