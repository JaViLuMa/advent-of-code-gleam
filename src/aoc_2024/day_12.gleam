import gleam/dict
import gleam/list
import gleam/set
import utils/list as lu

type Garden =
  List(List(String))

type GardenDict =
  dict.Dict(#(Int, Int), String)

type Coords =
  #(Int, Int)

type FilledCoords =
  set.Set(Coords)

type Region =
  List(Coords)

const directions = [#(0, -1), #(0, 1), #(-1, 0), #(1, 0)]

fn construct_garden_dict(garden_map: Garden) {
  garden_map
  |> list.index_fold(dict.new(), fn(row_accumulator, row, row_index) {
    let col_dict =
      row
      |> list.index_fold(dict.new(), fn(col_accumulator, char, col_index) {
        col_accumulator
        |> dict.insert(#(row_index, col_index), char)
      })

    row_accumulator |> dict.merge(col_dict)
  })
}

fn dfs_flood(
  garden_dict: GardenDict,
  coords: Coords,
  plant: String,
  filled_coords: FilledCoords,
  region: set.Set(Coords),
) {
  let plant_at_coords = case garden_dict |> dict.get(coords) {
    Ok(plant) -> plant
    Error(_) -> ""
  }
  case filled_coords |> set.contains(coords) || plant_at_coords != plant {
    True -> #(filled_coords, region)
    False -> {
      let #(row, col) = coords

      let new_filled_coords = filled_coords |> set.insert(coords)
      let new_region = region |> set.insert(coords)

      directions
      |> list.fold(#(new_filled_coords, new_region), fn(accumulator, direction) {
        let #(row_dir, col_dir) = direction

        let neighbor_coords = #(row + row_dir, col + col_dir)

        dfs_flood(
          garden_dict,
          neighbor_coords,
          plant,
          accumulator.0,
          accumulator.1,
        )
      })
    }
  }
}

fn go_through_garden(garden_dict: GardenDict) {
  garden_dict
  |> dict.fold(#(set.new(), []), fn(accumulator, coords, plant) {
    let #(filled_coords, regions) = accumulator

    case filled_coords |> set.contains(coords) {
      True -> accumulator
      False -> {
        let #(new_filled_coords, region) =
          dfs_flood(garden_dict, coords, plant, filled_coords, set.new())

        #(new_filled_coords, regions |> list.append([region]))
      }
    }
  })
}

fn calculate_garden_perimeter(region: Region) {
  directions
  |> list.fold(0, fn(final_perimeter, direction) {
    let #(row_dir, col_dir) = direction

    let region_perimeter =
      region
      |> list.fold(0, fn(perimeter, coords) {
        let #(row, col) = coords

        let neighbor_coords = #(row + row_dir, col + col_dir)

        case region |> list.contains(neighbor_coords) {
          True -> perimeter
          False -> perimeter + 1
        }
      })

    final_perimeter + region_perimeter
  })
}

fn scan_line(
  region: Region,
  plot: Coords,
  direction: Coords,
  scan_delta: Int,
  analyzed_coords: FilledCoords,
) {
  let #(row, col) = plot
  let #(row_dir, col_dir) = direction
  let neighbor_coords = #(row + row_dir, col + col_dir)

  let region_set = region |> set.from_list

  let region_set_has_neighbor = region_set |> set.contains(neighbor_coords)

  case region_set |> set.contains(plot) && region_set_has_neighbor == False {
    True -> {
      let new_analyzed_coords =
        analyzed_coords |> set.union(set.from_list([plot]))

      let next_plot = #(
        row + { col_dir * scan_delta },
        col + { row_dir * scan_delta },
      )

      scan_line(region, next_plot, direction, scan_delta, new_analyzed_coords)
    }
    False -> analyzed_coords
  }
}

fn analyze_plot(
  region: Region,
  plot: Coords,
  direction: Coords,
  analyzed_coords: FilledCoords,
) {
  case analyzed_coords |> set.contains(plot) {
    True -> #(0, analyzed_coords)
    False -> {
      let #(row, col) = plot
      let #(row_dir, col_dir) = direction

      let neighbor_coords = #(row + row_dir, col + col_dir)

      let region_set = region |> set.from_list

      case region_set |> set.contains(neighbor_coords) {
        True -> #(0, analyzed_coords)
        False -> {
          let base_count = 1

          let deltas = [-1, 1]

          let final_analyzed_coords =
            deltas
            |> list.fold(analyzed_coords, fn(analyzed_accumulator, delta) {
              let new_analyzed_coords =
                scan_line(region, plot, direction, delta, analyzed_accumulator)

              new_analyzed_coords
            })

          #(base_count, final_analyzed_coords)
        }
      }
    }
  }
}

fn analyze_plots(
  region: Region,
  index: Int,
  direction: Coords,
  analyzed_coords: FilledCoords,
) {
  case index == region |> list.length {
    True -> #(0, analyzed_coords)
    False -> {
      let assert Ok(plot) = lu.at(region, index)

      let #(count_increment, new_analyzed_coords) =
        analyze_plot(region, plot, direction, analyzed_coords)

      let #(rest_count, final_analyzed_coords) =
        analyze_plots(region, index + 1, direction, new_analyzed_coords)

      #(count_increment + rest_count, final_analyzed_coords)
    }
  }
}

fn calculate_garden_sides(region: Region, directions: List(Coords)) {
  case directions |> list.length == 0 {
    True -> 0
    False -> {
      let assert [direction, ..rest_of_directions] = directions

      let #(side_count_offset, _) =
        analyze_plots(region, 0, direction, set.new())

      side_count_offset + calculate_garden_sides(region, rest_of_directions)
    }
  }
}

pub fn parse(input: String) {
  input |> lu.parse_matrix
}

pub fn pt_1(garden_map: Garden) {
  let garden_dict = construct_garden_dict(garden_map)

  let #(_, garden_regions) = go_through_garden(garden_dict)

  let price_of_fencing =
    garden_regions
    |> list.fold(0, fn(total_price, region) {
      let area = region |> set.size

      let perimeter = calculate_garden_perimeter(region |> set.to_list)

      total_price + { area * perimeter }
    })

  price_of_fencing
}

pub fn pt_2(garden_map: Garden) {
  let garden_dict = construct_garden_dict(garden_map)

  let #(_, garden_regions) = go_through_garden(garden_dict)

  let price_of_fencing =
    garden_regions
    |> list.fold(0, fn(total_price, region) {
      let area = region |> set.size

      let sides = calculate_garden_sides(region |> set.to_list, directions)

      total_price + { area * sides }
    })

  price_of_fencing
}
