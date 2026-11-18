class_name GameEnums
extends RefCounted
## Foundation layer (rank 0). Shared, dependency-free enumerations.
##
## Every other layer may depend on this file; this file depends on nothing.

## The two simulation/presentation layers of the world.
enum WorldLayer {
	MACRO = 0, ## Strategic map of regions (armies, supply lines).
	MICRO = 1, ## Settlement zone inside a single macro region (buildings, ore nodes).
}

## Strict terrain typing shared by macro regions and micro tiles.
enum TerrainType {
	STEPPE = 0,
	FOREST = 1,
	MOUNTAIN = 2,
	RIVER = 3,
	DESERT = 4,
	TUNDRA = 5,
	HILLS = 6,
	LAKE = 7,
}

## High-level application state machine.
enum GameState {
	BOOT = 0,
	LOADING = 1,
	PLAYING = 2,
	PAUSED = 3,
	GAME_OVER = 4,
}

## Steppe calendar.
enum SeasonType {
	SPRING = 0, ## Bahar
	SUMMER = 1, ## Yaz
	AUTUMN = 2, ## Güz
	WINTER = 3, ## Kış
}

## Bit flags (1 << WorldLayer) used by `@export_flags` layer masks.
const LAYER_FLAG_MACRO: int = 1 << WorldLayer.MACRO
const LAYER_FLAG_MICRO: int = 1 << WorldLayer.MICRO


## Returns true when `layer_mask` contains the bit for `layer`.
static func layer_mask_has(layer_mask: int, layer: WorldLayer) -> bool:
	return (layer_mask & (1 << layer)) != 0
