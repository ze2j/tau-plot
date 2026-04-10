# Dependencies
const VisualAttributes = preload("res://addons/tau-plot/plot/xy/visual_attributes.gd").VisualAttributes

## Per-sample data-driven visual attribute buffers for SCATTER overlays.
## Each buffer is optional (null = no per-sample override for that property).
## Partial buffers are supported: if a buffer has fewer entries than the series,
## samples beyond the buffer size fall through to TauScatterStyle values.
class ScatterVisualAttributes extends VisualAttributes:
	const Float32Buffer = preload("res://addons/tau-plot/model/float32_buffer.gd").Float32Buffer
	const Int32Buffer = preload("res://addons/tau-plot/model/int32_buffer.gd").Int32Buffer

	# Per-sample marker size (units depend on active policy)
	var size_buffer: Float32Buffer = null

	# Per-sample MarkerShape enum values, -1 = unset (fall through to style default)
	var shape_buffer: Int32Buffer = null

	# Per-sample outline color
	var outline_color_buffer: ColorBuffer = null

	# Per-sample outline width in px, <0 = unset
	var outline_width_buffer: Float32Buffer = null
