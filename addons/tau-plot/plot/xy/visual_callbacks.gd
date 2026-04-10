## Visual callbacks compute rendering properties on-the-fly from data.
## Each overlay type defines its own subclass with specific callbacks.
## Each callback is optional (invalid Callable = no callback for that property).
@abstract class VisualCallbacks extends RefCounted:
	# Signature: func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> Color
	var color_callback: Callable = Callable()

	# Signature: func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> float
	# Return value should be in range [0.0, 1.0].
	var alpha_callback: Callable = Callable()
