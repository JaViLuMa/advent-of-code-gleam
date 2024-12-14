import gleam/float
import gleam/int
import gleam/list
import gleam/regexp
import gleam/result
import gleam/string

type ClawMachines =
  List(#(Int, Int, Int, Int, Int, Int))

const button_a_pattern = "Button A: X\\+([0-9]+), Y\\+([0-9]+)"

const button_b_pattern = "Button B: X\\+([0-9]+), Y\\+([0-9]+)"

const prize_pattern = "Prize: X=([0-9]+), Y=([0-9]+)"

const value_to_add = 10_000_000_000_000

fn get_button_values(button_string: String, button_pattern: String) {
  let assert Ok(button_regex) = regexp.from_string(button_pattern)

  regexp.split(button_regex, button_string)
  |> list.drop(1)
  |> list.take(2)
  |> list.map(fn(value) { value |> int.parse |> result.unwrap(0) })
}

fn get_prize_values(prize_string: String) {
  let assert Ok(prize_regex) = regexp.from_string(prize_pattern)

  regexp.split(prize_regex, prize_string)
  |> list.drop(1)
  |> list.take(2)
  |> list.map(fn(value) { value |> int.parse |> result.unwrap(0) })
}

fn calculate_determinant(a_one: Int, b_two: Int, a_two: Int, b_one: Int) {
  let a_one_as_float = a_one |> int.to_float
  let b_two_as_float = b_two |> int.to_float
  let a_two_as_float = a_two |> int.to_float
  let b_one_as_float = b_one |> int.to_float

  { a_one_as_float *. b_two_as_float } -. { a_two_as_float *. b_one_as_float }
}

pub fn parse(input: String) {
  let claw_machines =
    input
    |> string.split("\n\n")
    |> list.map(fn(claw_machine) {
      let assert [first_button, second_button, prize] =
        claw_machine |> string.split("\n")

      let assert [a_one, b_one] =
        get_button_values(first_button, button_a_pattern)
      let assert [a_two, b_two] =
        get_button_values(second_button, button_b_pattern)
      let assert [result_one, result_two] = get_prize_values(prize)

      #(a_one, a_two, b_one, b_two, result_one, result_two)
    })

  claw_machines
}

pub fn pt_1(claw_machines: ClawMachines) {
  let presses =
    claw_machines
    |> list.fold(0, fn(accumulator, claw_machine) {
      let #(a_one, a_two, b_one, b_two, result_one, result_two) = claw_machine

      let determinant = calculate_determinant(a_one, b_two, a_two, b_one)

      let determinant_x =
        calculate_determinant(result_one, b_two, a_two, result_two)
      let determinant_y =
        calculate_determinant(a_one, result_two, result_one, b_one)

      let x = {
        determinant_x /. determinant
      }
      let x_floored = x |> float.floor

      let y = {
        determinant_y /. determinant
      }
      let y_floored = y |> float.floor

      case x == x_floored && y == y_floored {
        True -> {
          let x_as_int = x |> float.truncate
          let y_as_int = y |> float.truncate

          case x_as_int <= 100 && y_as_int <= 100 {
            True -> accumulator + { x_as_int * 3 } + y_as_int
            False -> accumulator
          }
        }
        False -> accumulator
      }
    })

  presses
}

pub fn pt_2(claw_machines: ClawMachines) {
  let presses =
    claw_machines
    |> list.fold(0, fn(accumulator, claw_machine) {
      let #(a_one, a_two, b_one, b_two, result_one, result_two) = claw_machine

      let result_one_with_value = result_one + value_to_add
      let result_two_with_value = result_two + value_to_add

      let determinant = calculate_determinant(a_one, b_two, a_two, b_one)

      let determinant_x =
        calculate_determinant(
          result_one_with_value,
          b_two,
          a_two,
          result_two_with_value,
        )
      let determinant_y =
        calculate_determinant(
          a_one,
          result_two_with_value,
          result_one_with_value,
          b_one,
        )

      let x = {
        determinant_x /. determinant
      }
      let x_floored = x |> float.floor

      let y = {
        determinant_y /. determinant
      }
      let y_floored = y |> float.floor

      case x == x_floored && y == y_floored {
        True -> {
          let x_as_int = x |> float.truncate
          let y_as_int = y |> float.truncate

          accumulator + { x_as_int * 3 } + y_as_int
        }
        False -> accumulator
      }
    })

  presses
}
