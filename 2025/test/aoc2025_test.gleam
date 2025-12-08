import gleam/order
import gleam/string
import gleeunit

import days/day2
import days/day3

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn str_compare_test() {
  assert string.compare("1", "2") == order.Lt
  assert string.compare("9", "8") == order.Gt
}

pub fn day_2_is_number_palindrome_test() {
  assert day2.is_number_palindrome(55)
  assert day2.is_number_palindrome(1010)
  assert day2.is_number_palindrome(123_123)

  assert !day2.is_number_palindrome(1000)
  assert !day2.is_number_palindrome(913_847)
  assert !day2.is_number_palindrome(183_719)
}

pub fn day_2_only_looping_substr_test() {
  assert day2.only_looping_substr(55)
  assert day2.only_looping_substr(1010)
  assert day2.only_looping_substr(123_123)
  assert day2.only_looping_substr(101_010)

  assert !day2.only_looping_substr(1000)
  assert !day2.only_looping_substr(913_847)
  assert !day2.only_looping_substr(183_719)
}

pub fn day_3_get_highest_combo_test() {
  assert day3.get_highest_combo("") == Error(Nil)
  assert day3.get_highest_combo("1234") == Ok("34")
  assert day3.get_highest_combo("91837") == Ok("98")
}
