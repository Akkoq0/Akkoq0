class_name EvaluateCataclysmCommand
extends GameCommand
## Core command (rank 2). Evaluates accumulated steppe environmental and war
## devastation variables in `region_coord` to trigger causal cataclysms
## (`Kara Zud ve Buz Kapanı`, `Bozkır Yangını ve Kurak Rüzgar`, or
## `Büyük Göç Dalgası ve Yıkım Depremi / Sel Taşkını`).

const ID: StringName = &"evaluate_cataclysm"

var region_coord: Vector2i = Vector2i.ZERO
var is_zud_winter: bool = false
var temperature_celsius: float = 10.0
var pasture_depleted: bool = false
var drought_severity: float = 0.0
var wind_speed_m_per_sec: float = 4.0
var river_slope_quake_hazard: float = 0.0

var triggered_type: GameEnums.CataclysmType = GameEnums.CataclysmType.NONE
var event_data: CataclysmEventData = null
var pasture_yield_multiplier: float = 1.0
var caravan_speed_multiplier: float = 1.0
var forest_concealment_loss_ratio: float = 0.0
var structural_wear_ratio: float = 0.0
var refugee_influx_count: int = 0
var open_response_options: PackedStringArray = PackedStringArray()


func _init(p_region_coord: Vector2i, p_is_zud_winter: bool = false, p_temperature_celsius: float = 10.0, p_pasture_depleted: bool = false, p_drought_severity: float = 0.0, p_wind_speed_m_per_sec: float = 4.0, p_river_slope_quake_hazard: float = 0.0) -> void:
	region_coord = p_region_coord
	is_zud_winter = p_is_zud_winter
	temperature_celsius = p_temperature_celsius
	pasture_depleted = p_pasture_depleted
	drought_severity = p_drought_severity
	wind_speed_m_per_sec = p_wind_speed_m_per_sec
	river_slope_quake_hazard = p_river_slope_quake_hazard


func get_command_id() -> StringName:
	return ID
