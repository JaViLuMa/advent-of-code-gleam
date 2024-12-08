import gleam/dict
import gleam/list
import gleam/result
import gleam/set
import gleam/yielder
import utils/list as lu

type Cell =
  #(Int, Int, String)

type Matrix =
  List(List(String))

type FrequencyMap =
  List(Cell)

type MatrixFrequencyMap =
  #(Matrix, FrequencyMap)

type MapDict =
  dict.Dict(String, List(FrequencyMap))

fn antinode_in_or_out_of_bounds(
  row_index: Int,
  col_index: Int,
  matrix_row_length: Int,
  matrix_col_length: Int,
) {
  row_index < 0
  || row_index >= matrix_row_length
  || col_index < 0
  || col_index >= matrix_col_length
}

fn get_positions_until_boundary(
  head: Cell,
  value: Cell,
  matrix_row_length: Int,
  matrix_col_length: Int,
  current_antinodes: List(Cell),
) {
  let #(cell_row_index, cell_col_index, _) = head

  let antinode_positions = case
    antinode_in_or_out_of_bounds(
      cell_row_index,
      cell_col_index,
      matrix_row_length,
      matrix_col_length,
    )
  {
    True -> current_antinodes
    False -> {
      let current_antinodes =
        current_antinodes
        |> list.append([#(cell_row_index, cell_col_index, "#")])

      let #(row_index, col_index, _) = value

      let row_diff = cell_row_index - row_index
      let col_diff = cell_col_index - col_index

      let antinode_from_head_row = cell_row_index + row_diff
      let antinode_from_head_col = cell_col_index + col_diff

      let new_head_cell = #(antinode_from_head_row, antinode_from_head_col, "#")

      get_positions_until_boundary(
        new_head_cell,
        head,
        matrix_row_length,
        matrix_col_length,
        current_antinodes,
      )
    }
  }

  antinode_positions
}

fn get_positions(
  collection_of_suffixes: List(FrequencyMap),
  matrix_row_length: Int,
  matrix_col_length: Int,
  part_two: Bool,
) {
  collection_of_suffixes
  |> list.fold([], fn(final_accumulator, values) {
    let assert [head_value, ..tail_values] = values

    let #(head_row_index, head_col_index, _) = head_value

    let antinodes =
      tail_values
      |> list.fold([], fn(accumulator, value) {
        let #(row_index, col_index, _) = value

        case part_two {
          True -> {
            let all_antinode_positions_from_head =
              get_positions_until_boundary(
                head_value,
                value,
                matrix_row_length,
                matrix_col_length,
                [],
              )
            let all_antinode_positions_from_value =
              get_positions_until_boundary(
                value,
                head_value,
                matrix_row_length,
                matrix_col_length,
                [],
              )

            accumulator
            |> list.append(all_antinode_positions_from_head)
            |> list.append(all_antinode_positions_from_value)
          }
          False -> {
            let row_diff = head_row_index - row_index
            let col_diff = head_col_index - col_index

            let antinode_from_head_row = head_row_index + row_diff
            let antinode_from_head_col = head_col_index + col_diff

            let antinode_from_value_row = row_index + { -row_diff }
            let antinode_from_value_col = col_index + { -col_diff }

            let head_in_or_out_of_bounds =
              antinode_in_or_out_of_bounds(
                antinode_from_head_row,
                antinode_from_head_col,
                matrix_row_length,
                matrix_col_length,
              )
            let value_in_or_out_of_bounds =
              antinode_in_or_out_of_bounds(
                antinode_from_value_row,
                antinode_from_value_col,
                matrix_row_length,
                matrix_col_length,
              )

            accumulator
            |> list.append(case head_in_or_out_of_bounds {
              True -> []
              False -> [#(antinode_from_head_row, antinode_from_head_col, "#")]
            })
            |> list.append(case value_in_or_out_of_bounds {
              True -> []
              False -> [
                #(antinode_from_value_row, antinode_from_value_col, "#"),
              ]
            })
          }
        }
      })

    final_accumulator |> list.append(antinodes)
  })
}

fn calculate_unique_antinode_positions(
  map_dict: MapDict,
  matrix_row_length: Int,
  matrix_col_length: Int,
  part_two: Bool,
) {
  let antinodes =
    map_dict
    |> dict.fold(set.new(), fn(accumulator, _, value) {
      let antinode_positions =
        get_positions(value, matrix_row_length, matrix_col_length, part_two)

      let antinode_positions_as_set = antinode_positions |> set.from_list

      set.union(accumulator, antinode_positions_as_set)
    })

  antinodes
}

fn create_filtered_positions(map: FrequencyMap) {
  let map_without_dots =
    map
    |> list.filter(fn(cell) {
      let #(_, _, letter) = cell

      letter != "."
    })

  map_without_dots
  |> list.fold(dict.new(), fn(current_dictionary, cell) {
    let #(_, _, letter) = cell

    case dict.has_key(current_dictionary, letter) {
      True -> {
        let assert Ok(current_value) = dict.get(current_dictionary, letter)

        dict.insert(
          current_dictionary,
          letter,
          current_value |> list.append([cell]),
        )
      }
      False -> dict.insert(current_dictionary, letter, [cell])
    }
  })
}

fn dict_with_collection_of_suffixes(map: FrequencyMap) {
  let filtered_positions = create_filtered_positions(map)

  filtered_positions
  |> dict.map_values(fn(_, value) { value |> lu.collection_of_suffixes })
}

fn get_matrix_lengths(matrix: Matrix) {
  let matrix_row_length = matrix |> list.length

  let matrix_as_yielder = yielder.from_list(matrix)

  let matrix_col_length =
    matrix_as_yielder |> yielder.at(0) |> result.unwrap([]) |> list.length

  #(matrix_row_length, matrix_col_length)
}

pub fn parse(input: String) {
  let matrix = lu.parse_matrix(input)

  let enumerated_matrix = lu.enumerate_matrix(matrix)

  #(matrix, enumerated_matrix)
}

pub fn pt_1(input: MatrixFrequencyMap) {
  let #(matrix, enumerated_matrix) = input

  let positions_dictionary = dict_with_collection_of_suffixes(enumerated_matrix)

  let #(matrix_row_length, matrix_col_length) = get_matrix_lengths(matrix)

  let unique_antinode_positions =
    calculate_unique_antinode_positions(
      positions_dictionary,
      matrix_row_length,
      matrix_col_length,
      False,
    )

  unique_antinode_positions |> set.size
}

pub fn pt_2(input: MatrixFrequencyMap) {
  let #(matrix, enumerated_matrix) = input

  let positions_dictionary = dict_with_collection_of_suffixes(enumerated_matrix)

  let #(matrix_row_length, matrix_col_length) = get_matrix_lengths(matrix)

  let unique_antinode_positions =
    calculate_unique_antinode_positions(
      positions_dictionary,
      matrix_row_length,
      matrix_col_length,
      True,
    )

  unique_antinode_positions |> set.size
}
