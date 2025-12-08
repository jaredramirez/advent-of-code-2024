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

pub fn day_3_build_combinations_test() {
  assert day3.build_combinations("") == []
  assert day3.build_combinations("1") == ["1"]
  assert day3.build_combinations("12") == ["1", "12", "2"]
  assert day3.build_combinations("123")
    == ["1", "12", "123", "13", "2", "23", "3"]
}

pub fn day_3_get_highest_combo2_test() {
  assert day3.get_max_joltage("987654321111111") == Ok(987_654_321_111)
  assert day3.get_max_joltage("811111111111119") == Ok(811_111_111_119)
  assert day3.get_max_joltage("234234234234278") == Ok(434_234_234_278)
  assert day3.get_max_joltage("818181911112111") == Ok(888_911_112_111)
}
