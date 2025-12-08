/// Part one or two of a puzzle 
pub type Puzzle {
  Puzzle(part_1_run: PuzzleCallback, part_2_run: PuzzleCallback)
}

pub type PuzzleCallback =
  fn(Input) -> Result(Nil, String)

/// Part one or two of a puzzle 
pub type Input {
  Sample
  Full
}
