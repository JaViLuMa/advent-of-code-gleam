import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/string

type Stones =
  List(String)

type DictOfStones =
  dict.Dict(Int, Int)

type Items =
  List(#(Int, Int))

fn split_string_in_half(stone: String) {
  let string_as_list = stone |> string.to_graphemes

  let string_length = string_as_list |> list.length

  let first_half = string_as_list |> list.take(string_length / 2)
  let second_half = string_as_list |> list.drop(string_length / 2)

  let first_half = case first_half |> list.all(fn(char) { char == "0" }) {
    True -> 0
    False -> {
      let joined_first_half = first_half |> string.join("")

      let assert Ok(first_half_as_integer) = joined_first_half |> int.parse

      first_half_as_integer
    }
  }

  let second_half = case second_half |> list.all(fn(char) { char == "0" }) {
    True -> 0
    False -> {
      let joined_second_half = second_half |> string.join("")

      let assert Ok(second_half_as_integer) = joined_second_half |> int.parse

      second_half_as_integer
    }
  }

  #(first_half, second_half)
}

fn compute_updates_recursively(items: Items, accumulator: DictOfStones) {
  case items |> list.length == 0 {
    True -> accumulator
    False -> {
      let assert Ok(#(key, value)) = items |> list.first

      let new_dict =
        accumulator
        |> dict.upsert(key, fn(v) {
          case v {
            option.Some(i) -> i - value
            option.None -> 0 - value
          }
        })

      case key == 0 {
        True -> {
          let new_dict =
            new_dict
            |> dict.upsert(1, fn(v) {
              case v {
                option.Some(i) -> i + value
                option.None -> 0 + value
              }
            })

          let new_items = items |> list.drop(1)

          compute_updates_recursively(new_items, new_dict)
        }
        False -> {
          let key_as_string = key |> int.to_string

          let key_as_string_length = key_as_string |> string.length

          case key_as_string_length % 2 == 0 {
            True -> {
              let #(first_half, second_half) =
                split_string_in_half(key_as_string)

              let new_dict =
                new_dict
                |> dict.upsert(first_half, fn(v) {
                  case v {
                    option.Some(i) -> i + value
                    option.None -> 0 + value
                  }
                })
                |> dict.upsert(second_half, fn(v) {
                  case v {
                    option.Some(i) -> i + value
                    option.None -> 0 + value
                  }
                })

              let new_items = items |> list.drop(1)

              compute_updates_recursively(new_items, new_dict)
            }
            False -> {
              let multiplied_key = key * 2024

              let new_dict =
                new_dict
                |> dict.upsert(multiplied_key, fn(v) {
                  case v {
                    option.Some(i) -> i + value
                    option.None -> 0 + value
                  }
                })

              let new_items = items |> list.drop(1)

              compute_updates_recursively(new_items, new_dict)
            }
          }
        }
      }
    }
  }
}

fn compute_updates(dict_of_stones: DictOfStones) {
  let items = dict_of_stones |> dict.to_list

  compute_updates_recursively(items, dict.new())
}

fn apply_updates(
  dict_of_stones: DictOfStones,
  updates: DictOfStones,
  updates_keys: List(Int),
) {
  case updates_keys |> list.length == 0 {
    True -> dict_of_stones
    False -> {
      let assert Ok(first_key) = updates_keys |> list.first

      let assert Ok(value) = updates |> dict.get(first_key)

      let new_dict_of_stones =
        dict_of_stones
        |> dict.upsert(first_key, fn(v) {
          case v {
            option.Some(i) -> i + value
            option.None -> 0 + value
          }
        })

      let assert Ok(value_at_first_key) =
        new_dict_of_stones |> dict.get(first_key)

      case value_at_first_key == 0 {
        True ->
          apply_updates(
            new_dict_of_stones |> dict.drop([first_key]),
            updates,
            updates_keys |> list.drop(1),
          )
        False ->
          apply_updates(
            new_dict_of_stones,
            updates,
            updates_keys |> list.drop(1),
          )
      }
    }
  }
}

fn blink(dict_of_stones: DictOfStones, blink_amount: Int) {
  case blink_amount == 0 {
    True -> dict_of_stones
    False -> {
      let updates = compute_updates(dict_of_stones)

      let updates_keys =
        updates
        |> dict.fold([], fn(accumulator, key, _) {
          accumulator |> list.append([key])
        })

      let new_dict_of_stones =
        apply_updates(dict_of_stones, updates, updates_keys)

      blink(new_dict_of_stones, blink_amount - 1)
    }
  }
}

fn get_sum_of_stone_values(stones: DictOfStones) {
  stones
  |> dict.fold(0, fn(accumulator, _, value) { accumulator + value })
}

pub fn parse(input: String) {
  input |> string.split(" ")
}

pub fn pt_1(stones: Stones) {
  let dict_of_stones =
    stones
    |> list.fold(dict.new(), fn(stone_dict, stone) {
      let assert Ok(stone_as_integer) = stone |> int.parse

      stone_dict |> dict.insert(stone_as_integer, 1)
    })

  let stones = blink(dict_of_stones, 25)

  let sum = get_sum_of_stone_values(stones)

  sum
}

pub fn pt_2(stones: Stones) {
  let dict_of_stones =
    stones
    |> list.fold(dict.new(), fn(stone_dict, stone) {
      let assert Ok(stone_as_integer) = stone |> int.parse

      stone_dict |> dict.insert(stone_as_integer, 1)
    })

  let stones = blink(dict_of_stones, 75)

  let sum = get_sum_of_stone_values(stones)

  sum
}
