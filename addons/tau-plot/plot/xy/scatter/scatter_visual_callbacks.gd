# Dependencies
const VisualCallbacks := preload("res://addons/tau-plot/plot/xy/visual_callbacks.gd").VisualCallbacks

## SCATTER overlay specific callbacks.
class ScatterVisualCallbacks extends VisualCallbacks:
	# (series_index: int, sample_index: int, x_value: Variant, y_value: float) -> float
	var size_callback: Callable = Callable()

	# (series_index: int, sample_index: int, x_value: Variant, y_value: float) -> MarkerShape
	var shape_callback: Callable = Callable()

	# (series_index: int, sample_index: int, x_value: Variant, y_value: float) -> Color
	# Return ColorBuffer.NO_COLOR to leave the sample to the next resolution step.
	var outline_color_callback: Callable = Callable()

	# (series_index: int, sample_index: int, x_value: Variant, y_value: float) -> float
	var outline_width_callback: Callable = Callable()
