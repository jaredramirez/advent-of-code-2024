import gleeunit

import days/day2

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  let name = "Joe"
  let greeting = "Hello, " <> name <> "!"

  assert greeting == "Hello, Joe!"
}

pub fn is_number_palindrome_test() {
  assert day2.is_number_palindrome(55)
  assert day2.is_number_palindrome(1010)
  assert day2.is_number_palindrome(123_123)

  assert !day2.is_number_palindrome(1000)
  assert !day2.is_number_palindrome(913_847)
  assert !day2.is_number_palindrome(183_719)
}

pub fn only_looping_substr_test() {
  // assert day2.is_number_palindrome(55)
  // assert day2.is_number_palindrome(1010)
  // assert day2.is_number_palindrome(123_123)
  assert day2.is_number_palindrome(101_010)
  // assert !day2.is_number_palindrome(1000)
  // assert !day2.is_number_palindrome(913_847)
  // assert !day2.is_number_palindrome(183_719)
}
