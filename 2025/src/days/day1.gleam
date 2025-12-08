import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

import puzzle

// -----------------------------------------------------------------------------
// Part 1

pub fn part_1_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(part_1_input(input))

  // Parse input into data structures
  use cmds <- result.try(
    string.split(input_str, on: "\n")
    |> list.filter(fn(str) { string.length(str) != 0 })
    |> list.try_map(fn(line) {
      let starts_with_r = string.starts_with(line, "R")
      let starts_with_l = string.starts_with(line, "L")
      let without_prefix_res =
        string.drop_start(line, 1)
        |> int.parse
        |> result.map_error(fn(_) { "Invalid input: " <> line })
      case Nil {
        _ if starts_with_r -> {
          use val_int <- result.try(without_prefix_res)
          Ok(Command(Right, val_int))
        }
        _ if starts_with_l -> {
          use val_int <- result.try(without_prefix_res)
          Ok(Command(Left, val_int))
        }
        _ -> Error("Invalid input: " <> line)
      }
    }),
  )

  let initial_state = State(cur_val: 50, num_times_at_0: 0)
  let result =
    list.fold(cmds, initial_state, fn(state, cmd) {
      let adjusted_cmd_val = case cmd.dir {
        Left -> cmd.val * -1
        Right -> cmd.val
      }
      let next_val = case state.cur_val + adjusted_cmd_val {
        val if val < 1 || val > 99 ->
          int.modulo(val, 100)
          |> result.lazy_unwrap(fn() { panic })
        val -> val
      }
      let next_num_times_at_0 = case next_val == 0 {
        True -> state.num_times_at_0 + 1
        False -> state.num_times_at_0
      }
      State(cur_val: next_val, num_times_at_0: next_num_times_at_0)
    })

  io.println(string.inspect(result))

  Ok(Nil)
}

type State {
  State(cur_val: Int, num_times_at_0: Int)
}

type Command {
  Command(dir: Dir, val: Int)
}

type Dir {
  Left
  Right
}

// -----------------------------------------------------------------------------
// Part 2

pub fn part_2_run(input: puzzle.Input) -> Result(Nil, String) {
  use input_str <- result.try(part_1_input(input))

  // Parse input into data structures
  use cmds <- result.try(
    string.split(input_str, on: "\n")
    |> list.filter(fn(str) { string.length(str) != 0 })
    |> list.try_map(fn(line) {
      let starts_with_r = string.starts_with(line, "R")
      let starts_with_l = string.starts_with(line, "L")
      let without_prefix_res =
        string.drop_start(line, 1)
        |> int.parse
        |> result.map_error(fn(_) { "Invalid input: " <> line })
      case Nil {
        _ if starts_with_r -> {
          use val_int <- result.try(without_prefix_res)
          list.repeat(Command(Right, 1), times: val_int)
          |> Ok
        }
        _ if starts_with_l -> {
          use val_int <- result.try(without_prefix_res)
          list.repeat(Command(Left, -1), times: val_int)
          |> Ok
        }
        _ -> Error("Invalid input: " <> line)
      }
    })
    |> result.map(list.flatten),
  )

  let initial_state = State(cur_val: 50, num_times_at_0: 0)
  let result =
    list.fold(cmds, initial_state, fn(state, cmd) {
      let next_val = case state.cur_val + cmd.val {
        val if val < 1 || val > 99 ->
          int.modulo(val, 100)
          |> result.lazy_unwrap(fn() { panic })
        val -> val
      }
      let next_num_times_at_0 = case next_val == 0 {
        True -> state.num_times_at_0 + 1
        False -> state.num_times_at_0
      }
      State(cur_val: next_val, num_times_at_0: next_num_times_at_0)
    })

  io.println(string.inspect(result))

  Ok(Nil)
}

// -----------------------------------------------------------------------------
// Inputs

fn part_1_input(input: puzzle.Input) -> Result(String, String) {
  case input {
    puzzle.Sample -> simplifile.read(from: "./src/days/day1/sample.txt")
    puzzle.Full -> simplifile.read(from: "./src/days/day1/full.txt")
  }
  |> result.map_error(string.inspect)
}
