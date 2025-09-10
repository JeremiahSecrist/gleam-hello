import gleam/erlang/process
import gleam/otp/actor
import lru as l  // your LRU implementation
import gleam/option.{Some,None}
// Global cache subject - we'll pass this around
pub type AppState {
  AppState(cache: process.Subject(CacheMessage))
}

// Cache messages
pub type CacheMessage {
  Set(key: String, value: String)
  Get(key: String, reply_with: process.Subject(Result(String, Nil)))
  Shutdown
}

// Start cache actor with max size
pub fn start(max: Int) -> Result(
  actor.Started(process.Subject(CacheMessage)),
  actor.StartError,
) {
  actor.new(l.empty(max))
  |> actor.on_message(handle_message)
  |> actor.start()
}

// Public cache operations
pub fn set(cache: process.Subject(CacheMessage), key: String, value: String) {
  process.send(cache, Set(key, value))
}

pub fn get(
  cache: process.Subject(CacheMessage),
  key: String,
) -> Result(String, Nil) {
  process.call(cache, 5000, Get(key, _))
}

// Cache message handler

fn handle_message(
  cache: l.LruCache(String, String),
  message: CacheMessage,
) -> actor.Next(l.LruCache(String, String), CacheMessage) {
  case message {
    Shutdown -> actor.stop()

    Set(key, value) -> {
      let cache = l.insert(key, value, cache)
      actor.continue(cache)
    }

    Get(key, reply_with) -> {
      let #(cache, maybe_value) = l.get(key, cache)
      let result = 
        case maybe_value {
          Some(v) -> Ok(v)
          None -> Error(Nil)
        }
      process.send(reply_with, result)
      actor.continue(cache)
    }
  }
}

