import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder
import utils/iterator

type Calibration =
  #(Int, List(String))

fn get_calibration_operations_combinations(
  calibration_values: List(String),
  part_two: Bool,
) {
  let size_of_calibration = list.length(calibration_values)

  case size_of_calibration {
    1 -> {
      case part_two {
        True -> yielder.from_list([["+"], ["*"], ["||"]])
        False -> yielder.from_list([["+"], ["*"]])
      }
    }
    _ -> {
      let reduce_size_to_between_values = size_of_calibration - 1

      let operations_to_use = case part_two {
        True -> ["+", "*", "||"]
        False -> ["+", "*"]
      }

      iterator.product(operations_to_use, reduce_size_to_between_values)
    }
  }
}

fn get_calculated_expression_on_one_operation(
  expression: List(String),
  operation: List(String),
  final_value: Int,
) {
  let interleave_expression_and_operation =
    list.interleave([expression, operation])

  let interleave_expression_and_operation_as_yielder =
    yielder.from_list(interleave_expression_and_operation)

  let calculated_expression =
    interleave_expression_and_operation
    |> list.index_fold(0, fn(accumulator, value, index) {
      case accumulator > final_value {
        True -> list.Stop(accumulator)
        False -> list.Continue(accumulator)
      }

      case index == 0 {
        True -> {
          let parsed_value = int.parse(value) |> result.unwrap(0)

          parsed_value
        }
        False -> {
          case index % 2 != 0 {
            True -> {
              {
                case value {
                  "+" -> {
                    let value_after_index =
                      interleave_expression_and_operation_as_yielder
                      |> yielder.at(index + 1)
                      |> result.unwrap("0")
                      |> int.parse
                      |> result.unwrap(0)

                    accumulator + value_after_index
                  }
                  "*" -> {
                    let value_after_index =
                      interleave_expression_and_operation_as_yielder
                      |> yielder.at(index + 1)
                      |> result.unwrap("0")
                      |> int.parse
                      |> result.unwrap(0)

                    accumulator * value_after_index
                  }
                  "||" -> {
                    let value_after_index =
                      interleave_expression_and_operation_as_yielder
                      |> yielder.at(index + 1)
                      |> result.unwrap("0")

                    let accumulator_as_string = int.to_string(accumulator)

                    let accumulator_and_value =
                      accumulator_as_string |> string.append(value_after_index)

                    accumulator_and_value |> int.parse |> result.unwrap(0)
                  }
                  _ -> accumulator
                }
              }
            }
            False -> accumulator
          }
        }
      }
    })

  calculated_expression
}

fn get_calculated_expression_on_all_operations(
  expression: List(String),
  all_operations: yielder.Yielder(List(String)),
  final_value: Int,
) {
  let calculated_expressions =
    all_operations
    |> yielder.fold_until(0, fn(_, operation) {
      let calculate_expression =
        get_calculated_expression_on_one_operation(
          expression,
          operation,
          final_value,
        )

      case calculate_expression > final_value {
        True -> list.Stop(0)
        False -> list.Continue(calculate_expression)
      }

      case calculate_expression == final_value {
        True -> list.Stop(calculate_expression)
        False -> list.Continue(0)
      }
    })

  calculated_expressions
}

pub fn parse(input: String) {
  let calibrations =
    input
    |> string.split("\n")

  let parsed_calibrations =
    calibrations
    |> list.fold([], fn(current_parsed_calibrations, calibration) {
      let assert [final_value, values] =
        calibration
        |> string.split(": ")

      let parsed_values =
        values
        |> string.split(" ")

      current_parsed_calibrations
      |> list.append([
        #(int.parse(final_value) |> result.unwrap(0), parsed_values),
      ])
    })

  parsed_calibrations
}

pub fn pt_1(input: List(Calibration)) {
  let total_calibration =
    input
    |> list.fold(0, fn(valid_calibration_accumulator, cal) {
      let #(final_value, values) = cal

      let calibration_operation_combinations =
        get_calibration_operations_combinations(values, False)

      let calculated_expressions =
        get_calculated_expression_on_all_operations(
          values,
          calibration_operation_combinations,
          final_value,
        )

      case calculated_expressions {
        0 -> valid_calibration_accumulator
        _ -> valid_calibration_accumulator + calculated_expressions
      }
    })

  total_calibration
}

pub fn pt_2(input: List(Calibration)) {
  let total_calibration =
    input
    |> list.fold(0, fn(valid_calibration_accumulator, cal) {
      let #(final_value, values) = cal

      let calibration_operation_combinations =
        get_calibration_operations_combinations(values, True)

      let calculated_expressions =
        get_calculated_expression_on_all_operations(
          values,
          calibration_operation_combinations,
          final_value,
        )

      case calculated_expressions {
        0 -> valid_calibration_accumulator
        _ -> valid_calibration_accumulator + calculated_expressions
      }
    })

  total_calibration
}
