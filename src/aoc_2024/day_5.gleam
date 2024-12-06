import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import gleam/yielder
import utils/list as lu

pub type Pages =
  List(List(Int))

pub type Updates =
  List(List(Int))

pub type PagesUpdates =
  List(List(List(Int)))

fn get_middle_element(update: List(Int)) {
  let middle_index =
    { update |> list.length() |> int.to_float() } /. 2.0
    |> float.floor()
    |> float.round()

  yielder.from_list(update) |> yielder.at(middle_index) |> result.unwrap(0)
}

fn check_if_page_is_valid(update: List(Int), page: List(Int)) {
  let update_as_set = update |> set.from_list
  let page_as_set = page |> set.from_list

  case set.is_subset(page_as_set, update_as_set) {
    True -> {
      let assert [page_before, page_after] = page

      let assert Ok(page_before_index) = lu.find_index(update, page_before)
      let assert Ok(page_after_index) = lu.find_index(update, page_after)

      case page_before_index > page_after_index {
        True -> False
        False -> True
      }
    }
    False -> True
  }
}

fn check_if_update_is_valid(update: List(Int), pages: Pages) {
  let check_if_all_pages_are_valid =
    pages
    |> list.all(fn(page) { check_if_page_is_valid(update, page) })

  case check_if_all_pages_are_valid {
    True -> get_middle_element(update)
    False -> 0
  }
}

fn sort_pages_in_correct_order(update: List(Int), page: List(Int)) {
  let update_as_set = update |> set.from_list
  let page_as_set = page |> set.from_list

  case set.is_subset(page_as_set, update_as_set) {
    True -> {
      let assert [page_before, page_after] = page

      let page_before_index =
        lu.find_index(update, page_before) |> result.unwrap(0)
      let page_after_index =
        lu.find_index(update, page_after) |> result.unwrap(0)

      case page_before_index > page_after_index {
        True -> {
          let new_update =
            lu.swap_two_indexes(update, page_before_index, page_after_index)

          new_update
        }
        False -> update
      }
    }
    False -> update
  }
}

fn check_if_update_is_invalid_and_correct_it(
  update: List(Int),
  pages: Pages,
  first_traversal: Bool,
) {
  case first_traversal && check_if_update_is_valid(update, pages) > 0 {
    True -> 0
    False -> {
      let new_update =
        pages
        |> list.fold(update, fn(current_list, page) {
          let new_update = sort_pages_in_correct_order(current_list, page)

          new_update
        })

      case check_if_update_is_valid(new_update, pages) {
        0 -> check_if_update_is_invalid_and_correct_it(new_update, pages, False)
        _ -> get_middle_element(new_update)
      }
    }
  }
}

pub fn parse(input: String) {
  let split_on_newline = input |> string.split("\n\n")

  case split_on_newline {
    [] -> [[], []]
    [_] -> [[], []]
    [pages_lines, updates_lines] -> {
      let pages_lines_array =
        pages_lines
        |> string.split("\n")

      let pages =
        pages_lines_array
        |> list.map(fn(page_line) {
          let page = page_line |> string.split("|")

          case page {
            [] -> [0, 0]
            [_] -> [0, 0]
            [page_one, page_two] -> {
              let assert Ok(page_one_int) = int.parse(page_one)
              let assert Ok(page_two_int) = int.parse(page_two)

              [page_one_int, page_two_int]
            }
            _ -> [0, 0]
          }
        })

      let updates_lines_array =
        updates_lines
        |> string.split("\n")

      let updates =
        updates_lines_array
        |> list.map(fn(update_line) {
          let update =
            update_line
            |> string.split(",")
            |> list.map(fn(update) {
              case int.parse(update) {
                Ok(update_int) -> update_int
                Error(_) -> 0
              }
            })

          update
        })

      [pages, updates]
    }
    _ -> [[], []]
  }
}

pub fn pt_1(input: PagesUpdates) {
  let assert [pages, updates] = input

  let sum_of_valid_updates_middle_elements =
    updates
    |> list.fold(0, fn(accumulator, update) {
      let middle_element = check_if_update_is_valid(update, pages)

      accumulator + middle_element
    })

  sum_of_valid_updates_middle_elements
}

pub fn pt_2(input: PagesUpdates) {
  let assert [pages, updates] = input

  let sum_of_corrected_updates_middle_elements =
    updates
    |> list.fold(0, fn(accumulator, update) {
      let middle_element =
        check_if_update_is_invalid_and_correct_it(update, pages, True)

      accumulator + middle_element
    })

  sum_of_corrected_updates_middle_elements
}
