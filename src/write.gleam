import gleam/string
import gleam/list
import gleam/bit_array as b
import gleam/crypto as c
import gleam/result
import simplifile.{type FileError} as s

const cache_dir = ".cache"
pub fn mergefunc(xs: List(String)) -> List(String) {
  merge_chunks(xs, [])
  |> list.reverse
}

fn merge_chunks(xs: List(String), acc: List(String)) -> List(String) {
  case xs {
    // take 3 at a time
    [a, b, c, d, ..rest] ->
      merge_chunks(rest, [a <> b <> c <> d, ..acc])

    // 1 or 2 left, just append them as-is
    [a, ..rest] ->
      merge_chunks(rest, [a, ..acc])

    [] ->
      acc
  }
}
pub fn cf(name: String, content: String) -> Result(Nil, FileError) {
  let nh = b.base16_encode(c.hash(c.Sha256, <<name:utf8>>))
  use cd <- result.try(s.current_directory())
  let path = cd <> "/" <> cache_dir
  use _ <- result.try(s.create_directory_all(path))
  s.write(path <> "/" <> nh, content)
}
