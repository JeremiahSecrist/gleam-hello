import gleam/io
import gleam/erlang/process
import gleam/string_tree
import mist
import wisp
import wisp/wisp_mist

// ---------- Router ----------
pub fn handle_request(req) {
  case wisp.path_segments(req) {
    [] ->
      wisp.html_response(string_tree.from_string("<h1>Home Page</h1>"), 200)

    ["about"] ->
      wisp.html_response(string_tree.from_string("<h1>About Page</h1>"), 200)

    _ ->
      wisp.not_found()
  }
}

// ---------- Main ----------
pub fn main() {
  // Configure logger
  wisp.configure_logger()

  // Secret key
  let secret_key_base = wisp.random_string(64)

  // Start Mist server with Wisp handler
  let assert Ok(_) =
    wisp_mist.handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  io.println("🚀 Server running at http://localhost:8000")

  // Keep main process alive
  process.sleep_forever()
}

