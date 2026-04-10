## Per-sample data-driven visual attribute buffers shared by all overlay types.
## Each buffer is optional (null = no per-sample override for that property).
## Partial buffers are supported: if a buffer has fewer entries than the series,
## samples beyond the buffer size fall through to the resolved style values.
@abstract class VisualAttributes extends RefCounted:
	const ColorBuffer = preload("res://addons/tau-plot/model/color_buffer.gd").ColorBuffer
	const AlphaBuffer = preload("res://addons/tau-plot/model/float32_buffer.gd").Float32Buffer

	# Per-sample fill color
	var color_buffer: ColorBuffer = null

	# Per-sample alpha [0.0, 1.0], <0 = unset
	var alpha_buffer: AlphaBuffer = null
