import gleam/int
import gleam/list
import gleam/regexp
import gleam/string

const mul_pattern = "mul\\([0-9]+,[0-9]+\\)"

const do_and_dont_pattern = "don't\\(\\)(.*?)(?=do\\(\\)|$)"

fn get_mul_instructions(input: String) {
  let assert Ok(mul_regex) = regexp.from_string(mul_pattern)

  let mul_matches = regexp.scan(mul_regex, input)

  mul_matches
}

fn calculate_mul(mul_instruction: regexp.Match) {
  let mul_instruction_content =
    mul_instruction.content
    |> string.drop_start(4)
    |> string.drop_end(1)

  let assert Ok(#(left, right)) =
    mul_instruction_content
    |> string.split_once(",")

  let assert Ok(left_as_int) = int.parse(left)
  let assert Ok(right_as_int) = int.parse(right)

  left_as_int * right_as_int
}

fn remove_invalid_muls_and_get_mul_instructions(input: String) {
  let assert Ok(do_and_dont_regex) = regexp.from_string(do_and_dont_pattern)

  let valid_memory = regexp.replace(do_and_dont_regex, input, "#")

  get_mul_instructions(valid_memory)
}

pub fn parse(input: String) {
  let input_without_newlines = string.replace(input, "\n", "")

  input_without_newlines
}

pub fn pt_1(input: String) {
  let mul_instructions = get_mul_instructions(input)

  let mul_sum =
    mul_instructions
    |> list.fold(0, fn(accumulator, mul_instruction) {
      let calculated_mul = calculate_mul(mul_instruction)

      accumulator + calculated_mul
    })

  mul_sum
}

pub fn pt_2(input: String) {
  let mul_instructions = remove_invalid_muls_and_get_mul_instructions(input)

  let mul_sum =
    mul_instructions
    |> list.fold(0, fn(accumulator, mul_instruction) {
      let calculated_mul = calculate_mul(mul_instruction)

      accumulator + calculated_mul
    })

  mul_sum
}
