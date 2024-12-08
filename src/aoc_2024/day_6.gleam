import gleam/dict.{type Dict}
import gleam/list
import gleam/set
import gleam/string
import utils/list as lu

type IntPairs =
  #(Int, Int)

type PairOfPairs =
  #(IntPairs, IntPairs)

type MatrixDict =
  Dict(IntPairs, String)

type MatrixDictGuard =
  #(MatrixDict, IntPairs)

fn traverse_the_grid(
  matrix: MatrixDict,
  guard: IntPairs,
  direction: IntPairs,
  path_list_arg: List(PairOfPairs),
  path_set_arg: set.Set(PairOfPairs),
) {
  let path_item = #(guard, direction)

  let path_set_contains_path_item = set.contains(path_set_arg, path_item)

  case path_set_contains_path_item {
    True -> {
      #(path_list_arg, True)
    }
    False -> {
      let path_list =
        path_list_arg
        |> list.append([path_item])

      let path_set = set.insert(path_set_arg, path_item)

      let #(guard_row, guard_col) = guard
      let #(direction_y, direction_x) = direction

      let next_guard_position = #(
        guard_row + direction_y,
        guard_col + direction_x,
      )

      let has_next_guard_position = dict.get(matrix, next_guard_position)

      case has_next_guard_position {
        Ok(_) -> {
          let assert Ok(next_position) = dict.get(matrix, next_guard_position)

          case next_position == "#" {
            True -> {
              let next_direction = #(direction_x, -direction_y)

              traverse_the_grid(
                matrix,
                guard,
                next_direction,
                path_list,
                path_set,
              )
            }
            False -> {
              traverse_the_grid(
                matrix,
                next_guard_position,
                direction,
                path_list,
                path_set,
              )
            }
          }
        }
        Error(_) -> #(path_list, False)
      }
    }
  }
}

pub fn parse(input: String) {
  let lines =
    input
    |> string.split("\n")

  let matrix =
    lines
    |> list.map(fn(line) {
      line
      |> string.split("")
    })

  let enumerated_matrix = lu.enumerate_matrix(matrix)

  let matrix_dict =
    matrix
    |> list.index_fold(dict.new(), fn(current_dictionary, row, row_index) {
      row
      |> list.index_fold(
        current_dictionary,
        fn(current_dictionary, letter, col_index) {
          dict.insert(current_dictionary, #(row_index, col_index), letter)
        },
      )
    })

  let assert Ok(guard) =
    enumerated_matrix
    |> list.find_map(fn(cell) {
      let #(row_index, col_index, letter) = cell

      case letter == "^" {
        True -> Ok(#(row_index, col_index))
        False -> Error("guard not found")
      }
    })

  #(matrix_dict, guard)
}

pub fn pt_1(input: MatrixDictGuard) {
  let #(matrix_dict, guard) = input

  let traversed_path =
    traverse_the_grid(matrix_dict, guard, #(-1, 0), [], set.new())

  let #(path, _) = traversed_path

  let path_length =
    set.from_list(
      path
      |> list.map(fn(cell) {
        let #(coordinates, _) = cell

        coordinates
      }),
    )
    |> set.size

  path_length
}

pub fn pt_2(input: MatrixDictGuard) {
  let #(matrix_dict, guard) = input

  let total_infinite_loops =
    matrix_dict
    |> dict.fold(0, fn(dict_accumulator, key, value) {
      let new_dict = case value == "." {
        True -> matrix_dict |> dict.upsert(key, fn(_) { "#" })
        False -> matrix_dict
      }

      let traversed_path =
        traverse_the_grid(new_dict, guard, #(-1, 0), [], set.new())

      let #(_, is_infinite_loop) = traversed_path

      case is_infinite_loop {
        True -> dict_accumulator + 1
        False -> dict_accumulator
      }
    })

  total_infinite_loops
}
