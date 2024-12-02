import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type Reports =
  List(List(Int))

fn parse_report(line: String) -> List(Int) {
  let numbers =
    string.split(line, on: " ")
    |> list.map(fn(number) {
      int.parse(number)
      |> result.unwrap(0)
    })

  numbers
}

fn parse_reports(lines: List(String)) -> Reports {
  let reports =
    lines
    |> list.map(fn(line) {
      let numbers = parse_report(line)

      numbers
    })

  reports
}

fn bool_to_int(condition: Bool) {
  case condition {
    True -> 1
    False -> 0
  }
}

fn sorted_report_check(report: List(Int)) {
  let sorted_report = list.sort(report, int.compare)
  let reversed_sorted_report =
    list.sort(report, int.compare)
    |> list.reverse()

  bool_to_int(sorted_report == report || reversed_sorted_report == report)
}

fn difference_check(differences: List(Int), report: List(Int)) {
  let difference_lower_than_one_larger_than_three =
    differences
    |> list.count(fn(number) {
      int.absolute_value(number) < 1 || int.absolute_value(number) > 3
    })

  case difference_lower_than_one_larger_than_three {
    0 -> sorted_report_check(report)
    _ -> 0
  }
}

fn process_report(report: List(Int)) {
  let differences =
    report
    |> list.window_by_2
    |> list.map(fn(window) {
      let #(left, right) = window

      left - right
    })

  difference_check(differences, report)
}

fn create_report_without_level(report: List(Int), level: Int) -> List(Int) {
  report
  |> list.index_fold([], fn(report_accumulator, number, index) {
    case index == level {
      True -> report_accumulator
      False -> {
        report_accumulator
        |> list.append([number])
      }
    }
  })
}

fn process_report_without_specific_level(report: List(Int)) {
  let level_range = list.range(0, list.length(report) - 1)

  let safe_or_not =
    level_range
    |> list.any(fn(level) {
      let report_without_level_as_index =
        create_report_without_level(report, level)

      let processed_report = process_report(report_without_level_as_index)

      processed_report == 1
    })

  bool_to_int(safe_or_not)
}

pub fn parse(input: String) -> Reports {
  let lines = string.split(input, on: "\n")

  let reports = parse_reports(lines)

  reports
}

pub fn pt_1(reports: Reports) {
  let sum =
    reports
    |> list.fold(0, fn(accumulator, report) {
      let safe_or_not = process_report(report)

      accumulator + safe_or_not
    })

  sum
}

pub fn pt_2(reports: Reports) {
  let sum =
    reports
    |> list.fold(0, fn(accumulator, report) {
      let safe_or_not = process_report_without_specific_level(report)

      accumulator + safe_or_not
    })

  sum
}
