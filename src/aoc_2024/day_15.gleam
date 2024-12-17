import gleam/dict
import gleam/list
import gleam/option
import gleam/string
import utils/list as lu

type Position =
  #(Int, Int)

type WarehouseMapAsMatrix =
  List(List(String))

type WarehouseMap =
  dict.Dict(Position, String)

type Directions =
  List(String)

type Parsed =
  #(WarehouseMapAsMatrix, Directions)

fn get_warehouse_dict_and_robot_position(warehouse_map: WarehouseMapAsMatrix) {
  let enumerated_warehouse_map = lu.enumerate_matrix(warehouse_map)

  let assert Ok(#(robot_row, robot_col, _)) =
    enumerated_warehouse_map
    |> list.find(fn(cell) {
      let #(_, _, char) = cell

      char == "@"
    })

  let robot_position = #(robot_row, robot_col)

  let warehouse_dict =
    enumerated_warehouse_map
    |> list.fold(dict.new(), fn(accumulator, cell) {
      let #(row, col, char) = cell

      case char {
        "@" -> accumulator |> dict.insert(#(row, col), ".")
        _ -> accumulator |> dict.insert(#(row, col), char)
      }
    })

  #(warehouse_dict, robot_position)
}

fn try_to_move(
  warehouse_dict: WarehouseMap,
  robot_position: Position,
  direction_deltas: Position,
) {
  let #(robot_row, robot_col) = robot_position
  let #(row_delta, col_delta) = direction_deltas

  let next_position = #(robot_row + row_delta, robot_col + col_delta)

  let next_cell = case dict.get(warehouse_dict, next_position) {
    Ok(cell) -> cell
    Error(_) -> "#"
  }

  case next_cell {
    "." -> {
      let assert Ok(char_at_robot_position) =
        dict.get(warehouse_dict, robot_position)

      #(True, [#(next_position, char_at_robot_position)])
    }
    "O" -> {
      let #(success, further_positions) =
        try_to_move(warehouse_dict, next_position, direction_deltas)

      case success {
        True -> {
          let assert Ok(char_at_robot_position) =
            dict.get(warehouse_dict, robot_position)

          #(
            True,
            [#(next_position, char_at_robot_position)]
              |> list.append(further_positions),
          )
        }
        False -> #(False, [])
      }
    }
    _ -> #(False, [])
  }
}

fn move_robot(
  warehouse_dict: WarehouseMap,
  directions: Directions,
  robot_position: Position,
) {
  let directions_dict =
    dict.from_list([
      #(">", #(0, 1)),
      #("<", #(0, -1)),
      #("v", #(1, 0)),
      #("^", #(-1, 0)),
    ])

  directions
  |> list.fold(#(warehouse_dict, robot_position), fn(accumulator, direction) {
    let #(old_warehouse_dict, old_robot_position) = accumulator

    let assert Ok(direction_deltas) = dict.get(directions_dict, direction)

    let #(success, new_positions) =
      try_to_move(old_warehouse_dict, old_robot_position, direction_deltas)

    case success {
      True -> {
        let new_warehouse_moved_robot_dict =
          old_warehouse_dict
          |> dict.upsert(old_robot_position, fn(value) {
            case value {
              option.Some(_) -> "."
              option.None -> "."
            }
          })

        let new_warehouse_with_new_positions_dict =
          new_positions
          |> list.fold(
            new_warehouse_moved_robot_dict,
            fn(accumulator, position) {
              let #(row_and_col, char) = position

              accumulator
              |> dict.upsert(row_and_col, fn(value) {
                case value {
                  option.Some(_) -> char
                  option.None -> char
                }
              })
            },
          )

        let #(robot_row, robot_col) = old_robot_position
        let #(direction_row_delta, direction_col_delta) = direction_deltas

        let new_robot_position = #(
          robot_row + direction_row_delta,
          robot_col + direction_col_delta,
        )

        let new_warehouse_dict =
          new_warehouse_with_new_positions_dict
          |> dict.upsert(new_robot_position, fn(value) {
            case value {
              option.Some(_) -> "@"
              option.None -> "@"
            }
          })

        #(new_warehouse_dict, new_robot_position)
      }
      False -> #(old_warehouse_dict, old_robot_position)
    }
  })
}

fn sum_of_o(warehouse_dict: WarehouseMap) {
  warehouse_dict
  |> dict.fold(0, fn(accumulator, key, value) {
    let #(row, col) = key

    case value {
      "O" -> accumulator + { row * 100 } + col
      _ -> accumulator
    }
  })
}

fn sum_of_o_double(warehouse_dict: WarehouseMap) {
  warehouse_dict
  |> dict.fold(0, fn(accumulator, key, value) {
    let #(row, col) = key

    case value {
      "[" -> accumulator + { row * 100 } + col
      _ -> accumulator
    }
  })
}

fn try_to_move_double(
  warehouse_dict: WarehouseMap,
  robot_position: Position,
  direction_deltas: Position,
  movers: WarehouseMap,
  to_check: List(Position),
  move: String,
  can_move: Bool,
) {
  let assert Ok(#(actual_row, actual_column)) = list.last(to_check)
  let popped_to_check = lu.pop(to_check)

  case popped_to_check |> list.length > 0 {
    True -> {
      let #(direction_row_delta, direction_col_delta) = direction_deltas

      let final_position = #(
        actual_row + direction_row_delta,
        actual_column + direction_col_delta,
      )

      case ["<", ">"] |> list.contains(move) {
        True -> {
          let assert Ok(char_at_final_position) =
            dict.get(warehouse_dict, final_position)

          case ["[", "]"] |> list.contains(char_at_final_position) {
            True -> {
              let #(final_position_row, final_position_column) = final_position

              let final_position_with_delta_column = #(
                final_position_row,
                final_position_column + direction_col_delta,
              )

              let assert Ok(char_at_final_position_with_delta_column) =
                dict.get(warehouse_dict, final_position_with_delta_column)

              let new_movers =
                movers
                |> dict.insert(final_position, char_at_final_position)
                |> dict.insert(
                  final_position_with_delta_column,
                  char_at_final_position_with_delta_column,
                )

              let new_to_check =
                to_check |> list.append([final_position_with_delta_column])

              try_to_move_double(
                warehouse_dict,
                robot_position,
                direction_deltas,
                new_movers,
                new_to_check,
                move,
                can_move,
              )
            }
            False -> {
              case char_at_final_position == "#" {
                True -> #(False, movers)
                False ->
                  try_to_move_double(
                    warehouse_dict,
                    robot_position,
                    direction_deltas,
                    movers,
                    to_check,
                    move,
                    can_move,
                  )
              }
            }
          }
        }
        False -> {
          case ["^", "v"] |> list.contains(move) {
            True -> {
              let assert Ok(char_at_final_position) =
                dict.get(warehouse_dict, final_position)

              case char_at_final_position {
                "[" -> {
                  let #(final_position_row, final_position_column) =
                    final_position

                  let final_position_with_next_column = #(
                    final_position_row,
                    final_position_column + 1,
                  )

                  let assert Ok(char_at_final_position_with_next_column) =
                    dict.get(warehouse_dict, final_position_with_next_column)

                  let new_movers =
                    movers
                    |> dict.insert(final_position, char_at_final_position)
                    |> dict.insert(
                      final_position_with_next_column,
                      char_at_final_position_with_next_column,
                    )

                  let new_to_check =
                    to_check
                    |> list.append([
                      final_position,
                      final_position_with_next_column,
                    ])

                  try_to_move_double(
                    warehouse_dict,
                    robot_position,
                    direction_deltas,
                    new_movers,
                    new_to_check,
                    move,
                    can_move,
                  )
                }
                "]" -> {
                  let #(final_position_row, final_position_column) =
                    final_position

                  let final_position_with_prev_column = #(
                    final_position_row,
                    final_position_column - 1,
                  )

                  let assert Ok(char_at_final_position_with_next_column) =
                    dict.get(warehouse_dict, final_position_with_prev_column)

                  let new_movers =
                    movers
                    |> dict.insert(final_position, char_at_final_position)
                    |> dict.insert(
                      final_position_with_prev_column,
                      char_at_final_position_with_next_column,
                    )

                  let new_to_check =
                    to_check
                    |> list.append([
                      final_position,
                      final_position_with_prev_column,
                    ])

                  try_to_move_double(
                    warehouse_dict,
                    robot_position,
                    direction_deltas,
                    new_movers,
                    new_to_check,
                    move,
                    can_move,
                  )
                }
                "#" -> #(False, movers)
                _ ->
                  try_to_move_double(
                    warehouse_dict,
                    robot_position,
                    direction_deltas,
                    movers,
                    to_check,
                    move,
                    can_move,
                  )
              }
            }
            False ->
              try_to_move_double(
                warehouse_dict,
                robot_position,
                direction_deltas,
                movers,
                to_check,
                move,
                can_move,
              )
          }
        }
      }
    }
    False -> #(can_move, movers)
  }
}

