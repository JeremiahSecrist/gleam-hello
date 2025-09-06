import gleam/otp/actor
import gleam/erlang/process
import gleam/dict

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


// Start cache actor
pub fn start() -> Result(actor.Started(process.Subject(CacheMessage)), actor.StartError) {
  actor.new(dict.new())
  |> actor.on_message(handle_message)
  |> actor.start()
}

// Cache operations
pub fn set(cache: process.Subject(CacheMessage), key: String, value: String) {
  process.send(cache, Set(key, value))
}

pub fn get(cache: process.Subject(CacheMessage), key: String) -> Result(String, Nil) {
  process.call(cache, 5000, Get(key, _))
}

// Cache message handler
fn handle_message(
  cache: dict.Dict(String, String),
  message: CacheMessage,
) -> actor.Next(dict.Dict(String, String), CacheMessage) {
  case message {
    Shutdown -> actor.stop()
    Set(key, value) -> actor.continue(dict.insert(cache, key, value))
    Get(key, reply_with) -> {
      let result = dict.get(cache, key)
      process.send(reply_with, result)
      actor.continue(cache)
    }
  }
}
