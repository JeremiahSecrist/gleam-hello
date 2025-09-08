import gleam/bit_array as b
import gleam/crypto as c
import gleam/result
import simplifile.{type FileError} as s

const cache_dir = ".cache"

pub fn cf(name: String, content: String) -> Result(Nil, FileError) {
  let nh = b.base16_encode(c.hash(c.Sha256, <<name:utf8>>))
  use cd <- result.try(s.current_directory())
  let path = cd <> "/" <> cache_dir
  use _ <- result.try(s.create_directory_all(path))
  s.write(path <> "/" <> nh, content)
}
