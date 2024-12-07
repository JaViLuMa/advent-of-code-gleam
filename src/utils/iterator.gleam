import gleam/list
import gleam/yielder

fn create_pools(iterable: List(a), repeat: Int) {
  let pools =
    iterable
    |> list.repeat(repeat)

  pools
}

pub fn product(iterable: List(a), repeat: Int) {
  case repeat < 0 {
    True -> {
      panic as "Repeat must be larger than 0!"
    }
    False -> {
      let pools = create_pools(iterable, repeat)

      let results =
        pools
        |> list.fold([[]], fn(pool_accumulator, pool) {
          pool_accumulator
          |> list.flat_map(fn(result) {
            pool
            |> list.map(fn(pool_element) {
              list.flatten([result, [pool_element]])
            })
          })
        })

      yielder.from_list(results)
    }
  }
}
