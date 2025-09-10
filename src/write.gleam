
import simplifile.{type FileError} as s
import gleam/string
import gleam/result
import gleam/bit_array as b
import gleam/crypto as c

pub const cache_dir = ".cache"

// Hash a key into a nested path string, like "aa/bb/cc..."
pub fn hash_path(key: String) -> String {
  c.hash(c.Sha256, <<key:utf8>>)
  |> b.base16_encode()
  |> string.to_graphemes()
  |> string.join(with: "/")
}

// Create a file unless it already exists with non-zero size
pub fn create_file(name: String, content: String) -> Result(Nil, FileError) {
  let hp = hash_path(name)
  use cd <- result.try(s.current_directory())
  let file_path = cd <> "/" <> cache_dir <> "/" <> hp
  let dir_path = string.drop_end(file_path, up_to: string.length(name))

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

    Ok(False) -> {
      use _ <- result.try(s.create_directory_all(dir_path))
      s.write(file_path, content)
    }

    Error(e) -> Error(e)
  }
}

// Read back file content
pub fn read_file(name: String) -> Result(String, FileError) {
  let hp = hash_path(name)
  use cd <- result.try(s.current_directory())
  let file_path = cd <> "/" <> cache_dir <> "/" <> hp
  s.read(file_path)
}

