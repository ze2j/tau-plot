# Dependencies
const VisualAttributes = preload("res://addons/tau-plot/plot/xy/visual_attributes.gd").VisualAttributes

## Per-sample data-driven visual attribute buffers for BAR overlays.
## Each buffer is optional (null = no per-sample override for that property).
## Partial buffers are supported: if a buffer has fewer entries than the series,
## samples beyond the buffer size fall through to TauBarStyle values.
class BarVisualAttributes extends VisualAttributes:
	pass
