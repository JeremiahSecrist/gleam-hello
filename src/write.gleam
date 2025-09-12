import gleam/list
import simplifile.{type FileError} as s
import gleam/string
import gleam/result
import gleam/bit_array as b
import gleam/crypto as c

pub const cache_dir = ".cache"

pub fn merge_by_fours(strings: List(String)) -> List(String) {
  case list.length(strings) % 4 {
    0 -> {
      strings
      |> list.sized_chunk(into: 4)
      |> list.map(fn(chunk) {
        case chunk {
          [a, b, c, d] -> a <> b <> c <> d
          _ -> ""
        }
      })
    }
    _ -> [""]
  }
}

pub fn hash_path(key: String) -> #(String, String) {
  let hash_parts = c.hash(c.Sha256, <<key:utf8>>)
    |> b.base16_encode()
    |> string.to_graphemes()
    |> merge_by_fours()
  
  case list.reverse(hash_parts) {
    [filename, ..dir_parts] -> {
      let dir_path = list.reverse(dir_parts) |> string.join(with: "/")
      #(dir_path, filename)
    }
    [] -> #("", "")
  }
}

pub fn create_file(name: String, content: String) -> Result(Nil, FileError) {
  let #(hp, hashed_name) = hash_path(name)
  use cd <- result.try(s.current_directory())
  
  let dir_path = cd <> "/" <> cache_dir <> "/" <> hp
  let file_path = dir_path <> "/" <> hashed_name
  
  case s.is_file(file_path) {
    Ok(True) -> {
      use info <- result.try(s.file_info(file_path))
      case info.size {
        size if size > 0 -> Ok(Nil)
        _ -> {
          use _ <- result.try(s.create_directory_all(dir_path))
          s.write(file_path, content)
        }
      }
    }
    Ok(False) | Error(_) -> {
      use _ <- result.try(s.create_directory_all(dir_path))
      s.write(file_path, content)
    }
  }
}

pub fn read_file(name: String) -> Result(String, FileError) {
  let #(hp, hashed_name) = hash_path(name)
  use cd <- result.try(s.current_directory())
  let file_path = cd <> "/" <> cache_dir <> "/" <> hp <> "/" <> hashed_name
  s.read(file_path)
}
