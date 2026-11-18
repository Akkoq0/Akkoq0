class_name WorldRenderProfile
extends Resource
## Data layer (rank 1). Debug-visualisation parameters for world renderers.

## Vertical size (m) of a cell at elevation 1.0.
@export_range(0.0, 1000.0, 0.01) var height_scale_m: float = 1.0
## Minimum vertical size (m) of a cell (so low cells remain visible).
@export_range(0.01, 100.0, 0.01) var base_thickness_m: float = 0.1
## Fraction (0..0.9) of each cell left as a gap between neighbours.
@export_range(0.0, 0.9, 0.01) var cell_gap_ratio: float = 0.0
## Diameter of ore markers as a fraction of cell size.
@export_range(0.0, 1.0, 0.01) var ore_marker_scale: float = 0.5
