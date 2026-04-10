# Dependencies
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout


# Resolves bar geometry (width, gap, offsets) from layout + dataset + overlay config + style.
# This is the single source of truth for bar width policy computations so renderers never diverge.
class BarGeometry extends RefCounted:
	var _layout: XYLayout = null
	var _dataset: Dataset = null
	var _bar_config: TauBarConfig = null
	var _style: TauBarStyle = null

	# Number of series mapped as bars. Must be provided at construction;
	# 0 means no bar series (geometry queries will return zero/empty results).
	var _bar_series_count: int = 0

	# Pane index and active x axis config, passed from the renderer.
	var _pane_index: int = 0
	var _x_axis_config: TauAxisConfig = null
	var _x_is_horizontal: bool = true

	var _resolved_bar_width_policy: TauBarConfig.BarWidthPolicy = TauBarConfig.BarWidthPolicy.AUTO

	const _MIN_BAR_WIDTH_PX: float = 1.0


	func _init(p_layout: XYLayout, p_dataset: Dataset, p_bar_config: TauBarConfig, p_style: TauBarStyle, p_bar_series_count: int = 0, p_pane_index: int = 0, p_x_axis_config: TauAxisConfig = null) -> void:
		_layout = p_layout
		_dataset = p_dataset
		_bar_config = p_bar_config
		_style = p_style
		_bar_series_count = p_bar_series_count
		_pane_index = p_pane_index
		_x_axis_config = p_x_axis_config
		_x_is_horizontal = p_layout._x_is_horizontal
		_resolved_bar_width_policy = _bar_config.get_resolved_bar_width_policy(_x_axis_config.type)


	func get_resolved_bar_width_policy() -> TauBarConfig.BarWidthPolicy:
		return _resolved_bar_width_policy


	####################################################################################################
	# Geometry queries
	####################################################################################################

	func compute_group_gap_px_for_shared_x_index(p_index: int, p_count: int) -> float:
		if _x_axis_config.type != TauAxisConfig.Type.CONTINUOUS:
			return 0.0
		if _bar_config.mode != TauBarConfig.BarMode.GROUPED:
			return 0.0
		if p_count <= 0:
			return 0.0

		var x_i := float(_dataset.get_shared_x(p_index))

		match _resolved_bar_width_policy:
			TauBarConfig.BarWidthPolicy.THEME:
				return max(float(_style.bar_intragroup_gap_px), 0.0)

			TauBarConfig.BarWidthPolicy.DATA_UNITS:
				return _compute_group_gap_px_data_units_at_x(x_i)

			TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION:
				return _compute_group_gap_px_neighbor_spacing_shared_x(p_index, p_count)

			_:
				return 0.0


	func compute_bar_width_px_for_shared_x_index(p_index: int, p_count: int) -> float:
		if _x_axis_config.type != TauAxisConfig.Type.CONTINUOUS:
			return 0.0

		if p_count <= 0:
			return 0.0

		var x_i := float(_dataset.get_shared_x(p_index))

		match _resolved_bar_width_policy:
			TauBarConfig.BarWidthPolicy.THEME:
				return max(float(_style.bar_width_px), _MIN_BAR_WIDTH_PX)

			TauBarConfig.BarWidthPolicy.DATA_UNITS:
				if _is_log_x_scale():
					return max(_compute_bar_width_px_from_log_multiplicative_units(x_i, max(_bar_config.bar_width_log_factor, 1.000001)), _MIN_BAR_WIDTH_PX)
				else:
					return max(_compute_bar_width_px_from_data_units(x_i, _bar_config.bar_width_x_units), _MIN_BAR_WIDTH_PX)

			TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION:
				var series_count := _bar_series_count
				var grouped := (_bar_config.mode == TauBarConfig.BarMode.GROUPED)
				var gap_frac := max(_bar_config.neighbor_gap_fraction, 0.0)

				if _is_log_x_scale():
					# group_width_factor = spacing_ratio ^ frac
					var group_width_factor := _compute_neighbor_width_factor_log_shared_x(p_index, p_count, _bar_config.neighbor_spacing_fraction)

					if grouped and series_count > 1:
						var denom := _compute_group_denom_log(series_count, gap_frac)
						var per_bar_factor := pow(max(group_width_factor, 1.000001), 1.0 / denom)
						return max(_compute_bar_width_px_from_log_multiplicative_units(x_i, per_bar_factor), _MIN_BAR_WIDTH_PX)

					return max(_compute_bar_width_px_from_log_multiplicative_units(x_i, max(group_width_factor, 1.000001)), _MIN_BAR_WIDTH_PX)

				# Linear: group_width_units = spacing * frac
				var group_width_units := _compute_neighbor_width_units_linear_shared_x(p_index, p_count, _bar_config.neighbor_spacing_fraction)

				if grouped and series_count > 1:
					var denom := _compute_group_denom_linear(series_count, gap_frac)
					var per_bar_units := group_width_units / denom
					return max(_compute_bar_width_px_from_data_units(x_i, per_bar_units), _MIN_BAR_WIDTH_PX)

				return max(_compute_bar_width_px_from_data_units(x_i, group_width_units), _MIN_BAR_WIDTH_PX)

			_:
				return _MIN_BAR_WIDTH_PX


	func compute_bar_width_px_for_series_sample(p_series_id: int, p_index: int, p_count: int) -> float:
		if _x_axis_config.type != TauAxisConfig.Type.CONTINUOUS:
			return 0.0

		if p_count <= 0:
			return 0.0

		var x_i := float(_dataset.get_series_x(p_series_id, p_index))

		match _resolved_bar_width_policy:
			TauBarConfig.BarWidthPolicy.THEME:
				return max(float(_style.bar_width_px), _MIN_BAR_WIDTH_PX)

			TauBarConfig.BarWidthPolicy.DATA_UNITS:
				if _is_log_x_scale():
					return max(_compute_bar_width_px_from_log_multiplicative_units(x_i, max(_bar_config.bar_width_log_factor, 1.000001)), _MIN_BAR_WIDTH_PX)
				else:
					return max(_compute_bar_width_px_from_data_units(x_i, _bar_config.bar_width_x_units), _MIN_BAR_WIDTH_PX)

			TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION:
				var series_count := _bar_series_count
				var grouped := (_bar_config.mode == TauBarConfig.BarMode.GROUPED)
				var gap_frac := max(_bar_config.neighbor_gap_fraction, 0.0)

				if _is_log_x_scale():
					var group_width_factor := _compute_neighbor_width_factor_log_per_series(p_series_id, p_index, p_count, _bar_config.neighbor_spacing_fraction)

					if grouped and series_count > 1:
						var denom := _compute_group_denom_log(series_count, gap_frac)
						var per_bar_factor := pow(max(group_width_factor, 1.000001), 1.0 / denom)
						return max(_compute_bar_width_px_from_log_multiplicative_units(x_i, per_bar_factor), _MIN_BAR_WIDTH_PX)

					return max(_compute_bar_width_px_from_log_multiplicative_units(x_i, max(group_width_factor, 1.000001)), _MIN_BAR_WIDTH_PX)

				var group_width_units := _compute_neighbor_width_units_linear_per_series(p_series_id, p_index, p_count, _bar_config.neighbor_spacing_fraction)

				if grouped and series_count > 1:
					var denom := _compute_group_denom_linear(series_count, gap_frac)
					var per_bar_units := group_width_units / denom
					return max(_compute_bar_width_px_from_data_units(x_i, per_bar_units), _MIN_BAR_WIDTH_PX)

				return max(_compute_bar_width_px_from_data_units(x_i, group_width_units), _MIN_BAR_WIDTH_PX)

			_:
				return _MIN_BAR_WIDTH_PX


	####################################################################################################
	# Categorical geometry queries
	####################################################################################################

	## Returns the pixel width of a single bar at the given category index.
	## Accounts for bar mode (grouped/stacked/independent), width policy,
	## series count, and category slot width.
	##
	## p_pane_rect: pane rectangle in screen coordinates.
	## p_category_count: total number of categories on the x axis.
	func compute_categorical_bar_width_px(p_pane_rect: Rect2, p_category_count: int) -> float:
		if p_category_count <= 0:
			return _MIN_BAR_WIDTH_PX

		var step_px := _get_categorical_step_px(p_pane_rect, p_category_count)

		match _resolved_bar_width_policy:
			TauBarConfig.BarWidthPolicy.THEME:
				return max(float(_style.bar_width_px), _MIN_BAR_WIDTH_PX)

			TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION:
				var group_span_px := step_px * clampf(_bar_config.category_width_fraction, 0.000001, 1.0)

				if _bar_config.mode == TauBarConfig.BarMode.GROUPED and _bar_series_count > 1:
					var g := clampf(_bar_config.intra_group_gap_fraction, 0.0, 1.0)
					var denom := float(_bar_series_count) + float(_bar_series_count - 1) * g
					return max(group_span_px / denom, _MIN_BAR_WIDTH_PX)

				return max(group_span_px, _MIN_BAR_WIDTH_PX)

			_:
				push_error("BarGeometry: bar_width_policy %d is not supported for CATEGORICAL x" % int(_resolved_bar_width_policy))
				return _MIN_BAR_WIDTH_PX


	## Returns the pixel offset from the category center to the center of
	## the bar for p_series_local_idx within a GROUPED layout.
	##
	## p_series_local_idx: zero-based index of the series within the bar group.
	## p_pane_rect: pane rectangle in screen coordinates.
	## p_category_count: total number of categories on the x axis.
	func compute_grouped_bar_center_offset_px(p_series_local_idx: int, p_pane_rect: Rect2, p_category_count: int) -> float:
		if _bar_config.mode != TauBarConfig.BarMode.GROUPED:
			push_error("BarGeometry: compute_grouped_bar_center_offset_px called with non-GROUPED mode %d" % int(_bar_config.mode))
			return 0.0
		if _bar_series_count <= 1:
			return 0.0
		if p_category_count <= 0:
			return 0.0

		var bar_width_px := compute_categorical_bar_width_px(p_pane_rect, p_category_count)
		var gap_px := compute_categorical_group_gap_px(p_pane_rect, p_category_count)

		var stride := bar_width_px + gap_px
		var center_index := (float(_bar_series_count) - 1.0) * 0.5
		return (float(p_series_local_idx) - center_index) * stride


	## Returns the pixel width of the intra-group gap for GROUPED categorical bars.
	##
	## p_pane_rect: pane rectangle in screen coordinates.
	## p_category_count: total number of categories on the x axis.
	func compute_categorical_group_gap_px(p_pane_rect: Rect2, p_category_count: int) -> float:
		if _bar_config.mode != TauBarConfig.BarMode.GROUPED:
			push_error("BarGeometry: compute_categorical_group_gap_px called with non-GROUPED mode %d" % int(_bar_config.mode))
			return 0.0
		if _bar_series_count <= 1:
			return 0.0
		if p_category_count <= 0:
			return 0.0

		match _resolved_bar_width_policy:
			TauBarConfig.BarWidthPolicy.THEME:
				return max(float(_style.bar_intragroup_gap_px), 0.0)

			TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION:
				var step_px := _get_categorical_step_px(p_pane_rect, p_category_count)
				var group_span_px := step_px * clampf(_bar_config.category_width_fraction, 0.000001, 1.0)
				var g := clampf(_bar_config.intra_group_gap_fraction, 0.0, 1.0)
				var denom := float(_bar_series_count) + float(_bar_series_count - 1) * g
				var per_bar_px := group_span_px / denom
				return per_bar_px * g

			_:
				push_error("BarGeometry: bar_width_policy %d is not supported for CATEGORICAL x group gap" % int(_resolved_bar_width_policy))
				return 0.0


	## Returns the number of pixels per category slot along the x axis direction.
	func _get_categorical_step_px(p_pane_rect: Rect2, p_category_count: int) -> float:
		var x_extent: float = p_pane_rect.size.x if _x_is_horizontal else p_pane_rect.size.y
		return x_extent / float(p_category_count)


	####################################################################################################
	# Private helpers
	####################################################################################################

	# Maps an X value to pixels using the shared x axis.
	func _map_x_value_to_px(p_x: float) -> float:
		return _layout.map_x_to_px(_pane_index, p_x)


	func _is_log_x_scale() -> bool:
		return (_x_axis_config.type == TauAxisConfig.Type.CONTINUOUS and
				_x_axis_config.scale == TauAxisConfig.Scale.LOGARITHMIC)


	func _compute_px_distance_for_x_units(p_x_center: float, p_units: float) -> float:
		# Convert a delta in X data units into pixels at the given center.
		if p_units <= 0.0:
			return 0.0
		var x0 := _map_x_value_to_px(p_x_center)
		var x1 := _map_x_value_to_px(p_x_center + p_units)
		return absf(x1 - x0)


	func _compute_bar_width_px_from_data_units(p_x_value: float, p_bar_width_x_units: float) -> float:
		var half := p_bar_width_x_units * 0.5
		var x0 := _map_x_value_to_px(p_x_value - half)
		var x1 := _map_x_value_to_px(p_x_value + half)
		return absf(x1 - x0)


	func _compute_bar_width_px_from_log_multiplicative_units(p_x_center: float, p_multiplicative_width: float) -> float:
		# Width in log space: bar spans from x_center/sqrt(w) to x_center*sqrt(w)
		# where w is the multiplicative width factor
		if p_x_center <= 0.0 or p_multiplicative_width <= 0.0:
			return _MIN_BAR_WIDTH_PX

		var half_factor := sqrt(p_multiplicative_width)
		var x0 := p_x_center / half_factor
		var x1 := p_x_center * half_factor

		var px0 := _map_x_value_to_px(x0)
		var px1 := _map_x_value_to_px(x1)

		return absf(px1 - px0)


	func _compute_log_px_distance_for_multiplicative_gap(p_x_center: float, p_gap_factor: float) -> float:
		# Gap in log space is also multiplicative
		if p_x_center <= 0.0 or p_gap_factor <= 0.0:
			return 0.0

		var x0 := p_x_center
		var x1 := p_x_center * p_gap_factor

		var px0 := _map_x_value_to_px(x0)
		var px1 := _map_x_value_to_px(x1)

		return absf(px1 - px0)


	func _compute_log_gap_factor_from_width_factor(p_width_factor: float, p_gap_relative_to_width: float) -> float:
		# Converts a "gap relative to bar width in log space" into a multiplicative factor.
		var w := max(p_width_factor, 1.000001)
		var r := max(p_gap_relative_to_width, 1.0)
		return pow(w, r - 1.0)


	func _compute_group_gap_px_data_units_at_x(p_x_value: float) -> float:
		if _is_log_x_scale():
			if p_x_value <= 0.0:
				return 0.0
			var w_factor := max(_bar_config.bar_width_log_factor, 1.000001)
			var g_factor := _compute_log_gap_factor_from_width_factor(w_factor, max(_bar_config.bar_gap_log_factor, 1.0))
			return _compute_log_px_distance_for_multiplicative_gap(p_x_value, g_factor)

		return _compute_px_distance_for_x_units(p_x_value, max(_bar_config.bar_gap_x_units, 0.0))


	func _compute_group_gap_px_neighbor_spacing_shared_x(p_index: int, p_count: int) -> float:
		var series_count := _bar_series_count
		if series_count <= 1:
			return 0.0

		var x_i := float(_dataset.get_shared_x(p_index))
		var gap_frac := max(_bar_config.neighbor_gap_fraction, 0.0)

		if _is_log_x_scale():
			if x_i <= 0.0:
				return 0.0

			var group_width_factor := _compute_neighbor_width_factor_log_shared_x(p_index, p_count, _bar_config.neighbor_spacing_fraction)
			var denom := _compute_group_denom_log(series_count, gap_frac)
			var per_bar_factor := pow(max(group_width_factor, 1.000001), 1.0 / denom)

			var gap_factor := pow(max(per_bar_factor, 1.000001), gap_frac)
			return _compute_log_px_distance_for_multiplicative_gap(x_i, gap_factor)

		var group_width_units := _compute_neighbor_width_units_linear_shared_x(p_index, p_count, _bar_config.neighbor_spacing_fraction)
		var denom := _compute_group_denom_linear(series_count, gap_frac)
		var per_bar_units := group_width_units / denom

		var gap_units: float = per_bar_units * gap_frac
		return _compute_px_distance_for_x_units(x_i, gap_units)


	func _compute_neighbor_width_units_linear_shared_x(p_index: int, p_count: int, p_fraction: float) -> float:
		if p_count <= 1:
			return max(_bar_config.bar_width_x_units, 0.0)

		var x_i := float(_dataset.get_shared_x(p_index))
		var spacing := 0.0
		if p_index == 0:
			spacing = float(_dataset.get_shared_x(1)) - x_i
		elif p_index == p_count - 1:
			spacing = x_i - float(_dataset.get_shared_x(p_count - 2))
		else:
			var next_x := float(_dataset.get_shared_x(p_index + 1))
			var prev_x := float(_dataset.get_shared_x(p_index - 1))
			spacing = minf(next_x - x_i, x_i - prev_x)

		return absf(spacing) * clampf(p_fraction, 0.0, 1.0)


	func _compute_neighbor_width_units_linear_per_series(p_series_id: int, p_index: int, p_count: int, p_fraction: float) -> float:
		if p_count <= 1:
			return max(_bar_config.bar_width_x_units, 0.0)

		var x_i := float(_dataset.get_series_x(p_series_id, p_index))
		var spacing := 0.0
		if p_index == 0:
			spacing = float(_dataset.get_series_x(p_series_id, 1)) - x_i
		elif p_index == p_count - 1:
			spacing = x_i - float(_dataset.get_series_x(p_series_id, p_count - 2))
		else:
			var next_x := float(_dataset.get_series_x(p_series_id, p_index + 1))
			var prev_x := float(_dataset.get_series_x(p_series_id, p_index - 1))
			spacing = minf(next_x - x_i, x_i - prev_x)

		return absf(spacing) * clampf(p_fraction, 0.0, 1.0)


	func _compute_neighbor_width_factor_log_shared_x(p_index: int, p_count: int, p_fraction: float) -> float:
		if p_count <= 1:
			return max(_bar_config.bar_width_log_factor, 1.000001)

		var x_i := float(_dataset.get_shared_x(p_index))
		if x_i <= 0.0:
			return 1.0

		var spacing_ratio := 1.0
		if p_index == 0:
			var x_next := float(_dataset.get_shared_x(1))
			spacing_ratio = x_next / x_i if x_i > 0.0 else 1.0
		elif p_index == p_count - 1:
			var x_prev := float(_dataset.get_shared_x(p_count - 2))
			spacing_ratio = x_i / x_prev if x_prev > 0.0 else 1.0
		else:
			var x_next := float(_dataset.get_shared_x(p_index + 1))
			var x_prev := float(_dataset.get_shared_x(p_index - 1))
			var ratio_next := x_next / x_i if x_i > 0.0 else 1.0
			var ratio_prev := x_i / x_prev if x_prev > 0.0 else 1.0
			spacing_ratio = minf(ratio_next, ratio_prev)

		return pow(max(spacing_ratio, 1.0), clampf(p_fraction, 0.0, 1.0))


	func _compute_neighbor_width_factor_log_per_series(p_series_id: int, p_index: int, p_count: int, p_fraction: float) -> float:
		if p_count <= 1:
			return max(_bar_config.bar_width_log_factor, 1.000001)

		var x_i := float(_dataset.get_series_x(p_series_id, p_index))
		if x_i <= 0.0:
			return 1.0

		var spacing_ratio := 1.0
		if p_index == 0:
			var x_next := float(_dataset.get_series_x(p_series_id, 1))
			spacing_ratio = x_next / x_i if x_i > 0.0 else 1.0
		elif p_index == p_count - 1:
			var x_prev := float(_dataset.get_series_x(p_series_id, p_count - 2))
			spacing_ratio = x_i / x_prev if x_prev > 0.0 else 1.0
		else:
			var x_next := float(_dataset.get_series_x(p_series_id, p_index + 1))
			var x_prev := float(_dataset.get_series_x(p_series_id, p_index - 1))
			var ratio_next := x_next / x_i if x_i > 0.0 else 1.0
			var ratio_prev := x_i / x_prev if x_prev > 0.0 else 1.0
			spacing_ratio = minf(ratio_next, ratio_prev)

		return pow(max(spacing_ratio, 1.0), clampf(p_fraction, 0.0, 1.0))


	func _compute_group_denom_linear(p_series_count: int, p_gap_frac: float) -> float:
		if p_series_count <= 1:
			return 1.0
		return float(p_series_count) + float(p_series_count - 1) * max(p_gap_frac, 0.0)


	func _compute_group_denom_log(p_series_count: int, p_gap_frac: float) -> float:
		# Same denominator, but interpreted as exponent sum in log-space.
		return _compute_group_denom_linear(p_series_count, p_gap_frac)
