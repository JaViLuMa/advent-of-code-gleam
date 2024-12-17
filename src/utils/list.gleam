import gleam/int
import gleam/io
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

pub fn at(l: List(a), index: Int) {
  l |> list.drop(index) |> list.first
}

pub fn swap_two_indexes(l: List(a), i: Int, j: Int) {
  let assert Ok(i_value) = at(l, i)
  let assert Ok(j_value) = at(l, j)

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

pub fn swap_two_indexes_yielder(l: yielder.Yielder(a), i: Int, j: Int) {
  let l_as_list = yielder.to_list(l)

  let assert Ok(i_value) = yielder.at(l, i)
  let assert Ok(j_value) = yielder.at(l, j)

  l_as_list
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
  |> yielder.from_list
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
    |> list.map(fn(row) { row |> string.to_graphemes })

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

pub fn slice(start: Int, end: Int, l: List(a)) {
  case l {
    [] -> []
    [_] -> []
    _ -> {
      l
      |> list.index_fold([], fn(accumulator, item, index) {
        case index >= start && index < end {
          True -> accumulator |> list.append([item])
          False -> accumulator
        }
      })
    }
  }
}

pub fn slice_yielder(start: Int, end: Int, l: yielder.Yielder(a)) {
  let l_as_list = yielder.to_list(l)

  let sliced_list = slice(start, end, l_as_list)

  sliced_list |> yielder.from_list
}

pub fn collection_of_suffixes(l: List(a)) {
  let all_suffixes =
    l
    |> list.index_map(fn(_, i) { slice(i, l |> list.length, l) })

  all_suffixes
  |> list.filter(fn(suffix) { suffix |> list.length > 1 })
}

pub fn range_with_step(start: Int, end: Int, step: Int) {
  case { step > 0 && start >= end } || { step < 0 && start <= end } {
    True -> []
    False -> {
      [start] |> list.append(range_with_step(start + step, end, step))
    }
  }
}

pub fn range_with_step_yielder(start: Int, end: Int, step: Int) {
  let range = range_with_step(start, end, step)

  range |> yielder.from_list
}

@external(erlang, "lists", "droplast")
pub fn pop(l: List(a)) -> List(a)

pub fn pop_yielder(l: yielder.Yielder(a)) {
  let l_as_list = yielder.to_list(l)

  let popped_list = pop(l_as_list)

  popped_list |> yielder.from_list
}

pub fn construct_matrix(width: Int, height: Int, character: String) {
  let width_range = list.range(1, width)
  let height_range = list.range(1, height)

  height_range
  |> list.map(fn(_) {
    width_range
    |> list.map(fn(_) { character })
  })
}

pub fn matrix_print(matrix: List(List(String))) {
  case matrix |> list.length == 0 {
    True -> Nil
    False -> {
      matrix
      |> list.each(fn(row) { io.println(row |> string.join(" ")) })

      io.println("")
    }
  }
}

pub fn rotate_matrix_clockwise_90(matrix: List(List(a))) {
  let transposed_matrix = matrix |> list.transpose

  transposed_matrix
  |> list.map(fn(row) { row |> list.reverse })
}

pub fn rotate_matrix_counter_clockwise_90(matrix: List(List(a))) {
  matrix |> list.transpose |> list.reverse
}
