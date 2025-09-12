import gleeunit
import gleeunit/should
import simplifile as s
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
  
  // Destructure the hash_path tuple
  let #(hp, hashed_name) = hash_path(name)
  let cd = case s.current_directory() {
    Ok(dir) -> dir
    Error(_e) -> panic as "failed to get current_directory"
  }
  
  // Build proper paths
  let dir_path = cd <> "/" <> cache_dir <> "/" <> hp
  let file_path = dir_path <> "/" <> hashed_name
  
  // Create directory and empty file - handle Results properly
  case s.create_directory_all(dir_path) {
    Ok(_) -> Nil
    Error(_) -> panic as "failed to create directory"
  }
  
  case s.write(file_path, "") {
    Ok(_) -> Nil
    Error(_) -> panic as "failed to write empty file"
  }
  
  // Now call create_file, should overwrite the empty file
  let _ = create_file(name, content)
  let read_content = read_file(name)
  read_content |> should.equal(Ok(content))
}
