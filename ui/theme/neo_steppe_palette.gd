class_name NeoSteppePalette
extends RefCounted
## UI Presentation (rank 4). Immutable "Bozkır Modernizmi" color, border,
## spacing and typography tokens for all Ötüken UI surfaces.

# --- Primary Obsidian & Charcoal Surfaces ------------------------------------
const OBSIDIAN_DEEP: Color = Color(0.055, 0.063, 0.078, 0.94)
const OBSIDIAN_GLASS: Color = Color(0.075, 0.086, 0.106, 0.86)
const CHARCOAL_SURFACE: Color = Color(0.110, 0.125, 0.149, 0.92)
const CHARCOAL_ELEVATED: Color = Color(0.149, 0.169, 0.200, 0.96)
const CHARCOAL_PRESSED: Color = Color(0.039, 0.047, 0.059, 0.98)
const OBSIDIAN_SHADOW: Color = Color(0.020, 0.024, 0.031, 0.72)

# --- Weathered Bronze & Gold Geometric Tamga Accents -------------------------
const BRONZE_WEATHERED: Color = Color(0.620, 0.478, 0.275, 1.0)
const BRONZE_DARK: Color = Color(0.365, 0.282, 0.165, 0.88)
const GOLD_TAMGA: Color = Color(0.831, 0.667, 0.361, 1.0)
const GOLD_PALE: Color = Color(0.922, 0.824, 0.608, 1.0)

# --- Semantic Steppe Accent Poles --------------------------------------------
## Yeşim: Stratejik üstünlük, Töre meşruiyeti, Tuğ etki alanı ve Kut dengesi.
const JADE_PRIMARY: Color = Color(0.180, 0.686, 0.541, 1.0)
const JADE_BRIGHT: Color = Color(0.310, 0.843, 0.678, 1.0)
const JADE_DARK: Color = Color(0.078, 0.251, 0.204, 0.92)

## Buz Mavisi: Zud kış soğuğu, Bozkır su hatları ve Ulak lojistiği.
const ICE_BLUE: Color = Color(0.353, 0.745, 0.910, 1.0)
const ICE_FROST: Color = Color(0.659, 0.890, 0.976, 1.0)
const ICE_DEEP: Color = Color(0.098, 0.239, 0.345, 0.92)

## Köz Kızılı: Ülüş kırgınlığı, Kuyu/Kervan sabotajı, Kıtlık ve Veraset krizi.
const EMBER_RED: Color = Color(0.855, 0.290, 0.220, 1.0)
const EMBER_BRIGHT: Color = Color(0.969, 0.443, 0.310, 1.0)
const EMBER_DARK: Color = Color(0.314, 0.098, 0.082, 0.94)

# --- Typography Colors -------------------------------------------------------
const TEXT_PRIMARY: Color = Color(0.937, 0.918, 0.867, 1.0)
const TEXT_SECONDARY: Color = Color(0.706, 0.686, 0.635, 1.0)
const TEXT_MUTED: Color = Color(0.490, 0.478, 0.447, 1.0)

# --- Typography Hierarchy (px) -----------------------------------------------
const FONT_SIZE_DISPLAY: int = 19
const FONT_SIZE_TITLE: int = 15
const FONT_SIZE_METRIC: int = 14
const FONT_SIZE_BODY: int = 12
const FONT_SIZE_CAPTION: int = 11
const FONT_SIZE_MICRO: int = 10

# --- Architectural Frame Metrics (px) ----------------------------------------
const BORDER_WIDTH_THIN: int = 1
const BORDER_WIDTH_EMPHASIS: int = 2
const CORNER_RADIUS_CRISP: int = 3
const CORNER_RADIUS_PILL: int = 4
const TAMGA_CORNER_LENGTH: float = 8.0


## Maps high-level tactical status poles (`&"jade"`, `&"ice"`, `&"ember"`, `&"bronze"`) to palette colors.
static func get_semantic_color(tone_id: StringName) -> Color:
	if tone_id == &"jade":
		return JADE_PRIMARY
	if tone_id == &"ice":
		return ICE_BLUE
	if tone_id == &"ember":
		return EMBER_RED
	if tone_id == &"gold":
		return GOLD_TAMGA
	return BRONZE_WEATHERED


## Maps tactical lens enum values to their signature Neo-Steppe accent color.
static func get_lens_accent_color(lens: GameEnums.TacticalMapLens) -> Color:
	match lens:
		GameEnums.TacticalMapLens.LOGISTICS_WATER_COURIER:
			return ICE_BLUE
		GameEnums.TacticalMapLens.YAYLAK_KISLAK:
			return JADE_BRIGHT
		GameEnums.TacticalMapLens.TUG_CONTROL:
			return JADE_PRIMARY
		GameEnums.TacticalMapLens.INTELLIGENCE_DUST:
			return EMBER_BRIGHT
		_:
			return GOLD_TAMGA
