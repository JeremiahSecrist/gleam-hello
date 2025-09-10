import gleam/result
import gleeunit
import gleeunit/should
import simplifile as s
import gleam/string
import write.{create_file, read_file, hash_path, cache_dir}

pub fn main() {
  gleeunit.main()
}

// Test that a file is created and can be read
pub fn create_and_read_file_test() {
  let name = "test-key-1"
  let content = "hello world"

  // First create
  let _ = create_file(name, content)

  // Read back
  let read_content = read_file(name)
  read_content |> should.equal(Ok(content))
}

// Test that re-creating does not overwrite non-empty file

pub fn create_file_overwrites_empty_test() {
  let name = "test-key-3"
  let content = "new-data"

  // Manually create empty file
  let hp = hash_path(name)
  let cd =
    case s.current_directory() {
      Ok(dir) -> dir
      Error(_e) -> panic as "failed to get current_directory:"
    }
  let path = cd <> "/" <> cache_dir <> "/" <> string.drop_end(hp, up_to: 2)
  let file_path = path <> "/" <> hp
  let _ = s.create_directory_all(path)
  let _ = s.write(file_path, "")

  // Now call create_file, should overwrite
  let _ = create_file(name, content)
  let read_content = read_file(name)
  read_content |> should.equal(Ok(content))
}

