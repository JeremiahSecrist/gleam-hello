import gleam/list
import gleam/json
import gleam/dynamic/decode.{type Decoder}

pub fn pokemon_encoder(pokemon: Pokemon) -> String {
  json.object([
    #("id", json.int(pokemon.id)),
    #("name", json.string(pokemon.name)),
    #("base_experience", json.int(pokemon.base_experience)),
    #("cries",
      json.object([
        #("latest", json.string(pokemon.cries.latest)),
        #("legacy", json.string(pokemon.cries.legacy)),
      ])
    ),
    // #("is_default", json.bool(pokemon.is_default)),
    #("order", json.int(pokemon.order)),
    #("stats", 
      json.object(
        list.map(pokemon.stats, stat_entry_to_pair)
      )
    ),
    #("moves", moves_to_json(pokemon.moves)),
    #("weight", json.int(pokemon.weight)),
  ])
  |> json.to_string
}

pub type Pokemon{
  Pokemon(
    abilities: Abilities,
    base_experience: Int,
    cries: Cries,
    name: String,
    forms: List(Forms),
    game_indices: GameIndices,
    // height: Int,
    // held_items: HeldItems,
    id: Int,
    is_default: Bool,
    // location_area_encounters: LocationAreaEncounters,
    moves: Moves,
    order: Int,
    // past_abilities: PastAbilities,
    // past_types: PastTypes,
    // species: Species,
    // sprites: Sprites,
    stats: Stats,
    // types: Types,
    weight: Int,
  )
}

pub type Moves = List(Pmove)
// Decoder for a single Move inside a Pmove
fn pmove_decoder() -> Decoder(Pmove) {
  use move <- decode.field("move", move_decoder())
  decode.success(PMove(move))
}

pub type Pmove {
  PMove(move: Move)
}

pub type Move {
  Move(name: String)
}

fn move_decoder() -> Decoder(Move) {
  use name <- decode.field("name", decode.string)
  decode.success(Move(name))
}

fn moves_to_json(moves: Moves) -> json.Json {
  json.array(moves, fn(pmove) {
    let PMove(Move(name)) = pmove
    json.string(name)
  })
}

pub fn pokemon_json_parse(string:String) -> Result(Pokemon, json.DecodeError) {
  json.parse(string, pokemon_decoder())
} 
pub fn pokemon_decoder() -> Decoder(Pokemon) {
  use abilities <- decode.field("abilities", abilities_decoder())
  use base_experience <- decode.field("base_experience", decode.int)
  use cries <- decode.field("cries", cries_decoder())
  use name <- decode.field("name", decode.string)
  use forms <- decode.field("forms", decode.list(forms_decoder()))
  use game_indices <- decode.field("game_indices", game_indices_decoder())
  use id <- decode.field("id", decode.int)
  use is_default <- decode.field("is_default", decode.bool)
  use moves <- decode.field("moves", decode.list(pmove_decoder()))
  use order <- decode.field("order", decode.int)
  use stats <- decode.field("stats", stats_decoder())
  use weight <- decode.field("weight", decode.int)
  decode.success(Pokemon(
    abilities:, 
    base_experience:, 
    cries:, 
    name:, 
    forms:, 
    game_indices:,
    id:, 
    is_default:,
    moves:,
    order:, 
    stats:, 
    weight:
    ))
}

pub type AbilityInfo {
  AbilityInfo(
    name: String,
    url: String,
  )
}

fn ability_info_decoder() -> Decoder(AbilityInfo) {
  use name <- decode.field("name", decode.string)
  use url <- decode.field("url", decode.string)
  decode.success(AbilityInfo(name:, url:))
}

pub type AbilityEntry {
  AbilityEntry(
    ability: AbilityInfo,
    is_hidden: Bool,
    slot: Int,
  )
}

fn ability_entry_decoder() -> Decoder(AbilityEntry) {
  use ability <- decode.field("ability", ability_info_decoder()) 
  use is_hidden <- decode.field("is_hidden", decode.bool)
  use slot <- decode.field("slot", decode.int)
  decode.success(AbilityEntry(ability:, is_hidden:, slot:))
}

pub type Abilities = List(AbilityEntry)

fn abilities_decoder() -> Decoder(List(AbilityEntry)) {
  decode.list(ability_entry_decoder())
}

pub type Cries{
  Cries(
    latest: String,
    legacy: String,
  ) 
}

fn cries_decoder() -> Decoder(Cries) {
  use latest <- decode.field("latest", decode.string)
  use legacy <- decode.field("legacy", decode.string)
  decode.success(Cries(latest:, legacy:))
}

pub type Forms{
  Forms(
    name: String,
    url: String,
  )
}

fn forms_decoder() -> Decoder(Forms) {
  use name <- decode.field("name", decode.string)
  use url <- decode.field("url", decode.string)
  decode.success(Forms(name:, url:))
}

pub type VersionInfo {
  VersionInfo(
    name: String,
    url: String,
  )
}

fn version_info_decoder() -> Decoder(VersionInfo) {
  use name <- decode.field("name", decode.string)
  use url <- decode.field("url", decode.string)
  decode.success(VersionInfo(name:, url:))
}

pub type GameIndexEntry {
  GameIndexEntry(
    game_index: Int,
    version: VersionInfo,
  )
}

fn game_index_entry_decoder() -> Decoder(GameIndexEntry) {
  use game_index <- decode.field("game_index", decode.int)
  use version <- decode.field("version", version_info_decoder()) 
  decode.success(GameIndexEntry(game_index:, version:))
}
fn stat_entry_to_pair(stat_entry: StatEntry) -> #(String, json.Json) {
  let StatEntry(base_stat, stat) = stat_entry
  #(stat.name, json.int(base_stat))
}
pub type GameIndices = List(GameIndexEntry)

fn game_indices_decoder() -> Decoder(List(GameIndexEntry)) {
  decode.list(game_index_entry_decoder())
}

pub type StatInfo {
  StatInfo(
    name: String,
    url: String,
  )
}

fn stat_info_decoder() -> Decoder(StatInfo) {
  use name <- decode.field("name", decode.string)
  use url <- decode.field("url", decode.string)
  decode.success(StatInfo(name:, url:))
}

pub type StatEntry {
  StatEntry(
    base_stat: Int,
    stat: StatInfo,
  )
}


fn stat_entry_decoder() -> Decoder(StatEntry) {
  use base_stat <- decode.field("base_stat", decode.int)
  use stat <- decode.field("stat", stat_info_decoder())
  decode.success(StatEntry(base_stat:, stat:))
}

pub type Stats = List(StatEntry)

fn stats_decoder() -> Decoder(List(StatEntry)) {
  decode.list(stat_entry_decoder())
}

