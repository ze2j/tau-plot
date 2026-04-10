class YDomainOverride extends RefCounted:
	const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId

	# The y-axis that the override targets. Only that axis is affected by
	# force_y_range and stack_y_values. A value of -1 means "no axis targeted"
	# (override is inactive regardless of the flags above).
	var target_y_axis_id: int = -1

	var force_y_range: bool = false
	var force_y_min: float = 0.0
	var force_y_max: float = 1.0

	var stack_y_values: bool = false


	func reset() -> void:
		target_y_axis_id = -1
		force_y_range = false
		force_y_min = 0.0
		force_y_max = 1.0
		stack_y_values = false


# XY plot domain overrides driven by renderers.
# Y axis overrides are per-pane.
class XYDomainOverrides extends RefCounted:

	var y_domain_overrides: Array[YDomainOverride] = [] # Per-pane Y axis overrides.

	# Initializes per-pane override storage. Existing entries are preserved up to
	# p_pane_count. Excess entries are trimmed and missing entries are appended.
	func init_panes(p_pane_count: int) -> void:
		while y_domain_overrides.size() > p_pane_count:
			y_domain_overrides.pop_back()
		while y_domain_overrides.size() < p_pane_count:
			y_domain_overrides.append(YDomainOverride.new())
