class_name MicroZoneRenderer
extends GridCellRenderer
## World / micro (rank 3). Draws the most recently generated settlement zone.
## Visibility per layer is handled by a child `LayerVisibilityComponent`.


func _ready() -> void:
	super._ready()
	EventBus.micro_zone_generated.connect(_on_micro_zone_generated)


func _on_micro_zone_generated(zone_state: MicroZoneState) -> void:
	var cells: Array[GridCellRenderer.CellVisual] = []
	for tile: MicroTile in zone_state.get_tiles():
		if tile == null or tile.terrain == null:
			continue
		var cell: GridCellRenderer.CellVisual = GridCellRenderer.CellVisual.new(
			zone_state.tile_to_world(tile.coord), zone_state.tile_size_m, tile.elevation, tile.terrain.debug_color)
		if tile.has_ore():
			cell.has_marker = true
			cell.marker_color = tile.ore.debug_color
		cells.append(cell)
	draw_cells(cells)
