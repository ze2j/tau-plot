# Dependencies
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout


# Resolves scatter marker geometry (size) from layout + overlay config + style.
# Single source of truth for scatter size computations so renderers never diverge.
class ScatterGeometry extends RefCounted:
	var _layout: XYLayout = null
	var _scatter_config: TauScatterConfig = null
	var _style: TauScatterStyle = null

	# Pane index for per-pane layout queries.
	var _pane_index: int = 0

	var _resolved_marker_size_policy: TauScatterConfig.MarkerSizePolicy = TauScatterConfig.MarkerSizePolicy.AUTO


	func _init(p_layout: XYLayout, p_scatter_config: TauScatterConfig, p_style: TauScatterStyle, p_pane_index: int = 0) -> void:
		_layout = p_layout
		_scatter_config = p_scatter_config
		_style = p_style
		_pane_index = p_pane_index
		_resolved_marker_size_policy = _scatter_config.get_resolved_marker_size_policy()


	####################################################################################################
	# Geometry queries
	####################################################################################################

	func get_resolved_marker_size_policy() -> TauScatterConfig.MarkerSizePolicy:
		return _resolved_marker_size_policy


	# Returns marker size in pixels for THEME policy.
	func get_marker_size_px_from_theme() -> float:
		return max(_style.marker_size_px, 1.0)


	# Returns marker size in pixels for DATA_UNITS policy at a given X value.
	# The marker spans `marker_size_data_units` X data units, converted to pixels.
	func compute_marker_size_px_at_x(p_x_value: float) -> float:
		var size_units := max(_scatter_config.marker_size_data_units, 0.0)
		if size_units <= 0.0:
			return 1.0

		if _is_log_x_scale():
			# For log X, DATA_UNITS is additive in data space.
			# Compute pixel span of [x - half, x + half].
			var half: float = size_units * 0.5
			var x_lo := p_x_value - half
			var x_hi := p_x_value + half
			# Clamp to positive for log
			if x_lo <= 0.0:
				x_lo = p_x_value * 0.01  # fallback: tiny positive value
			var px_lo := _layout.map_x_to_px(_pane_index, x_lo)
			var px_hi := _layout.map_x_to_px(_pane_index, x_hi)
			return max(absf(px_hi - px_lo), 1.0)
		else:
			# Linear: pixel span is constant across the plot
			var half: float = size_units * 0.5
			var px0 := _layout.map_x_to_px(_pane_index, p_x_value - half)
			var px1 := _layout.map_x_to_px(_pane_index, p_x_value + half)
			return max(absf(px1 - px0), 1.0)


	####################################################################################################
	# Private helpers
	####################################################################################################

	func _is_log_x_scale() -> bool:
		var h_config := _layout.domain.get_x_axis_config()
		return (h_config != null and
				h_config.type == TauAxisConfig.Type.CONTINUOUS and
				h_config.scale == TauAxisConfig.Scale.LOGARITHMIC)
