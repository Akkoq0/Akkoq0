class_name GridCellRenderer
extends Node3D
## World shared utility (rank 3). Debug renderer that draws a grid of coloured
## boxes (+ optional ore markers) with two MultiMeshes. Concrete layer
## renderers translate their model into `CellVisual` entries.

## One drawable cell.
class CellVisual:
	var center: Vector3
	var size: float
	var elevation: float
	var color: Color
	var marker_color: Color
	var has_marker: bool

	func _init(p_center: Vector3, p_size: float, p_elevation: float, p_color: Color) -> void:
		center = p_center
		size = p_size
		elevation = p_elevation
		color = p_color
		marker_color = Color.WHITE
		has_marker = false


const TEX_STEPPE_PATH: String = "res://assets/textures/Grass001_1K-JPG_Color.jpg"
const TEX_WINTER_PATH: String = "res://assets/textures/Snow006_1K-JPG_Color.jpg"

@export var render_profile: WorldRenderProfile

var _cells_instance: MultiMeshInstance3D = null
var _markers_instance: MultiMeshInstance3D = null
var _cell_material: StandardMaterial3D = null


func _ready() -> void:
	if render_profile == null:
		push_error("%s: render_profile is not assigned." % get_path())
		return
	_cells_instance = _create_instance(BoxMesh.new(), "Cells")
	_markers_instance = _create_instance(SphereMesh.new(), "OreMarkers")
	if _cells_instance != null and _cells_instance.multimesh != null and _cells_instance.multimesh.mesh is PrimitiveMesh:
		var prim: PrimitiveMesh = _cells_instance.multimesh.mesh as PrimitiveMesh
		if prim.material is StandardMaterial3D:
			_cell_material = prim.material as StandardMaterial3D
			_apply_terrain_texture(false)
	if not EventBus.season_changed.is_connected(_on_season_changed):
		EventBus.season_changed.connect(_on_season_changed)


func _exit_tree() -> void:
	if EventBus.season_changed.is_connected(_on_season_changed):
		EventBus.season_changed.disconnect(_on_season_changed)


func _on_season_changed(season: SeasonData, _cycle_index: int) -> void:
	_apply_terrain_texture(season != null and season.season_type == GameEnums.SeasonType.WINTER)


func _apply_terrain_texture(is_winter: bool) -> void:
	if _cell_material == null:
		return
	var tex_path: String = TEX_WINTER_PATH if is_winter else TEX_STEPPE_PATH
	if ResourceLoader.exists(tex_path):
		var tex: Texture2D = ResourceLoader.load(tex_path) as Texture2D
		if tex != null:
			_cell_material.albedo_texture = tex
			_cell_material.uv1_scale = Vector3(2.0, 2.0, 2.0)
			return
	_cell_material.albedo_texture = null


## Rebuilds both MultiMeshes from `cells`.
func draw_cells(cells: Array[CellVisual]) -> void:
	if render_profile == null or _cells_instance == null:
		return
	var cell_mesh: MultiMesh = _cells_instance.multimesh
	cell_mesh.instance_count = cells.size()
	var marker_count: int = 0
	for cell: CellVisual in cells:
		if cell.has_marker:
			marker_count += 1
	var marker_mesh: MultiMesh = _markers_instance.multimesh
	marker_mesh.instance_count = marker_count

	var marker_index: int = 0
	for i: int in range(cells.size()):
		var cell: CellVisual = cells[i]
		var height: float = render_profile.base_thickness_m + cell.elevation * render_profile.height_scale_m
		var width: float = cell.size * (1.0 - render_profile.cell_gap_ratio)
		var basis: Basis = Basis.from_scale(Vector3(width, height, width))
		var origin: Vector3 = cell.center + Vector3(0.0, height * 0.5, 0.0)
		cell_mesh.set_instance_transform(i, Transform3D(basis, origin))
		cell_mesh.set_instance_color(i, cell.color)
		if cell.has_marker:
			var diameter: float = cell.size * render_profile.ore_marker_scale
			var marker_origin: Vector3 = cell.center + Vector3(0.0, height + diameter * 0.5, 0.0)
			marker_mesh.set_instance_transform(marker_index, Transform3D(Basis.from_scale(Vector3.ONE * diameter), marker_origin))
			marker_mesh.set_instance_color(marker_index, cell.marker_color)
			marker_index += 1


func _create_instance(mesh: PrimitiveMesh, instance_name: String) -> MultiMeshInstance3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = Vector3.ONE
	elif mesh is SphereMesh:
		(mesh as SphereMesh).radius = 0.5
		(mesh as SphereMesh).height = 1.0
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = instance_name
	instance.multimesh = multimesh
	add_child(instance)
	return instance
