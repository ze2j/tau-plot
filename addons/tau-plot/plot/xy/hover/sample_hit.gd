const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType


## Data object produced by the hit-testing engine.
## Describes a single sample under or near the cursor.
class SampleHit extends RefCounted:
	## Dataset series ID.
	var series_id: int

	## Human-readable series name from the dataset.
	var series_name: String

	## Logical sample index within the series.
	var sample_index: int

	## X value: float for continuous axes, String for categorical.
	var x_value: Variant

	## Y value.
	var y_value: float

	## Screen position of the data point in plot-local coordinates.
	## For bars this is the top-center of the bar (or the relevant edge
	## depending on orientation). For scatter this is the marker center.
	var screen_position: Vector2

	## Pane index the hit belongs to.
	var pane_index: int

	## Which overlay type the hit came from.
	var overlay_type: PaneOverlayType

	## Pixel distance from cursor to the hit point. Useful for users who
	## want to implement a custom distance threshold.
	var distance_px: float

	## True when the cursor position falls inside the visual bounds of this
	## sample (the bar rectangle for bars, the marker radius for scatter).
	var contains_pointer: bool = false
