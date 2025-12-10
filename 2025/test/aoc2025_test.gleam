import gleam/order
import gleam/result
import gleam/string
import gleeunit
import iv
import non_empty_list

import days/day2
import days/day3
import days/day5
import days/day6

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn random_test() {
  assert string.compare("1", "2") == order.Lt
  assert string.compare("9", "8") == order.Gt
  assert string.split("123   33 1  33", on: " ")
    == ["123", "", "", "33", "1", "", "33"]
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

pub fn day_3_pick_best_number_test() {
  assert day3.pick_best_number(string.to_graphemes(""), 1) == Error(Nil)

  assert day3.pick_best_number(string.to_graphemes("1"), 1)
    == Ok(#("1", non_empty_list.new(0, [])))

  assert day3.pick_best_number(string.to_graphemes("1234"), 1)
    == Ok(#("4", non_empty_list.new(3, [])))

  assert day3.pick_best_number(string.to_graphemes("1234"), 2)
    == Ok(#("3", non_empty_list.new(2, [])))

  assert day3.pick_best_number(string.to_graphemes("1234321"), 2)
    == Ok(#("4", non_empty_list.new(3, [])))

  assert day3.pick_best_number(string.to_graphemes("987654321111111"), 2)
    == Ok(#("9", non_empty_list.new(0, [])))

  assert day3.pick_best_number(string.to_graphemes("87654321111111"), 1)
    == Ok(#("8", non_empty_list.new(0, [])))
}

pub fn day_3_get_highest_combo2_test() {
  assert day3.get_max_joltage("987654321111111", 2) == Ok(98)
  assert day3.get_max_joltage("987654321111111", 12) == Ok(987_654_321_111)

  assert day3.get_max_joltage("811111111111119", 2) == Ok(89)
  assert day3.get_max_joltage("811111111111119", 12) == Ok(811_111_111_119)

  assert day3.get_max_joltage("234234234234278", 2) == Ok(78)
  assert day3.get_max_joltage("234234234234278", 12) == Ok(434_234_234_278)

  assert day3.get_max_joltage("818181911112111", 2) == Ok(92)
  assert day3.get_max_joltage("818181911112111", 12) == Ok(888_911_112_111)
}

pub fn day5_compare_ranges_test() {
  assert day5.compare_ranges(day5.Range(0, 1), day5.Range(4, 5))
    == day5.NoOverlap

  assert day5.compare_ranges(day5.Range(0, 1), day5.Range(1, 2))
    == day5.AEndBStartOverlap

  assert day5.compare_ranges(day5.Range(1, 2), day5.Range(0, 1))
    == day5.BEndAStartOverlap

  assert day5.compare_ranges(day5.Range(1, 2), day5.Range(0, 1))
    == day5.BEndAStartOverlap

  assert day5.compare_ranges(day5.Range(1, 10), day5.Range(5, 6))
    == day5.BContainedWithinA

  assert day5.compare_ranges(day5.Range(5, 6), day5.Range(1, 10))
    == day5.AContainedWithinB

  assert day5.compare_ranges(day5.Range(50, 100), day5.Range(150, 200))
    == day5.NoOverlap
}

pub fn day5_merge_ranges_test() {
  assert day5.merge_ranges(day5.Range(0, 1), day5.Range(4, 5)) == Error(Nil)

  assert day5.merge_ranges(day5.Range(0, 1), day5.Range(1, 2))
    == Ok(day5.Range(0, 2))

  assert day5.merge_ranges(day5.Range(1, 2), day5.Range(0, 1))
    == Ok(day5.Range(0, 2))

  assert day5.merge_ranges(day5.Range(7, 10), day5.Range(5, 8))
    == Ok(day5.Range(5, 10))

  assert day5.merge_ranges(day5.Range(1, 10), day5.Range(5, 6))
    == Ok(day5.Range(1, 10))

  assert day5.merge_ranges(day5.Range(5, 6), day5.Range(1, 10))
    == Ok(day5.Range(1, 10))

  assert day5.merge_ranges(day5.Range(50, 100), day5.Range(150, 200))
    == Error(Nil)

  assert day5.merge_ranges(day5.Range(10, 18), day5.Range(16, 20))
    == Ok(day5.Range(10, 20))
}

pub fn day6_rotate_arrays_test() {
  {
    let lhs =
      iv.from_list([
        iv.from_list([1, 2, 3]),
        iv.from_list([4, 5, 6]),
      ])
    let rhs =
      iv.from_list([
        iv.from_list([1, 4]),
        iv.from_list([2, 5]),
        iv.from_list([3, 6]),
      ])
    assert day6.rotate_arrays(lhs) == Ok(rhs)
  }

  {
    let lhs =
      iv.from_list([
        iv.from_list([1, 2, 3]),
        iv.from_list([4, 5]),
      ])
    assert result.is_error(day6.rotate_arrays(lhs))
  }
}

pub fn day6_str_to_cephalopod_num_test() {
  assert {
      day6.str_to_cephalopod_nums(iv.from_list(["64 ", "23 ", "314"]))
      |> result.map(iv.to_list)
    }
    == Ok([4, 431, 623])

  assert {
      day6.str_to_cephalopod_nums(iv.from_list([" 51", "387", "215"]))
      |> result.map(iv.to_list)
    }
    == Ok([175, 581, 32])
}
