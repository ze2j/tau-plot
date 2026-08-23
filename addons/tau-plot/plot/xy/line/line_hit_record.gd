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

	## Y position the polyline vertex is drawn at, in data units.
	## Differs from y_raw_value when STACKED is on (cumulative top) or when
	## FRACTION/PERCENT normalization is on.
	var y_plotted_value: float

	## Original dataset value, before any stacking, normalization, or
	## accumulation. Equal to y_plotted_value when STACKED is off.
	var y_raw_value: float

	## Real sample position in pane-local screen coordinates.
	var screen_position: Vector2
