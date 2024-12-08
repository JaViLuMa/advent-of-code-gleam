import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder

pub fn find_index(l: List(a), value: a) {
  list.index_map(l, fn(v, i) { #(i, v) })
  |> list.find(fn(pair) {
    let #(_, v) = pair

    v == value
  })
  |> result.map(fn(pair) {
    let #(i, _) = pair

    i
  })
}

pub fn swap_two_indexes(l: List(a), i: Int, j: Int) {
  let l_as_yielder = yielder.from_list(l)

  let assert Ok(i_value) = yielder.at(l_as_yielder, i)
  let assert Ok(j_value) = yielder.at(l_as_yielder, j)

  l
  |> list.index_fold([], fn(current_list, item, index) {
    case index == i {
      True -> current_list |> list.append([j_value])
      False -> {
        case index == j {
          True -> current_list |> list.append([i_value])
          False -> current_list |> list.append([item])
        }
      }
    }
  })
}

pub fn enumerate(l: List(a)) {
  list.index_map(l, fn(v, i) { #(i, v) })
}

pub fn enumerate_matrix(matrix: List(List(a))) {
  let rows_with_index = enumerate(matrix)

  list.flat_map(rows_with_index, fn(row_with_index) {
    let #(row_index, row) = row_with_index

    list.index_map(row, fn(col, col_index) { #(row_index, col_index, col) })
  })
}

pub fn parse_matrix(input: String) {
  let rows = input |> string.split("\n")

  let matrix =
    rows
    |> list.map(fn(row) { row |> string.split("") })

  matrix
}

pub fn parse_matrix_as_ints(input: String) {
  let rows = input |> string.split("\n")

  let matrix =
    rows
    |> list.map(fn(row) {
      row
      |> string.split("")
      |> list.map(fn(cell) {
        let assert Ok(cell_as_int) = int.parse(cell)

        cell_as_int
      })
    })

  matrix
}

pub fn slice(start: Int, end: Int, l: List(a), current_index: Int) {
  case l {
    [] -> []
    [_] -> l
    _ -> {
      let assert [head, ..tail] = l

      case current_index >= end {
        True -> []
        False -> {
          case current_index < start {
            True -> slice(start, end, tail, current_index + 1)
            False -> [head, ..slice(start, end, tail, current_index + 1)]
          }
        }
      }
    }
  }
}

pub fn collection_of_suffixes(l: List(a)) {
  let all_suffixes =
    l
    |> list.index_map(fn(_, i) { slice(i, l |> list.length, l, 0) })

  all_suffixes
  |> list.filter(fn(suffix) { suffix |> list.length > 1 })
}
