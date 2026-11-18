class_name TerrainClassifier
extends RefCounted
## World shared utility (rank 3). Pure, stateless terrain classification used
## by both world layers. Enforces strict terrain typing per layer.


## Returns the first rule terrain matching (elevation, moisture) that is
## allowed on `layer`; falls back to `fallback` otherwise.
static func classify(rules: Array[TerrainRule], elevation: float, moisture: float, layer: GameEnums.WorldLayer, fallback: TerrainData) -> TerrainData:
	for rule: TerrainRule in rules:
		if rule == null or rule.terrain == null:
			continue
		if not rule.terrain.is_allowed_in_layer(layer):
			continue
		if rule.matches(elevation, moisture):
			return rule.terrain
	return fallback


## Builds a seeded FastNoiseLite configured for terrain fields.
static func build_noise(noise_seed: int, frequency: float, octaves: int) -> FastNoiseLite:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves
	return noise


## Samples `noise` and remaps from [-1, 1] to [0, 1].
static func sample01(noise: FastNoiseLite, x: float, y: float) -> float:
	return clampf(noise.get_noise_2d(x, y) * 0.5 + 0.5, 0.0, 1.0)
