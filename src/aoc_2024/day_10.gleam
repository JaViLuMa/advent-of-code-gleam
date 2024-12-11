import gleam/list
import gleam/result
import gleam/set
import utils/list as lu

type TopographicMap =
  List(List(Int))

fn get_all_trailheads_positions(topographic_map: TopographicMap) {
  let trailheads =
    topographic_map
    |> list.index_fold([], fn(final_accumulator, row, row_index) {
      let row_col_pair =
        row
        |> list.index_fold([], fn(accumulator, value, column_index) {
          case value == 0 {
            True -> accumulator |> list.append([#(row_index, column_index)])
            False -> accumulator
          }
        })

      final_accumulator |> list.append(row_col_pair)
    })

  trailheads
}

fn is_out_of_bounds(topographic_map: TopographicMap, row: Int, col: Int) {
  let row_length = topographic_map |> list.length
  let specific_row = lu.at(topographic_map, row) |> result.unwrap([])
  let col_length = specific_row |> list.length

  case row < 0 || col < 0 || row >= row_length || col >= col_length {
    True -> True
    False -> False
  }
}

fn find_end_of_trail(
  row: Int,
  col: Int,
  topographic_map: TopographicMap,
  visited: set.Set(#(Int, Int)),
  previous_value: Int,
) {
  case is_out_of_bounds(topographic_map, row, col) {
    True -> #(visited, 0)
    False -> {
      let assert Ok(specific_row) = lu.at(topographic_map, row)
      let assert Ok(current_value) = lu.at(specific_row, col)

      case previous_value + 1 != current_value {
        True -> #(visited, 0)
        False -> {
          case current_value == 9 {
            True -> #(visited |> set.insert(#(row, col)), 1)
            False -> {
              let #(visited_above_row, value_above_row) =
                find_end_of_trail(
                  row - 1,
                  col,
                  topographic_map,
                  visited,
                  current_value,
                )
              let #(visited_below_row, value_below_row) =
                find_end_of_trail(
                  row + 1,
                  col,
                  topographic_map,
                  visited,
                  current_value,
                )
              let #(visited_left_col, value_left_col) =
                find_end_of_trail(
                  row,
                  col - 1,
                  topographic_map,
                  visited,
                  current_value,
                )
              let #(visited_right_col, value_right_col) =
                find_end_of_trail(
                  row,
                  col + 1,
                  topographic_map,
                  visited,
                  current_value,
                )

              #(
                visited
                  |> set.union(visited_above_row)
                  |> set.union(visited_below_row)
                  |> set.union(visited_left_col)
                  |> set.union(visited_right_col),
                value_above_row
                  + value_below_row
                  + value_left_col
                  + value_right_col,
              )
            }
          }
        }
      }
    }
  }
}

pub fn parse(input: String) {
  let topographic_map = lu.parse_matrix_as_ints(input)

  topographic_map
}

pub fn pt_1(topographic_map: TopographicMap) {
  let trailheads = get_all_trailheads_positions(topographic_map)

  let sum_of_trailheads =
    trailheads
    |> list.fold(0, fn(accumulator, trailhead) {
      let #(row, col) = trailhead

      let #(visited, _) =
        find_end_of_trail(row, col, topographic_map, set.new(), -1)

      accumulator + { visited |> set.size }
    })

  sum_of_trailheads
}

pub fn pt_2(topographic_map: TopographicMap) {
  let trailheads = get_all_trailheads_positions(topographic_map)

  let sum_of_trailheads_ratings =
    trailheads
    |> list.fold(0, fn(accumulator, trailhead) {
      let #(row, col) = trailhead

      let #(_, rating) =
        find_end_of_trail(row, col, topographic_map, set.new(), -1)

      accumulator + rating
    })

  sum_of_trailheads_ratings
}
