import gleam/list
import gleam/result
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

pub fn enumerate_grid(grid_list: List(List(a))) {
  let rows_with_index = enumerate(grid_list)

  list.flat_map(rows_with_index, fn(row_with_index) {
    let #(row_index, row) = row_with_index

    list.index_map(row, fn(col, col_index) { #(row_index, col_index, col) })
  })
}
