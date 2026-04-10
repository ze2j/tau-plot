# Dependencies
const VisualCallbacks = preload("res://addons/tau-plot/plot/xy/visual_callbacks.gd").VisualCallbacks

## BAR overlay specific callbacks.
class BarVisualCallbacks extends VisualCallbacks:

	# Signature: func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> StyleBox
	var style_box_callback: Callable = Callable()
