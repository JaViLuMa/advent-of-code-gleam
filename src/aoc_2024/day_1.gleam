import gleam/result
import gleam/list
import gleam/string
import gleam/int
import gleam/dict

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

fn create_hash_map(numbers: List(Int)) {
  list.fold(numbers, dict.new(), fn (current_dictionary, number) {
    let has_key = dict.has_key(current_dictionary, number)

    case has_key {
      True -> {
        let old_value = dict.get(current_dictionary, number)
          |> result.unwrap(0)

        dict.insert(current_dictionary, number, old_value + 1)
      }
      False -> {
        dict.insert(current_dictionary, number, 1)
      }
    }
  })
}

pub fn pt_2(input: TupleListInt) {
  let #(left_column, right_column) = input

  let hash_map = create_hash_map(right_column)

  let similarity_score = left_column
    |> list.fold(0, fn (accumulator, left) {
      let count_of_left_in_right_column = dict.get(hash_map, left)
        |> result.unwrap(0)
        |> int.multiply(left)

      accumulator + count_of_left_in_right_column
    })

  similarity_score
}