fn move_robot_double(
  warehouse_dict: WarehouseMap,
  directions: Directions,
  robot_position: Position,
) {
  let directions_dict =
    dict.from_list([
      #(">", #(0, 1)),
      #("<", #(0, -1)),
      #("v", #(1, 0)),
      #("^", #(-1, 0)),
    ])

  directions
  |> list.fold(#(warehouse_dict, robot_position), fn(accumulator, direction) {
    let #(old_warehouse_dict, old_robot_position) = accumulator

    let assert Ok(direction_deltas) = dict.get(directions_dict, direction)

    let #(can_move, movers) =
      try_to_move_double(
        old_warehouse_dict,
        old_robot_position,
        direction_deltas,
        dict.new(),
        [old_robot_position],
        direction,
        True,
      )

    case can_move {
      True -> {
        let #(direction_row_delta, direction_col_delta) = direction_deltas

        let new_warehouse_dict =
          movers
          |> dict.fold(old_warehouse_dict, fn(accumulator, key, _) {
            accumulator
            |> dict.upsert(key, fn(value) {
              case value {
                option.Some(_) -> "."
                option.None -> "."
              }
            })
          })

        let new_warehouse_dict =
          movers
          |> dict.fold(new_warehouse_dict, fn(accumulator, key, char) {
            let #(mover_row, mover_col) = key

            let new_position = #(
              mover_row + direction_row_delta,
              mover_col + direction_col_delta,
            )

            accumulator
            |> dict.upsert(new_position, fn(value) {
              case value {
                option.Some(_) -> char
                option.None -> char
              }
            })
          })

        let #(robot_row, robot_col) = old_robot_position

        let new_robot_position = #(
          robot_row + direction_row_delta,
          robot_col + direction_col_delta,
        )

        let new_warehouse_dict =
          new_warehouse_dict
          |> dict.upsert(new_robot_position, fn(value) {
            case value {
              option.Some(_) -> "@"
              option.None -> "@"
            }
          })

        #(new_warehouse_dict, new_robot_position)
      }
      False -> #(old_warehouse_dict, old_robot_position)
    }
  })
}

