class_name HybridConquestAndCollapsePanel
extends VBoxContainer
## UI Panel (rank 3). Houses Hybrid Conquest aftermath actions and 3-Way Collapse
## Recovery choices (SUBMIT_VASSAL, FLEE_HOMELESS_EXILE, REBUILD_AT_FRONTIER),
## dispatching strictly via CommandBus.

var _player_id: int = 1
var _target_coord: Vector2i = Vector2i.ZERO
var _state_label: Label = null
var _btn_vassal: Button = null
var _btn_exile: Button = null
var _btn_frontier: Button = null
var _btn_conquest_hold: Button = null
var _ui_built: bool = false


func _ready() -> void:
	name = "HybridConquestAndCollapsePanel"
	add_theme_constant_override("separation", 4)
	_build_ui()


func set_context(p_player_id: int, p_coord: Vector2i) -> void:
	_player_id = p_player_id
	_target_coord = p_coord


func apply_snapshot(snap: SovereigntyViewModel.SovereigntySnapshot) -> void:
	_build_ui()
	if snap == null:
		return
	_player_id = snap.player_id
	_target_coord = snap.target_coord
	if _state_label != null:
		_state_label.text = "Egemenlik: %s · Kut Tavanı %.0f" % [
			_format_collapse_state(snap.collapse_state), snap.kut_ceiling]
	var can_choose: bool = snap.can_select_collapse_path
	if _btn_vassal != null:
		_btn_vassal.disabled = not can_choose
	if _btn_exile != null:
		_btn_exile.disabled = not can_choose
	if _btn_frontier != null:
		_btn_frontier.disabled = not can_choose


func trigger_conquest_aftermath(choice: GameEnums.ConquestAftermathChoice) -> bool:
	var cmd: ResolveConquestAftermathCommand = ResolveConquestAftermathCommand.new(
		_player_id, _target_coord, choice)
	return CommandBus.dispatch(cmd)


func trigger_collapse_path(choice: GameEnums.CollapsePathChoice) -> bool:
	var cmd: SelectCollapsePathCommand = SelectCollapsePathCommand.new(_player_id, choice)
	return CommandBus.dispatch(cmd)


func _build_ui() -> void:
	if _ui_built:
		return
	_ui_built = true

	_state_label = Label.new()
	_state_label.name = "SovereigntyStateLabel"
	_state_label.add_theme_font_size_override("font_size", 11)
	_state_label.add_theme_color_override("font_color", NeoSteppePalette.GOLD_TAMGA)
	add_child(_state_label)

	var conq_row: HBoxContainer = HBoxContainer.new()
	conq_row.add_theme_constant_override("separation", 4)
	add_child(conq_row)

	_btn_conquest_hold = Button.new()
	_btn_conquest_hold.name = "ConquestHoldButton"
	_btn_conquest_hold.text = "Garnizon Tut"
	_btn_conquest_hold.pressed.connect(_on_conquest_hold_pressed)
	conq_row.add_child(_btn_conquest_hold)

	var collapse_row: HBoxContainer = HBoxContainer.new()
	collapse_row.add_theme_constant_override("separation", 4)
	add_child(collapse_row)

	_btn_vassal = Button.new()
	_btn_vassal.name = "CollapseVassalButton"
	_btn_vassal.text = "Tâbi Bey"
	_btn_vassal.pressed.connect(_on_vassal_pressed)
	collapse_row.add_child(_btn_vassal)

	_btn_exile = Button.new()
	_btn_exile.name = "CollapseExileButton"
	_btn_exile.text = "Sürgün"
	_btn_exile.pressed.connect(_on_exile_pressed)
	collapse_row.add_child(_btn_exile)

	_btn_frontier = Button.new()
	_btn_frontier.name = "CollapseFrontierButton"
	_btn_frontier.text = "Uç Beyi"
	_btn_frontier.pressed.connect(_on_frontier_pressed)
	collapse_row.add_child(_btn_frontier)


func _on_conquest_hold_pressed() -> void:
	trigger_conquest_aftermath(GameEnums.ConquestAftermathChoice.HOLD_GARRISON_CONTROL)


func _on_vassal_pressed() -> void:
	trigger_collapse_path(GameEnums.CollapsePathChoice.SUBMIT_VASSAL)


func _on_exile_pressed() -> void:
	trigger_collapse_path(GameEnums.CollapsePathChoice.FLEE_HOMELESS_EXILE)


func _on_frontier_pressed() -> void:
	trigger_collapse_path(GameEnums.CollapsePathChoice.REBUILD_AT_FRONTIER)


static func _format_collapse_state(st: GameEnums.CollapseState) -> String:
	match st:
		GameEnums.CollapseState.SOVEREIGN:
			return "Egemen Kağanlık"
		GameEnums.CollapseState.TRUCE_WITHDRAWAL:
			return "Ateşkes Çekilmesi"
		GameEnums.CollapseState.VASSAL_BEYLIK:
			return "Tâbi Beylik"
		GameEnums.CollapseState.HOMELESS_EXILE:
			return "Yersiz Yurtsuz Sürgün"
		GameEnums.CollapseState.FRONTIER_MARCH_LORD:
			return "Uç Beyi"
		GameEnums.CollapseState.DYNASTY_EXTINCT:
			return "Hanedan Söndü"
		_:
			return "Egemen"
