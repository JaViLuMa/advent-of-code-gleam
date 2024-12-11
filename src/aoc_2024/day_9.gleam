import gleam/int
import gleam/list
import gleam/string
import gleam/yielder
import utils/list as lu

type DiskMap =
  List(String)

type Blocks =
  List(List(Int))

fn calculate_sum_of_last_element_and_value(accumulator: List(Int), value: Int) {
  let assert Ok(last_value_in_accumulator) = accumulator |> list.last

  last_value_in_accumulator + value
}

pub fn build_blocks(disk_map: DiskMap) {
  let positions =
    disk_map
    |> list.fold([0], fn(accumulator, value) {
      let assert Ok(value_as_int) = value |> int.parse

      let accumulated_sum =
        calculate_sum_of_last_element_and_value(accumulator, value_as_int)

      accumulator |> list.append([accumulated_sum])
    })

  let range_from_zero = lu.range_with_step(0, disk_map |> list.length, 2)

  let blocks =
    range_from_zero
    |> list.fold([], fn(accumulator, index) {
      let assert Ok(value) = lu.at(positions, index)
      let assert Ok(value_at_next_index) = lu.at(positions, index + 1)

      let create_range = list.range(value, value_at_next_index)

      let range_without_last_element = lu.pop(create_range)

      accumulator |> list.append([range_without_last_element])
    })

  let range_from_one = lu.range_with_step_yielder(1, disk_map |> list.length, 2)

  let empty_blocks =
    range_from_one
    |> yielder.fold([], fn(accumulator, index) {
      let assert Ok(value) = lu.at(positions, index)
      let assert Ok(value_at_next_index) = lu.at(positions, index + 1)

      let create_range = list.range(value, value_at_next_index)

      let range_without_last_element = lu.pop(create_range)

      accumulator |> list.append([range_without_last_element])
    })

  #(blocks, empty_blocks)
}

fn replace_with_smaller_segments(
  blocks_segment: List(Int),
  flatten_empty_blocks: List(Int),
) {
  let reversed_blocks_segment = list.reverse(blocks_segment)

  reversed_blocks_segment
  |> list.fold(#([], flatten_empty_blocks), fn(accumulator, value) {
    let #(replaced_elements, leftovers) = accumulator

    let assert Ok(first_leftover_element) = leftovers |> list.first

    case leftovers |> list.length > 0 && value > first_leftover_element {
      True -> {
        let drop_first_leftover_element = leftovers |> list.drop(1)

        #(
          replaced_elements |> list.prepend(first_leftover_element),
          drop_first_leftover_element,
        )
      }
      False -> {
        #(replaced_elements |> list.prepend(value), leftovers)
      }
    }
  })
}

fn replace_with_smaller(blocks: Blocks, flattened_empty_blocks: List(Int)) {
  let reversed_blocks = list.reverse(blocks)

  reversed_blocks
  |> list.fold(#([[]], flattened_empty_blocks), fn(accumulator, front_segment) {
    let #(replaced_fronts, leftovers) = accumulator

    let #(new_fronts, new_leftovers) =
      replace_with_smaller_segments(front_segment, leftovers)

    #(replaced_fronts |> list.prepend(new_fronts), new_leftovers)
  })
}

fn calculate_sum(blocks: List(List(Int))) {
  blocks
  |> list.index_fold(0, fn(final_accumulator, block, index) {
    let block_sum =
      block
      |> list.fold(0, fn(accumulator, value) { accumulator + { value * index } })

    final_accumulator + block_sum
  })
}

fn process_empty_blocks_for_blocks(
  blocks_segment: List(Int),
  empty_blocks: Blocks,
) {
  empty_blocks
  |> list.fold(
    #(blocks_segment, [], False),
    fn(accumulator, empty_block_segment) {
      let #(matched_blocks, empty_blocks_so_far, block_found) = accumulator

      case block_found {
        True -> #(
          matched_blocks,
          empty_blocks_so_far |> list.append([empty_block_segment]),
          block_found,
        )
        False -> {
          let blocks_segment_length = blocks_segment |> list.length
          let empty_block_segment_length = empty_block_segment |> list.length

          let assert Ok(first_block_segment_element) =
            blocks_segment |> list.first
          let first_empty_block_segment_element = case
            empty_block_segment |> list.first
          {
            Ok(value) -> value
            Error(_) -> -1
          }

          case
            empty_block_segment_length >= blocks_segment_length
            && first_empty_block_segment_element != -1
            && first_block_segment_element > first_empty_block_segment_element
          {
            True -> {
              let matched_block_segment =
                empty_block_segment |> list.take(blocks_segment_length)
              let new_empty_block_segment =
                empty_block_segment |> list.drop(blocks_segment_length)

              case new_empty_block_segment |> list.length > 0 {
                True -> #(
                  matched_block_segment,
                  empty_blocks_so_far |> list.append([new_empty_block_segment]),
                  True,
                )
                False -> #(matched_block_segment, empty_blocks_so_far, True)
              }
            }
            False -> #(
              matched_blocks,
              empty_blocks_so_far |> list.append([empty_block_segment]),
              block_found,
            )
          }
        }
      }
    },
  )
}

fn adjust_blocks(blocks: Blocks, empty_blocks: Blocks) {
  let reversed_blocks = list.reverse(blocks)

  let #(adjusted_blocks, adjusted_empty_blocks) =
    reversed_blocks
    |> list.fold(#([[]], empty_blocks), fn(accumulator, blocks_segment) {
      let #(accumulator_blocks, accumulator_empty_blocks) = accumulator

      let #(new_blocks, new_empty_blocks, _) =
        process_empty_blocks_for_blocks(
          blocks_segment,
          accumulator_empty_blocks,
        )

      #(accumulator_blocks |> list.append([new_blocks]), new_empty_blocks)
    })

  #(adjusted_blocks |> list.reverse, adjusted_empty_blocks)
}

pub fn parse(input: String) {
  input |> string.to_graphemes
}

pub fn pt_1(disk_map: DiskMap) {
  let #(blocks, empty_blocks) = build_blocks(disk_map)

  let flatten_empty_blocks = empty_blocks |> list.flatten

  let #(new_blocks, _) = replace_with_smaller(blocks, flatten_empty_blocks)

  let sum = calculate_sum(new_blocks)

  sum
}

pub fn pt_2(disk_map: DiskMap) {
  let #(blocks, empty_blocks) = build_blocks(disk_map)

  let #(adjusted_blocks, _) = adjust_blocks(blocks, empty_blocks)

  let sum = calculate_sum(adjusted_blocks)

  sum
}
