import gleam/result
import gleam/list
import gleam/string
import gleam/int

pub type TupleListInt = #(List(Int), List(Int))

fn split_pair(pair: String) -> #(Int, Int) {
  let parts = string.split(pair, on: "   ")

  case parts {
    [left, right, ..] -> {
      let left_int = int.parse(left)
        |> result.unwrap(0)
      
      let right_int = int.parse(right)
        |> result.unwrap(0)

      #(left_int, right_int)
    }
    _ -> #(0, 0)
  }
}

pub fn process_pairs(input: List(String)) -> TupleListInt {
  let parsed_pairs = list.map(input, split_pair)

  let #(left_column, right_column) = list.unzip(parsed_pairs)

  #(left_column, right_column)
}

pub fn parse(input: String) -> TupleListInt {
  let lines = string.split(input, on: "\n")

  let #(left_column, right_column) = process_pairs(lines)

  let sorted_left_column = list.sort(left_column, int.compare)
  let sorted_right_column = list.sort(right_column, int.compare)

  #(sorted_left_column, sorted_right_column)
}

pub fn pt_1(input: TupleListInt) -> Int {
  let #(left_column, right_column) = input

  let zipped_lists = list.zip(left_column, right_column)

  let differences_sum = zipped_lists
    |> list.fold(0, fn (accumulator, pair) {
      let #(left, right) = pair

      let difference = int.absolute_value(left - right)

      accumulator + difference
    })

  differences_sum
}

pub fn pt_2(input: TupleListInt) -> Int {
  let #(left_column, right_column) = input

  let similarity_score = left_column
    |> list.fold(0, fn (accumulator, left) {
      let count_of_left_in_right_column = right_column
        |> list.count(fn (right) {
          left == right
        })
        |> int.multiply(left)

      accumulator + count_of_left_in_right_column
    })

  similarity_score
}
