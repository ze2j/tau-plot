## Snapshot of one painted bar in pane-local screen coordinates.
class BarHitRecord extends RefCounted:
	## Dataset series id.
	var series_id: int

	## Sample index within the series.
	var sample_index: int

	## Float for continuous x, String for categorical.
	var x_value: Variant

	## Y position the bar's top is drawn at, in data units.
	## Differs from y_raw_value when STACKED is on (cumulative top) or when
	## FRACTION/PERCENT normalization is on.
	var y_plotted_value: float

	## Original dataset value, before any stacking, normalization, or
	## accumulation. Equal to y_plotted_value when STACKED is off.
	var y_raw_value: float

	## Painted rectangle, clipped to the pane.
	var rect: Rect2

	## Bar tip center in pane-local screen coordinates, un-clipped.
	var anchor: Vector2
