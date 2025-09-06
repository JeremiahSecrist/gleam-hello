import gleam/json
import gleam/dynamic/decode.{type Decoder}

pub fn pokemon_encoder(pokemon: Pokemon) -> String {
  json.object([
    #("name", json.string(pokemon.name)),
    #("base_experience", json.int(pokemon.base_experience)),
    #("criesssss",
      json.object([
        #("latest", json.string(pokemon.cries.latest)),
        #("legacy", json.string(pokemon.cries.legacy)),
      ])
    ),
  ])
  |> json.to_string
}


pub fn pokemon_decoder(json_string: String) -> Result(Pokemon, json.DecodeError) {
    let poke_decoder = {
      use name <- decode.field("name", decode.string)
      use base_experience <- decode.field("base_experience", decode.int)
      use cries <- decode.field("cries",cries_decoder()) 
      decode.success(Pokemon(name:,base_experience:,cries:))
    }
    json.parse(from: json_string, using: poke_decoder)

}

pub fn cries_decoder() -> Decoder(Cries) {
  use latest <- decode.field("latest", decode.string)
  use legacy <- decode.field("legacy", decode.string)
  decode.success(Cries(latest:, legacy:))
}



pub type Pokemon{
  Pokemon(
    // abilities: Abilities,
    base_experience: Int,
    cries: Cries,
    name: String
    // forms: Forms,
    // game_indices: GameIndices,
    // height: Int,
    // held_items: HeldItems,
    // id: Int,
    // is_default: Bool,
    // location_area_encounters: LocationAreaEncounters,
    // moves: Moves,
    // name: String,
    // order: Int,
    // past_abilities: PastAbilities,
    // past_types: PastTypes,
    // species: Species,
    // sprites: Sprites,
    // stats: Stats,
    // types: Types,
    // weight: Int,
  )
}

pub type AbilityInfo {
  AbilityInfo(
    name: String,
    url: String,
  )
}

pub type AbilityEntry {
  AbilityEntry(
    ability: AbilityInfo,
    is_hidden: Bool,
    slot: Int,
  )
}

pub type Abilities = List(AbilityEntry)

pub type Cries{
  Cries(
    latest: String,
    legacy: String,
  ) 
}

pub type Forms{
  Forms(
    name: String,
    url: String,
  )
}

pub type VersionInfo {
  VersionInfo(
    name: String,
    url: String,
  )
}

pub type GameIndexEntry {
  GameIndexEntry(
    game_index: Int,
    version: VersionInfo,
  )
}

pub type GameIndices = List(GameIndexEntry)

pub type StatInfo {
  StatInfo(
    name: String,
    url: String,
  )
}

pub type StatEntry {
  StatEntry(
    base_stat: Int,
    effort: Int,
    stat: StatInfo,
  )
}

pub type Stats = List(StatEntry)
