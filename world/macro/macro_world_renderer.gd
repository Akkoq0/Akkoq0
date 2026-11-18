class_name MacroWorldRenderer
extends GridCellRenderer
## World / macro (rank 3). Draws the macro map whenever it is (re)generated.
## Visibility per layer is handled by a child `LayerVisibilityComponent`.

## Ore whose marker colour represents a region (highest tier wins).
@export var ore_registry: OreRegistry


func _ready() -> void:
	super._ready()
	EventBus.macro_world_generated.connect(_on_macro_world_generated)


func _on_macro_world_generated(world_state: MacroWorldState) -> void:
	var cells: Array[GridCellRenderer.CellVisual] = []
	for region: MacroRegion in world_state.get_regions():
		if region == null or region.terrain == null:
			continue
		var cell: GridCellRenderer.CellVisual = GridCellRenderer.CellVisual.new(
			region.world_center, world_state.region_size_m, region.elevation, region.terrain.debug_color)
		var marker_ore: OreData = _pick_marker_ore(region)
		if marker_ore != null:
			cell.has_marker = true
			cell.marker_color = marker_ore.debug_color
		cells.append(cell)
	draw_cells(cells)


func _pick_marker_ore(region: MacroRegion) -> OreData:
	if ore_registry == null or not region.has_deposits():
		return null
	var best: OreData = null
	for ore_id: StringName in region.ore_deposits:
		var ore: OreData = ore_registry.find_ore(ore_id)
		if ore != null and (best == null or ore.tier > best.tier):
			best = ore
	return best