fn double_up_warehouse(warehouse_map: WarehouseMapAsMatrix) {
  warehouse_map
  |> list.map(fn(row) {
    let new_row =
      row
      |> list.fold([], fn(accumulated_row, cell) {
        case cell {
          "#" -> accumulated_row |> list.append(["#", "#"])
          "O" -> accumulated_row |> list.append(["[", "]"])
          "." -> accumulated_row |> list.append([".", "."])
          "@" -> accumulated_row |> list.append(["@", "."])
          _ -> accumulated_row |> list.append([cell])
        }
      })

    new_row
  })
}

pub fn parse(input: String) {
  let assert [map_as_string, directions_as_string] =
    input |> string.split("\n\n")

  let warehouse_map = lu.parse_matrix(map_as_string)

  let directions =
    directions_as_string
    |> string.split("\n")
    |> list.map(string.to_graphemes)
    |> list.flatten

  #(warehouse_map, directions)
}

pub fn pt_1(warehouse_with_directions: Parsed) {
  let #(warehouse_map, directions) = warehouse_with_directions

  let #(warehouse_dict, robot_position) =
    get_warehouse_dict_and_robot_position(warehouse_map)

  let #(new_warehouse_dict, _) =
    move_robot(warehouse_dict, directions, robot_position)

  let sum = sum_of_o(new_warehouse_dict)

  sum
}

pub fn pt_2(warehouse_with_directions: Parsed) {
  let #(warehouse_map, directions) = warehouse_with_directions

  let doubled_up_warehouse_map = double_up_warehouse(warehouse_map)

  let #(warehouse_dict, robot_position) =
    get_warehouse_dict_and_robot_position(doubled_up_warehouse_map)

  let #(new_warehouse_dict, _) =
    move_robot_double(warehouse_dict, directions, robot_position)

  let sum = sum_of_o_double(new_warehouse_dict)

  sum
}
