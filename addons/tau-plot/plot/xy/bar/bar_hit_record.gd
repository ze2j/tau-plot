## Snapshot of one painted bar in pane-local screen coordinates.
class BarHitRecord extends RefCounted:
	## Dataset series id.
	var series_id: int

	## Sample index within the series.
	var sample_index: int

	## Float for continuous x, String for categorical.
	var x_value: Variant

	## Plotted y value. For STACKED with normalization, this is the scaled
	## value matching the y-axis labels, not the raw dataset value.
	var y_value: float

	## Painted rectangle, clipped to the pane.
	var rect: Rect2

	## Bar tip center in pane-local screen coordinates, un-clipped.
	var anchor: Vector2
