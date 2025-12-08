import gleam/int
import gleam/io
import gleam/result
import gleam/string

pub type ContinueOrStop(loop_state, final) {
  Continue(loop_state)
  Stop(final)
}

/// Starting from an initial state, loop until termination
pub fn loop(
  from state: state,
  with fun: fn(state) -> ContinueOrStop(state, final),
) -> final {
  case fun(state) {
    Stop(final_state) -> final_state
    Continue(next_state) -> loop(from: next_state, with: fun)
  }
}

pub fn div_with_remainder(dividend: Int, divisor: Int) -> #(Int, Int) {
  let div = dividend / divisor
  let remainder =
    int.modulo(dividend, divisor)
    |> result.lazy_unwrap(fn() { panic })

  io.println(
    "div_with_remainder: "
    <> string.inspect(dividend)
    <> " "
    <> string.inspect(divisor)
    <> " "
    <> string.inspect(#(div, remainder)),
  )

  #(div, remainder)
}
