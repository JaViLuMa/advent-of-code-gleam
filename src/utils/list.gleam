import gleam/list
import gleam/result

pub fn find_index(l: List(a), value: a) {
  list.index_map(l, fn(v, i) { #(i, v) })
  |> list.find(fn(pair) {
    let #(_, v) = pair

    v == value
  })
  |> result.map(fn(pair) {
    let #(i, _) = pair

    i
  })
}
