import argv
import gleam/int
import gleam/io
import gleam/result

import days/day1
import days/day2
import days/day3
import days/day4
import days/day5
import days/day6
import days/day7
import days/day8
import days/day9
import days/day10
import days/day11
import days/day12
import puzzle

pub fn main() -> Nil {
  case main_help() {
    Error(msg) -> {
      io.println_error(msg)
      panic
    }
    Ok(Nil) -> {
      Nil
    }
  }
}

fn main_help() -> Result(Nil, String) {
  use day_part <- result.try(load_args())
  puzzle_calllback(day_part)
}

fn puzzle_calllback(day_part: DayPart) -> Result(Nil, String) {
  case day_part.day {
    1 -> {
      case day_part.part {
        Part1 -> day1.part_1_run(day_part.input)
        Part2 -> day1.part_2_run(day_part.input)
      }
    }
    2 -> {
      case day_part.part {
        Part1 -> day2.part_1_run(day_part.input)
        Part2 -> day2.part_2_run(day_part.input)
      }
    }
    3 -> {
      case day_part.part {
        Part1 -> day3.part_1_run(day_part.input)
        Part2 -> day3.part_2_run(day_part.input)
      }
    }
    4 -> {
      case day_part.part {
        Part1 -> day4.part_1_run(day_part.input)
        Part2 -> day4.part_2_run(day_part.input)
      }
    }
    5 -> {
      case day_part.part {
        Part1 -> day5.part_1_run(day_part.input)
        Part2 -> day5.part_2_run(day_part.input)
      }
    }
    6 -> {
      case day_part.part {
        Part1 -> day6.part_1_run(day_part.input)
        Part2 -> day6.part_2_run(day_part.input)
      }
    }
    7 -> {
      case day_part.part {
        Part1 -> day7.part_1_run(day_part.input)
        Part2 -> day7.part_2_run(day_part.input)
      }
    }
    8 -> {
      case day_part.part {
        Part1 -> day8.part_1_run(day_part.input)
        Part2 -> day8.part_2_run(day_part.input)
      }
    }
    9 -> {
      case day_part.part {
        Part1 -> day9.part_1_run(day_part.input)
        Part2 -> day9.part_2_run(day_part.input)
      }
    }
    10 -> {
      case day_part.part {
        Part1 -> day10.part_1_run(day_part.input)
        Part2 -> day10.part_2_run(day_part.input)
      }
    }
    11 -> {
      case day_part.part {
        Part1 -> day11.part_1_run(day_part.input)
        Part2 -> day11.part_2_run(day_part.input)
      }
    }
    12 -> {
      case day_part.part {
        Part1 -> day12.part_1_run(day_part.input)
        Part2 -> day12.part_2_run(day_part.input)
      }
    }
    day_int -> Error("Day " <> int.to_string(day_int) <> " is not yet support")
  }
}

/// Part one or two of a puzzle 
type Part {
  Part1
  Part2
}

type DayPart {
  DayPart(day: Int, part: Part, input: puzzle.Input)
}

/// Load argumuents
fn load_args() -> Result(DayPart, String) {
  case argv.load().arguments {
    [day_arg, part_arg, input_arg] ->
      result.map_error(
        {
          use day <- result.try(int.parse(day_arg))
          use part <- result.try(
            int.parse(part_arg)
            |> result.try(fn(part_int) {
              case part_int {
                1 -> Ok(Part1)
                2 -> Ok(Part2)
                _ -> Error(Nil)
              }
            }),
          )
          use input <- result.try(case input_arg {
            "sample" -> Ok(puzzle.Sample)
            "full" -> Ok(puzzle.Full)
            _ -> Error(Nil)
          })

          DayPart(day: day, part: part, input: input)
          |> Ok
        },
        fn(_) { parse_error_message },
      )
    _ -> Error(parse_error_message)
  }
}

/// Parse error message
const parse_error_message = "Unable to parse arguments.

Usage: aoc2025 <DAY> <PART> <INPUT>

where

DAY: 1 | 2 | ... | 12
PART: 1 | 2
INPUT: sample | full
"
