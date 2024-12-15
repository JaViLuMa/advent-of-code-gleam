import gleam/int
import gleam/list
import gleam/result
import gleam/string
import utils/list as lu

type Robot =
  #(#(Int, Int), #(Int, Int))

type Robots =
  List(Robot)

type Quadrants =
  #(Int, Int, Int, Int)

type Map =
  List(List(String))

const map_width = 101

const map_height = 103

fn move_robot(map_width: Int, map_height: Int, robot: Robot) {
  let #(robot_position, robot_velocity) = robot
  let #(robot_row, robot_col) = robot_position
  let #(robot_velocity_row, robot_velocity_col) = robot_velocity

  let assert Ok(new_robot_row) =
    int.modulo(robot_row + robot_velocity_row, map_height)
  let assert Ok(new_robot_col) =
    int.modulo(robot_col + robot_velocity_col, map_width)

  let new_robot_position = #(new_robot_row, new_robot_col)

  #(new_robot_position, robot_velocity)
}

fn pass_a_second(map_width: Int, map_height: Int, robots: Robots, seconds) {
  let seconds_range = list.range(1, seconds)

  seconds_range
  |> list.fold(robots, fn(robots_accumulator, _) {
    let new_robots_positions =
      robots_accumulator
      |> list.map(fn(robot) { move_robot(map_width, map_height, robot) })

    new_robots_positions
  })
}

fn create_map(map_width: Int, map_height: Int, robots: Robots) {
  let width_range = list.range(1, map_width)
  let height_range = list.range(1, map_height)

  height_range
  |> list.index_map(fn(_, row_index) {
    width_range
    |> list.index_map(fn(_, col_index) {
      let specific_robot =
        robots
        |> list.find(fn(robot) {
          let #(robot_position, _) = robot
          let #(robot_row, robot_col) = robot_position

          robot_row == row_index && robot_col == col_index
        })

      case specific_robot {
        Ok(_) -> "#"
        Error(_) -> "."
      }
    })
  })
}

fn find_a_lot_of_hashes(map: Map) {
  map
  |> list.find(fn(row) {
    let connected_row = row |> string.join("")

    connected_row |> string.contains("##########")
  })
}

fn find_a_christmas_tree(
  map_width: Int,
  map_height: Int,
  robots: Robots,
  seconds: Int,
) {
  let seconds_range = list.range(1, seconds)

  seconds_range
  |> list.fold_until(#(1, robots), fn(robots_accumulator, second) {
    let #(_, robots) = robots_accumulator

    let new_robots_positions =
      robots
      |> list.map(fn(robot) { move_robot(map_width, map_height, robot) })

    let map = create_map(map_width, map_height, new_robots_positions)

    let has_a_lot_of_hashes = find_a_lot_of_hashes(map)

    case has_a_lot_of_hashes {
      Ok(_) -> {
        lu.matrix_print(map)

        list.Stop(#(second, new_robots_positions))
      }
      Error(_) -> list.Continue(#(second + 1, new_robots_positions))
    }
  })
}

fn place_robots_in_quadrants(map_width: Int, map_height: Int, robots: Robots) {
  let assert Ok(middle_row_index) = int.floor_divide(map_height, 2)
  let assert Ok(middle_col_index) = int.floor_divide(map_width, 2)

  robots
  |> list.fold(#(0, 0, 0, 0), fn(quadrants_accumulator, robot) {
    let #(top_left, top_right, bottom_left, bottom_right) =
      quadrants_accumulator

    let #(robot_position, _) = robot

    let #(robot_row, robot_col) = robot_position

    let top_left = case
      robot_row < middle_row_index && robot_col < middle_col_index
    {
      True -> top_left + 1
      False -> top_left
    }

    let top_right = case
      robot_row < middle_row_index && robot_col > middle_col_index
    {
      True -> top_right + 1
      False -> top_right
    }

    let bottom_left = case
      robot_row > middle_row_index && robot_col < middle_col_index
    {
      True -> bottom_left + 1
      False -> bottom_left
    }

    let bottom_right = case
      robot_row > middle_row_index && robot_col > middle_col_index
    {
      True -> bottom_right + 1
      False -> bottom_right
    }

    #(top_left, top_right, bottom_left, bottom_right)
  })
}

fn multiply_quadrants(quadrants: Quadrants) {
  let #(top_left, top_right, bottom_left, bottom_right) = quadrants

  top_left * top_right * bottom_left * bottom_right
}

pub fn parse(input: String) {
  let robot_lines = input |> string.split("\n")

  robot_lines
  |> list.map(fn(robot_line) {
    let assert [robot_position, robot_velocity] =
      robot_line |> string.split(" ")

    let assert [robots_position_col, robots_position_row] =
      robot_position
      |> string.drop_start(2)
      |> string.split(",")
      |> list.map(fn(position) { int.parse(position) |> result.unwrap(0) })

    let assert [robots_velocity_col, robots_velocity_row] =
      robot_velocity
      |> string.drop_start(2)
      |> string.split(",")
      |> list.map(fn(position) { int.parse(position) |> result.unwrap(0) })

    let robot_position = #(robots_position_row, robots_position_col)
    let robot_velocity = #(robots_velocity_row, robots_velocity_col)

    #(robot_position, robot_velocity)
  })
}

pub fn pt_1(robots: Robots) {
  let final_robot_positions = pass_a_second(map_width, map_height, robots, 100)

  let robots_in_quadrants =
    place_robots_in_quadrants(map_width, map_height, final_robot_positions)

  let safety_factor = multiply_quadrants(robots_in_quadrants)

  safety_factor
}

pub fn pt_2(robots: Robots) {
  let #(second_a_christmas_tree_appears, _) =
    find_a_christmas_tree(map_width, map_height, robots, 10_000)

  second_a_christmas_tree_appears
}
