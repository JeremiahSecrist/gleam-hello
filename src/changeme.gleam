import gleam/io
import gleam/erlang/process
import gleam/string_tree
import gleam/dict
import gleam/int
import gleam/otp/actor
import mist
import wisp
import wisp/wisp_mist
import gleam/http/request
import gleam/httpc

const url = "https://pokeapi.co/api/v2"

// Cache messages
pub type CacheMessage {
  Set(key: String, value: String)
  Get(key: String, reply_with: process.Subject(Result(String, Nil)))
  Shutdown
}

// Cache message handler
fn handle_cache_message(
  cache: dict.Dict(String, String),
  message: CacheMessage,
) -> actor.Next(dict.Dict(String, String), CacheMessage) {
  case message {
    Shutdown -> {
      io.println("🛑 Cache shutting down")
      actor.stop()
    }
    Set(key, value) -> {
      io.println("✅ Caching: " <> key)
      let new_cache = dict.insert(cache, key, value)
      actor.continue(new_cache)
    }
    Get(key, reply_with) -> {
      let result = dict.get(cache, key)
      case result {
        Ok(_) -> io.println("🎯 Cache HIT: " <> key)
        Error(_) -> io.println("❌ Cache MISS: " <> key)
      }
      process.send(reply_with, result)
      actor.continue(cache)
    }
  }
}

// Start cache actor
pub fn start_cache() -> Result(actor.Started(process.Subject(CacheMessage)), actor.StartError) {
  actor.new(dict.new())
  |> actor.on_message(handle_cache_message)
  |> actor.start()
}

// Cache operations
pub fn cache_set(cache: process.Subject(CacheMessage), key: String, value: String) {
  process.send(cache, Set(key, value))
}

pub fn cache_get(cache: process.Subject(CacheMessage), key: String) -> Result(String, Nil) {
  process.call(cache, 5000, Get(key, _))
}

// Global cache subject - we'll pass this around
pub type AppState {
  AppState(cache: process.Subject(CacheMessage))
}

// Request handler that takes the app state
pub fn handle_request(req: wisp.Request, ctx: AppState) -> wisp.Response {
  case wisp.path_segments(req) {
    [first, ..] -> {
      let cache_key = first
      case get_from_cache_or_fetch(ctx.cache, cache_key, url <> "/" <> first) {
        Ok(str) -> {
          wisp.json_response(string_tree.from_string(str), 200)
        }
        Error(code) -> {
          wisp.response(code)
        }
      }
    }
    _ -> wisp.response(404)
  }
}

// Wrapper to match wisp handler signature
pub fn request_handler(cache: process.Subject(CacheMessage)) -> fn(wisp.Request) -> wisp.Response {
  fn(req: wisp.Request) -> wisp.Response {
    let ctx = AppState(cache)
    handle_request(req, ctx)
  }
}

pub fn get_from_cache_or_fetch(
  cache: process.Subject(CacheMessage),
  cache_key: String,
  api_url: String,
) -> Result(String, Int) {
  // Check cache first
  case cache_get(cache, cache_key) {
    Ok(cached_data) -> {
      io.println("🚀 Using cached data for: " <> cache_key)
      Ok(cached_data)
    }
    Error(_) -> {
      io.println("🔄 Cache miss, fetching from API: " <> cache_key)
      case fetch_data(api_url) {
        Ok(fresh_data) -> {
          // Store in cache
          cache_set(cache, cache_key, fresh_data)
          io.println("💾 Data cached for: " <> cache_key)
          Ok(fresh_data)
        }
        Error(code) -> {
          io.println("🚨 API fetch failed: " <> int.to_string(code))
          Error(code)
        }
      }
    }
  }
}

pub fn fetch_data(url: String) -> Result(String, Int) {
  io.println("🌐 Making API call to: " <> url)
  case request.to(url) {
    Ok(req) -> {
      case httpc.send(req) {
        Ok(resp) -> {
          case resp.status {
            200 -> {
              let body_length = string_tree.from_string(resp.body) |> string_tree.byte_size
              io.println("✅ API success (" <> int.to_string(body_length) <> " bytes)")
              Ok(resp.body)
            }
            status_code -> {
              io.println("❌ API error: " <> int.to_string(status_code))
              Error(status_code)
            }
          }
        }
        Error(_) -> {
          io.println("🚨 HTTP request failed")
          Error(503)
        }
      }
    }
    Error(_) -> {
      io.println("🚨 Invalid URL: " <> url)
      Error(400)
    }
  }
}

pub fn main() {
  wisp.configure_logger()
  
  io.println("🏁 Starting Pokemon API with persistent caching...")
  
  // Create a persistent cache that survives across requests
  case start_cache() {
    Ok(started) -> {
      let cache = started.data
      
      io.println("📦 Persistent cache created!")
      
      let secret_key_base = wisp.random_string(64)
      let assert Ok(_) = wisp_mist.handler(request_handler(cache), secret_key_base)
        |> mist.new
        |> mist.port(8000)
        |> mist.start
      
      io.println("🚀 Server running at http://localhost:8000")
      io.println("🎯 Cache persists across requests - try the same endpoint twice!")
      io.println("🧪 Test with: curl http://localhost:8000/pokemon/1")
      io.println("📊 Second request should show Cache HIT!")
      
      process.sleep_forever()
    }
    Error(_) -> {
      io.println("🚨 Failed to create persistent cache")
    }
  }
}
