import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}

pub type LruCache(key, value) {
  LruCache(items: Dict(key, #(value, Int)), maximum: Int, counter: Int)
}

// Helper: find the item with the minimum value when applying function f
// Optimized version with early termination for counter values
fn minimum_by(f: fn(a) -> Int, items: List(a)) -> Option(a) {
  case items {
    // Empty list - no minimum
    [] -> None

    // Single item - it's the minimum
    [single_item] -> Some(single_item)
    // Multiple items - find the one with minimum f(item) value
    [first_item, ..remaining_items] -> {
      let first_value = f(first_item)

      // For our LRU cache, if we find counter value 0 (oldest possible), we can stop
      case first_value == 0 {
        True -> Some(first_item)
        // Can't get older than counter 0!
        False -> {
          let compare_items = fn(current_best: #(a, Int), candidate: a) -> #(
            a,
            Int,
          ) {
            let #(best_item, best_value) = current_best
            let candidate_value = f(candidate)

            // Early termination: if we find counter 0, that's definitely the oldest
            case candidate_value == 0 {
              True -> #(candidate, 0)
              False ->
                case candidate_value < best_value {
                  True -> #(candidate, candidate_value)
                  // New minimum found
                  False -> #(best_item, best_value)
                  // Keep current minimum
                }
            }
          }

          let starting_best = #(first_item, first_value)
          let #(final_best_item, _final_best_value) =
            list.fold(remaining_items, starting_best, compare_items)

          Some(final_best_item)
        }
      }
    }
  }
}

// Create empty cache
pub fn empty(maximum: Int) -> LruCache(key, value) {
  LruCache(items: dict.new(), maximum: maximum, counter: 0)
}

// Insert into cache
pub fn insert(
  key: key,
  value: value,
  cache: LruCache(key, value),
) -> LruCache(key, value) {
  // Special case: zero capacity cache should never store anything
  case cache.maximum == 0 {
    True -> cache
    False -> {
      let new_items =
        case dict.size(cache.items) >= cache.maximum {
          True -> {
            let get_count = fn(item) {
              let #(_, #(_, c)) = item
              c
            }
            case minimum_by(get_count, dict.to_list(cache.items)) {
              Some(#(removed_key, _)) -> dict.delete(cache.items, removed_key)
              None -> cache.items
            }
          }
          False -> cache.items
        }
        |> dict.insert(key, #(value, cache.counter))
      let new_counter = case cache.counter >= 1_000_000 {
        True -> 1000
        // Reset to 0 when it gets large
        False -> cache.counter + 1
      }
      LruCache(..cache, items: new_items, counter: new_counter)
    }
  }
}

// Get value from cache and update recency
pub fn get(
  key: key,
  cache: LruCache(key, value),
) -> #(LruCache(key, value), Option(value)) {
  case dict.get(cache.items, key) {
    Ok(#(entry, _)) -> {
      let updated_items = dict.insert(cache.items, key, #(entry, cache.counter))
      #(
        LruCache(..cache, items: updated_items, counter: cache.counter + 1),
        Some(entry),
      )
    }
    Error(Nil) -> #(cache, None)
  }
}

// Cache size
pub fn size(cache: LruCache(key, value)) -> Int {
  dict.size(cache.items)
}

// Check membership without updating recency
pub fn member(key: key, cache: LruCache(key, value)) -> Bool {
  dict.has_key(cache.items, key)
}

// Convert to plain Dict
pub fn to_dict(cache: LruCache(key, value)) -> Dict(key, value) {
  let value_of = fn(_k, pair) {
    let #(v, _) = pair
    v
  }
  dict.map_values(cache.items, value_of)
}
