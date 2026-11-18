class_name UnitStack
extends Resource
## Data layer (rank 1). `count` units of a given `UnitData`.

@export var unit: UnitData
@export_range(0, 100000) var count: int = 0


## True when this stack contributes to an army.
func is_populated() -> bool:
	return unit != null and count > 0
