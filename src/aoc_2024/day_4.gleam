import gleam/list
import gleam/result
import gleam/string
import gleam/yielder

type Crossword =
  yielder.Yielder(List(String))

const directions = [
  #(0, 1), #(1, 0), #(0, -1), #(-1, 0), #(1, 1), #(-1, -1), #(-1, 1), #(1, -1),
]

const valid_mas_patterns = ["SMMS", "MSSM", "MMSS", "SSMM"]

fn is_crossword_border(crossword: Crossword, row: Int, col: Int) {
  let crossword_column =
    yielder.at(crossword, row)
    |> result.unwrap([])

  row < 0
  || col < 0
  || row >= yielder.length(crossword)
  || col >= list.length(crossword_column)
}

fn get_word_as_yielder(word: String) {
  yielder.from_list(word |> string.split(""))
}

fn get_current_word_letter(word: yielder.Yielder(String), word_index: Int) {
  let assert Ok(curr_word_letter) = yielder.at(word, word_index)

  curr_word_letter
}

fn get_adjacent_letters(
  crossword: Crossword,
  row: Int,
  col: Int,
  word: String,
  word_index: Int,
  row_dir: Int,
  col_dir: Int,
) {
  case word_index == string.length(word) {
    True -> 1
    False -> {
      let curr_row =
        yielder.at(crossword, row)
        |> result.unwrap([])

      let curr_letter =
        yielder.at(yielder.from_list(curr_row), col)
        |> result.unwrap("")

      let word_as_yielder = get_word_as_yielder(word)

      let curr_word_letter =
        get_current_word_letter(word_as_yielder, word_index)

      case
        is_crossword_border(crossword, row, col)
        || curr_letter != curr_word_letter
      {
        True -> 0
        False ->
          get_adjacent_letters(
            crossword,
            row + row_dir,
            col + col_dir,
            word,
            word_index + 1,
            row_dir,
            col_dir,
          )
      }
    }
  }
}

fn count_xmas_occurrences(
  crossword: Crossword,
  word: String,
  row: Int,
  col: Int,
) {
  case row >= yielder.length(crossword) {
    True -> 0
    False -> {
      let assert Ok(curr_row) = yielder.at(crossword, row)

      case col >= list.length(curr_row) {
        True -> count_xmas_occurrences(crossword, word, row + 1, 0)
        False -> {
          let assert Ok(curr_letter) =
            yielder.at(yielder.from_list(curr_row), col)

          let count = 0

          let word_as_yielder = get_word_as_yielder(word)

          let curr_word_letter = get_current_word_letter(word_as_yielder, 0)

          case curr_letter == curr_word_letter {
            True -> {
              let count =
                directions
                |> list.fold(0, fn(accumulator, direction) {
                  let #(row_dir, col_dir) = direction

                  accumulator
                  + get_adjacent_letters(
                    crossword,
                    row,
                    col,
                    word,
                    0,
                    row_dir,
                    col_dir,
                  )
                })

              count + count_xmas_occurrences(crossword, word, row, col + 1)
            }
            False ->
              count + count_xmas_occurrences(crossword, word, row, col + 1)
          }
        }
      }
    }
  }
}

fn construct_pattern(crossword: Crossword, row, col) {
  let assert Ok(row_above) = yielder.at(crossword, row - 1)
  let assert Ok(row_below) = yielder.at(crossword, row + 1)

  let top_left =
    yielder.at(yielder.from_list(row_above), col - 1)
    |> result.unwrap("")
  let top_right =
    yielder.at(yielder.from_list(row_above), col + 1)
    |> result.unwrap("")
  let bottom_left =
    yielder.at(yielder.from_list(row_below), col - 1)
    |> result.unwrap("")
  let bottom_right =
    yielder.at(yielder.from_list(row_below), col + 1)
    |> result.unwrap("")

  top_left
  |> string.append(top_right)
  |> string.append(bottom_right)
  |> string.append(bottom_left)
}

fn count_mas_occurrence(crossword: Crossword, row, col) {
  case row >= yielder.length(crossword) - 1 {
    True -> 0
    False -> {
      let assert Ok(curr_row) = yielder.at(crossword, row)

      case col >= list.length(curr_row) - 1 {
        True -> count_mas_occurrence(crossword, row + 1, 1)
        False -> {
          let count = 0

          let assert Ok(curr_letter) =
            yielder.at(yielder.from_list(curr_row), col)

          case curr_letter == "A" {
            True -> {
              let pattern = construct_pattern(crossword, row, col)

              let find_concatenated_word_in_valid_mas_patterns =
                valid_mas_patterns
                |> list.find(fn(valid_mas_pattern) {
                  valid_mas_pattern == pattern
                })

              case find_concatenated_word_in_valid_mas_patterns {
                Ok(_) ->
                  count + count_mas_occurrence(crossword, row, col + 1) + 1
                Error(_) ->
                  count + count_mas_occurrence(crossword, row, col + 1)
              }
            }
            False -> count + count_mas_occurrence(crossword, row, col + 1)
          }
        }
      }
    }
  }
}

pub fn parse(input: String) {
  let crossword =
    input
    |> string.split("\n")
    |> list.map(fn(line) {
      line
      |> string.split("")
    })

  yielder.from_list(crossword)
}

pub fn pt_1(crossword: Crossword) {
  let count_xmas = count_xmas_occurrences(crossword, "XMAS", 0, 0)

  count_xmas
}

pub fn pt_2(crossword: Crossword) {
  let count_mas = count_mas_occurrence(crossword, 1, 1)

  count_mas
}
