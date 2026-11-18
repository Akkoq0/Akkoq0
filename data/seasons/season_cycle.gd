class_name SeasonCycle
extends Resource
## Data layer (rank 1). Ordered, looping list of seasons.

@export var seasons: Array[SeasonData] = []
@export_range(0, 16) var starting_index: int = 0


## Returns the season at `index` (wrapped), or null when the cycle is empty.
func get_season(index: int) -> SeasonData:
	if seasons.is_empty():
		return null
	return seasons[posmod(index, seasons.size())]


## Index that follows `index` in the loop.
func get_next_index(index: int) -> int:
	if seasons.is_empty():
		return 0
	return posmod(index + 1, seasons.size())


## Returns a list of human-readable schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if seasons.is_empty():
		errors.append("SeasonCycle is empty.")
	if starting_index < 0 or starting_index >= maxi(seasons.size(), 1):
		errors.append("SeasonCycle.starting_index %d out of range." % starting_index)
	for season: SeasonData in seasons:
		if season == null:
			errors.append("SeasonCycle contains a null entry.")
		else:
			errors.append_array(season.get_validation_errors())
	return errors
