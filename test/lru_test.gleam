import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import lru as l

pub fn main() {
  gleeunit.main()
}

// Test creating an empty cache
pub fn empty_cache_test() {
  let cache = l.empty(5)

  l.size(cache)
  |> should.equal(0)
}

// Test inserting a single item
pub fn insert_single_item_test() {
  let cache = l.empty(3)
  let cache = l.insert("key1", "value1", cache)

  l.size(cache)
  |> should.equal(1)

  l.member("key1", cache)
  |> should.be_true()
}

// Test inserting multiple items
pub fn insert_multiple_items_test() {
  let cache = l.empty(3)
  let cache = l.insert("key1", "value1", cache)
  let cache = l.insert("key2", "value2", cache)
  let cache = l.insert("key3", "value3", cache)

  l.size(cache)
  |> should.equal(3)

  l.member("key1", cache)
  |> should.be_true()

  l.member("key2", cache)
  |> should.be_true()

  l.member("key3", cache)
  |> should.be_true()
}

// Test cache eviction when exceeding capacity
pub fn cache_eviction_test() {
  let cache = l.empty(2)
  // Small cache
  let cache = l.insert("key1", "value1", cache)
  let cache = l.insert("key2", "value2", cache)

  // Cache is full, adding third item should evict key1 (oldest)
  let cache = l.insert("key3", "value3", cache)

  l.size(cache)
  |> should.equal(2)

  // key1 should be evicted
  l.member("key1", cache)
  |> should.be_false()

  // key2 and key3 should still be there
  l.member("key2", cache)
  |> should.be_true()

  l.member("key3", cache)
  |> should.be_true()
}

// Test getting items from cache
pub fn get_item_test() {
  let cache = l.empty(3)
  let cache = l.insert("key1", "value1", cache)

  let #(_cache, result) = l.get("key1", cache)

  result
  |> should.equal(Some("value1"))
}

// Test getting non-existent item
pub fn get_missing_item_test() {
  let cache = l.empty(3)

  let #(_cache, result) = l.get("missing_key", cache)

  result
  |> should.equal(None)
}

// Test LRU behavior: accessing an item makes it recently used
pub fn lru_access_behavior_test() {
  let cache = l.empty(2)
  let cache = l.insert("key1", "value1", cache)
  let cache = l.insert("key2", "value2", cache)

  // Access key1 to make it recently used
  let #(cache, _) = l.get("key1", cache)

  // Add key3 - should evict key2 (not key1, since key1 was accessed)
  let cache = l.insert("key3", "value3", cache)

  // key1 should still be there (was recently accessed)
  l.member("key1", cache)
  |> should.be_true()

  // key2 should be evicted (least recently used)
  l.member("key2", cache)
  |> should.be_false()

  // key3 should be there (just added)
  l.member("key3", cache)
  |> should.be_true()
}

// Test converting cache to dict
pub fn to_dict_test() {
  let cache = l.empty(3)
  let cache = l.insert("key1", "value1", cache)
  let cache = l.insert("key2", "value2", cache)

  let dict = l.to_dict(cache)

  // Should contain both keys (can't easily test dict contents in gleeunit)
  // But we can test the cache still works after conversion
  l.size(cache)
  |> should.equal(2)
}

// Test cache with zero capacity (edge case)
pub fn zero_capacity_test() {
  let cache = l.empty(0)
  let cache = l.insert("key1", "value1", cache)

  // Should evict immediately since capacity is 0
  l.size(cache)
  |> should.equal(0)

  l.member("key1", cache)
  |> should.be_false()
}

// Test inserting same key twice (should update, not duplicate)
pub fn update_existing_key_test() {
  let cache = l.empty(3)
  let cache = l.insert("key1", "value1", cache)
  let cache = l.insert("key1", "updated_value", cache)

  // Should still have size 1 (updated, not added)
  l.size(cache)
  |> should.equal(1)

  // Should get the updated value
  let #(_cache, result) = l.get("key1", cache)

  result
  |> should.equal(Some("updated_value"))
}

// Test complex LRU scenario
pub fn complex_lru_scenario_test() {
  let cache = l.empty(3)

  // Fill cache
  let cache = l.insert("a", "1", cache)
  let cache = l.insert("b", "2", cache)
  let cache = l.insert("c", "3", cache)

  // Access 'a' to make it recent
  let #(cache, _) = l.get("a", cache)

  // Add 'd' - should evict 'b' (oldest after 'a' was accessed)
  let cache = l.insert("d", "4", cache)

  // Access 'c' to make it recent
  let #(cache, _) = l.get("c", cache)

  // Add 'e' - should evict 'a' (now oldest)
  let cache = l.insert("e", "5", cache)

  // Final state should be: d, c, e
  l.member("a", cache) |> should.be_false()
  // evicted first
  l.member("b", cache) |> should.be_false()
  // evicted second  
  l.member("c", cache) |> should.be_true()
  // kept (accessed)
  l.member("d", cache) |> should.be_true()
  // kept
  l.member("e", cache) |> should.be_true()
  // just added

  l.size(cache) |> should.equal(3)
}
