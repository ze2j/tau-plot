const AxisId := preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const StackedNormalization := preload("res://addons/tau-plot/plot/xy/stacked_normalization.gd").StackedNormalization
const StackedNegativePolicy := preload("res://addons/tau-plot/plot/xy/stacked_negative_policy.gd").StackedNegativePolicy


# Stacking and forced-range override for one (pane, y-axis) pair.
#
# bar_stack_active and line_stack_active are independent flags: each tells the
# domain scanner that the corresponding overlay type contributes a stacked
# cumulative on this axis. Both can be true at the same time, in which case
# their cumulatives are computed separately and unioned with the non-stacked
# range. Cross-overlay validation enforces a single shared
# stacked_normalization and a single shared stacked_negative_policy on the
# axis when both flags are true.
class YDomainOverride extends RefCounted:

	var force_y_range: bool = false
	var force_y_min: float = 0.0
	var force_y_max: float = 1.0

	var bar_stack_active: bool = false
	var line_stack_active: bool = false

	var stacked_normalization: StackedNormalization = StackedNormalization.NONE
	var stacked_negative_policy: StackedNegativePolicy = StackedNegativePolicy.DIVERGING


# Per-pane and per-axis Y domain overrides driven by renderers.
class XYDomainOverrides extends RefCounted:

	var y_domain_overrides: Array = [] # FIXME Real type is Array[Dictionary[AxisId, YDomainOverride]. Godot 4.5 does not support nested typed collections.


	# Resizes per-pane storage. Existing entries below p_pane_count are kept.
	func init_panes(p_pane_count: int) -> void:
		while y_domain_overrides.size() > p_pane_count:
			y_domain_overrides.pop_back()
		while y_domain_overrides.size() < p_pane_count:
			var empty: Dictionary[AxisId, YDomainOverride] = {}
			y_domain_overrides.append(empty)


	# Returns null when no override exists for that (pane, axis).
	func get_override(p_pane_index: int, p_y_axis_id: AxisId) -> YDomainOverride:
		if p_pane_index < 0 or p_pane_index >= y_domain_overrides.size():
			return null
		var pane_dict: Dictionary[AxisId, YDomainOverride] = y_domain_overrides[p_pane_index]
		if p_y_axis_id in pane_dict:
			return pane_dict[p_y_axis_id]
		return null


	func get_or_create_override(p_pane_index: int, p_y_axis_id: AxisId) -> YDomainOverride:
		var pane_dict: Dictionary[AxisId, YDomainOverride] = y_domain_overrides[p_pane_index]
		if p_y_axis_id in pane_dict:
			return pane_dict[p_y_axis_id]
		var override := YDomainOverride.new()
		pane_dict[p_y_axis_id] = override
		return override


	func clear_pane(p_pane_index: int) -> void:
		if p_pane_index < 0 or p_pane_index >= y_domain_overrides.size():
			return
		y_domain_overrides[p_pane_index].clear()
