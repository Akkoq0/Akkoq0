class_name MoltenOreAndMarketCrucible
extends Control
## UI Widget (rank 3). Custom `_draw()` Molten Ore & Market Crucible displaying
## ore/steel/artisan flow and the `tanh`-bounded `<= 3.40x` black-market elasticity.

const MAX_ELASTICITY_CAP: float = 3.40

var _iron: int = 0
var _coal: int = 0
var _steel: int = 0
var _silver: int = 0
var _meteoric: int = 0
var _artisan_factor: float = 1.0
var _black_market_mult: float = 1.0
var _volume_traded: int = 0


func _ready() -> void:
	custom_minimum_size = Vector2(280.0, 114.0)


func apply_snapshot(snap: WorldEcologyViewModel.WorldEcologySnapshot) -> void:
	if snap == null:
		return
	_iron = snap.iron_stock
	_coal = snap.coal_stock
	_steel = snap.steel_stock
	_silver = snap.silver_stock
	_meteoric = snap.meteoric_iron_stock
	_artisan_factor = snap.artisan_quality_factor
	_black_market_mult = clampf(snap.black_market_scarcity_mult, 1.0, MAX_ELASTICITY_CAP)
	_volume_traded = snap.market_volume_traded
	queue_redraw()


func _draw() -> void:
	var w: float = maxf(size.x, 220.0)
	var h: float = maxf(size.y, 98.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color(0.06, 0.06, 0.08, 0.90), true)
	draw_rect(Rect2(Vector2(1.0, 1.0), Vector2(w - 2.0, h - 2.0)), NeoSteppePalette.BRONZE_WEATHERED, false, 1.0)

	# Crucible vessel bars (Iron, Coal, Steel, Meteoric)
	var bar_x: float = 12.0
	var bar_w: float = w - 24.0
	var steel_ratio: float = clampf(float(_steel) / 150.0, 0.0, 1.0)
	draw_rect(Rect2(Vector2(bar_x, 36.0), Vector2(bar_w, 12.0)), Color(0.14, 0.14, 0.16, 0.9), true)
	draw_rect(Rect2(Vector2(bar_x, 36.0), Vector2(bar_w * steel_ratio, 12.0)), NeoSteppePalette.GOLD_TAMGA, true)

	# Black-market tanh elasticity bar (1.0x .. 3.40x)
	var bm_norm: float = clampf((_black_market_mult - 1.0) / (MAX_ELASTICITY_CAP - 1.0), 0.0, 1.0)
	draw_rect(Rect2(Vector2(bar_x, 74.0), Vector2(bar_w, 12.0)), Color(0.14, 0.12, 0.14, 0.9), true)
	var bm_col: Color = NeoSteppePalette.EMBER_RED if _black_market_mult >= 2.20 else NeoSteppePalette.JADE_BRIGHT
	draw_rect(Rect2(Vector2(bar_x, 74.0), Vector2(bar_w * bm_norm, 12.0)), bm_col, true)
	# Cap tick at right end
	draw_line(Vector2(bar_x + bar_w - 1.0, 70.0), Vector2(bar_x + bar_w - 1.0, 90.0), NeoSteppePalette.EMBER_RED, 2.0, true)

	var font: Font = ThemeDB.fallback_font
	if font != null:
		draw_string(font, Vector2(bar_x, 16.0), "POTA: Demir %d · Kömür %d · Çelik %d · Gök %d" % [_iron, _coal, _steel, _meteoric], HORIZONTAL_ALIGNMENT_LEFT, bar_w, 10, NeoSteppePalette.TEXT_PRIMARY)
		draw_string(font, Vector2(bar_x, 32.0), "Zanaatkar Çarpanı: %.2fx · Gümüş: %d" % [_artisan_factor, _silver], HORIZONTAL_ALIGNMENT_LEFT, bar_w, 10, NeoSteppePalette.GOLD_TAMGA)
		draw_string(font, Vector2(bar_x, 68.0), "Kara Borsa Esnekliği (tanh): %.2fx / 3.40x (Hacim %d)" % [_black_market_mult, _volume_traded], HORIZONTAL_ALIGNMENT_LEFT, bar_w, 10, bm_col)
