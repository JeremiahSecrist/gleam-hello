import gleam/io
import gleam/erlang/process
import gleam/string_tree
import mist
import wisp
import wisp/wisp_mist
import gleam/http/request
import gleam/httpc
import gleam/uri

const url = "https://pokeapi.co/api/v2"
pub fn handle_request(req) {
  case wisp.path_segments(req) {
    [first, ..] -> case fetch_data(url <> "/"<>first) {
      Ok(str) -> wisp.json_response(string_tree.from_string(str), 200)
      Error(code) -> wisp.response(code)
    }
    _ -> wisp.response(404)
  }
}

pub fn fetch_data(url: String) -> Result(String, Int) {
  case request.to(url) {
    Ok(req) -> {
      case httpc.send(req) {
        Ok(resp) -> {
          case resp.status {
            200 -> Ok(resp.body)
            a -> Error(a)
          }
        }
        Error(_) -> Error(503)
      }
    }
    Error(_) -> Error(400)
  }
}

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)
  let assert Ok(_) = wisp_mist.handler(handle_request, secret_key_base) |> mist.new |> mist.port(8000) |> mist.start
  io.println("🚀 Server running at http://localhost:8000")
  process.sleep_forever()
}
