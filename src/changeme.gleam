import gleam/io
import gleam/int
import gleam/erlang/process
import gleam/string_tree
import mist
import wisp
import wisp/wisp_mist
import gleam/http/request
import gleam/httpc

const url = "https://pokeapi.co/api/v2"
pub fn handle_request(req) {
  case wisp.path_segments(req) {
    [] -> wisp.json_response(string_tree.from_string(fetch_data(url)), 200)
    _ -> wisp.not_found()
  }
}

// Simple function that returns a string - either the response body or an error message
pub fn fetch_data(url: String) -> String {
  case request.to(url) {
    Ok(req) -> {
      case httpc.send(req) {
        Ok(resp) -> {
          case resp.status {
            200 -> resp.body
            404 -> "No data found"
            _ -> "Request failed with status: " <> int.to_string(resp.status)
          }
        }
        Error(_) -> "Failed to connect"
      }
    }
    Error(_) -> "Invalid URL"
  }
}


pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)
  let assert Ok(_) = wisp_mist.handler(handle_request, secret_key_base) |> mist.new |> mist.port(8000) |> mist.start
  io.println("🚀 Server running at http://localhost:8000")
  process.sleep_forever()
}
