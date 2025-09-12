import yodel
import yodel/input
import cache.{type AppState, type CacheMessage, AppState}
import gleam/erlang/process
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/list
import gleam/result
import gleam/string_tree
import mist
import pokeapi.{pokemon_encoder, pokemon_json_parse}
import wisp
import wisp/wisp_mist
// import write

const url = "https://pokeapi.co/api/v2"

// Request handler that takes the app state
pub fn handle_request(req: wisp.Request, ctx: AppState) -> wisp.Response {
  case wisp.path_segments(req) {
    ["favicon.ico"] -> wisp.response(204)
    resp -> {
      let cache_key = list.fold(resp, "", fn(a, b) { a <> "/" <> b })
      case get_from_cache_or_fetch(ctx.cache, cache_key, url <> cache_key) {
        Ok(str) ->
          case pokemon_json_parse(str) {
            Ok(val) ->
              wisp.json_response(
                string_tree.from_string(pokemon_encoder(val)),
                200,
              )
            Error(_) -> wisp.json_response(string_tree.from_string(str), 200)
          }
        Error(code) -> wisp.response(code)
      }
    }
  }
}

// Wrapper to match wisp handler signature
pub fn request_handler(
  cache: process.Subject(CacheMessage),
) -> fn(wisp.Request) -> wisp.Response {
  handle_request(_, AppState(cache))
}

pub fn get_from_cache_or_fetch(
  cache: process.Subject(CacheMessage),
  cache_key: String,
  api_url: String,
) -> Result(String, Int) {
  case cache.get(cache, cache_key) {
    Error(_) -> {
      use fresh_data <- result.try(fetch_data(api_url))
      cache.set(cache, cache_key, fresh_data)
      Ok(fresh_data)
    }
    Ok(cached_data) -> Ok(cached_data)
  }
}

pub fn fetch_data(url: String) -> Result(String, Int) {
  use req <- result.try(request.to(url) |> result.replace_error(400))
  use resp <- result.try(httpc.send(req) |> result.replace_error(503))
  case resp.status {
    200 -> {
      Ok(resp.body)
    }
    status_code -> {
      Error(status_code)
    }
  }
}

pub fn main() {
  wisp.configure_logger()
  let assert Ok(file) = input.read_file(from:"./config.toml")
  let assert Ok(ctx) = yodel.load(file)
  let assert Ok(count) = yodel.get_int(ctx,"count")
  let assert Ok(port) = yodel.get_int(ctx,"port")
  case cache.start(count) {
    Ok(started) -> {
      let cache = started.data
      let secret_key_base = wisp.random_string(64)
      let assert Ok(_) =
        wisp_mist.handler(request_handler(cache), secret_key_base)
        |> mist.new
        |> mist.port(port)
        |> mist.start
      process.sleep_forever()
    }
    Error(_) -> {
      io.println("🚨 Failed to create persistent cache")
    }
  }
}
