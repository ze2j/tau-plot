## Snapshot of one real sample drawn onto a line polyline, in pane-local
## screen coordinates. One record per dataset sample, sub-samples
## are not recorded.
class LineHitRecord extends RefCounted:
	## Dataset series id.
	var series_id: int

	## Sample index within the series.
	var sample_index: int

	## Float for continuous x, String for categorical.
	var x_value: Variant

	## Plotted y value.
	var y_value: float

	## Real sample position in pane-local screen coordinates.
	var screen_position: Vector2
