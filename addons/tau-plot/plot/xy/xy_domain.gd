# Dependencies
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const YDomainOverride := preload("res://addons/tau-plot/plot/xy/xy_domain_overrides.gd").YDomainOverride
const XYDomainOverrides := preload("res://addons/tau-plot/plot/xy/xy_domain_overrides.gd").XYDomainOverrides
const SeriesAxisAssignment := preload("res://addons/tau-plot/plot/xy/series_axis_assignment.gd").SeriesAxisAssignment
const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const Axis = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis


# Resolved domain for a single axis.
# Stores the padded domain (min_val/max_val used by renderers), the raw data
# bounds before padding, and the recompute thresholds used to decide whether
# incoming data can skip a full domain recomputation.
class AxisDomain extends RefCounted:
	var config: TauAxisConfig = null
	var scale: TauAxisConfig.Scale = TauAxisConfig.Scale.LINEAR

	# Padded domain bounds (used by renderers and layout).
	var min_val: float = INF
	var max_val: float = -INF

	# Raw data bounds before padding was applied.
	var data_min: float = INF
	var data_max: float = -INF

	# Recompute thresholds: if any incoming data value falls outside
	# [recompute_min, recompute_max], a full domain + tick recompute is needed.
	# These sit at the midpoint between raw data bounds and padded bounds,
	# leaving half the padding as visual headroom for elements near the boundary.
	var recompute_min: float = -INF
	var recompute_max: float = INF

	func reset() -> void:
		min_val = INF
		max_val = -INF
		data_min = INF
		data_max = -INF
		recompute_min = -INF
		recompute_max = INF


# Resolved domain for a single pane.
class PaneYDomains extends RefCounted:
	var pane_config: TauPaneConfig = null
	var y_axis_domains: Dictionary[AxisId, AxisDomain] = {}

	func get_y_axis_domain(p_axis_id: AxisId) -> AxisDomain:
		if p_axis_id in y_axis_domains:
			return y_axis_domains[p_axis_id]
		return null

	func reset() -> void:
		for d in y_axis_domains.values():
			d.reset()


# Computes and stores the resolved axis domains for XY plots.
# It validates dataset consistency based on TauXYConfig and applies overrides/policies.
# Renderers rely on it to provide coherent domains (min < max) and consistent categories.
#
# Axis model: one shared x axis and per-pane y axes. The secondary x axis is
# display-only and does not participate in domain computation.
class XYDomain extends RefCounted:
	# Inputs
	var config: TauXYConfig = null
	var overrides: XYDomainOverrides = null
	var series_assignment: SeriesAxisAssignment = null

	# Outputs
	var x_axis_domain: AxisDomain = AxisDomain.new()
	var x_categories: PackedStringArray = []
	var pane_y_domains: Array[PaneYDomains] = []


	const _RELATIVE_EXPAND_FRACTION: float = 0.1
	const _MIN_ABSOLUTE_EXPAND: float = 1.0
	const _LOG_MIN_DOMAIN_RATIO: float = 1.1  # Minimum ratio between max/min for log scales


	func _init(p_dataset: Dataset, p_config: TauXYConfig, p_series_assignment: SeriesAxisAssignment, p_overrides: XYDomainOverrides = null) -> void:
		config = p_config
		overrides = p_overrides
		series_assignment = p_series_assignment
		update_from_dataset(p_dataset)


	# FIXME: pane_y_domains is public so remove this method?
	func get_pane_count() -> int:
		return pane_y_domains.size()


	# FIXME: pane_y_domains is public so remove this method?
	func get_pane_domain(p_pane_index: int) -> PaneYDomains:
		return pane_y_domains[p_pane_index]


	# FIXME: config.x_axis is public so remove this method?
	func get_x_axis_config() -> TauAxisConfig:
		return config.x_axis


	func update_from_dataset(p_dataset: Dataset) -> void:
		_reset_domain()

		# Compute shared x axis domain.
		_compute_x_domain(p_dataset)

		# Compute per-pane raw y domains.
		var pane_count := config.panes.size()
		var y_axes: Array[AxisId] = Axis.get_orthogonal_axes(config.x_axis_id)
		pane_y_domains.resize(pane_count)
		for pane_idx in range(pane_count):
			_compute_pane_y_domains(p_dataset, pane_idx, y_axes)

		# Per-pane zero-alignment.
		for pane_idx in range(pane_count):
			var pane_domain: PaneYDomains = pane_y_domains[pane_idx]
			if not pane_domain.pane_config.align_y_axes_at_zero:
				continue

			# Zero alignment requires exactly two y axes, both linear.
			if y_axes.size() != 2:
				continue
			var y_axis_domain_0: AxisDomain = pane_domain.get_y_axis_domain(y_axes[0])
			var y_axis_domain_1: AxisDomain = pane_domain.get_y_axis_domain(y_axes[1])
			if y_axis_domain_0 == null or y_axis_domain_1 == null:
				continue
			if y_axis_domain_0.scale != TauAxisConfig.Scale.LINEAR or y_axis_domain_1.scale != TauAxisConfig.Scale.LINEAR:
				continue

			var overridden_0 := (y_axis_domain_0.config != null and y_axis_domain_0.config.range_override_enabled)
			var overridden_1 := (y_axis_domain_1.config != null and y_axis_domain_1.config.range_override_enabled)
			var include_zero_0 := (y_axis_domain_0.config != null and y_axis_domain_0.config.include_zero_in_domain)
			var include_zero_1 := (y_axis_domain_1.config != null and y_axis_domain_1.config.include_zero_in_domain)

			# Both overridden: cannot modify either axis, skip.
			if overridden_0 and overridden_1:
				continue

			# For a non-overridden axis, include_zero_in_domain must be true.
			# For an overridden axis, the overridden range must contain zero.
			var zero_ok_0: bool = (overridden_0 and _range_contains_zero(y_axis_domain_0.min_val, y_axis_domain_0.max_val)) or (not overridden_0 and include_zero_0)
			var zero_ok_1: bool = (overridden_1 and _range_contains_zero(y_axis_domain_1.min_val, y_axis_domain_1.max_val)) or (not overridden_1 and include_zero_1)
			if not zero_ok_0 or not zero_ok_1:
				continue

			# lock_a / lock_b tell the alignment function which domain(s) it
			# must not modify. When one axis is overridden its range is locked.
			_align_y_axes_at_zero_for_pane(y_axis_domain_0, y_axis_domain_1, overridden_0, overridden_1)


	####################################################################################################
	# Private
	####################################################################################################

	func _reset_domain() -> void:
		x_categories = []
		x_axis_domain.reset()
		for pane_domain in pane_y_domains:
			pane_domain.reset()


	# Computes the shared x axis domain.
	func _compute_x_domain(p_dataset: Dataset) -> void:
		var x_axis_cfg := config.x_axis

		# If no x axis configured, leave domain at INF/-INF (unused).
		if x_axis_cfg == null:
			return

		match x_axis_cfg.type:
			TauAxisConfig.Type.CATEGORICAL:
				x_categories = _get_categories(p_dataset)

			TauAxisConfig.Type.CONTINUOUS:
				var xmin := INF
				var xmax := -INF

				if x_axis_cfg.range_override_enabled:
					xmin = x_axis_cfg.min_override
					xmax = x_axis_cfg.max_override
				else:
					var is_log := x_axis_cfg.scale == TauAxisConfig.Scale.LOGARITHMIC
					if p_dataset.get_mode() == Dataset.Mode.SHARED_X:
						var x_range := _compute_continuous_shared_x(p_dataset, is_log)
						xmin = x_range.x
						xmax = x_range.y
					else:
						var series_ids := series_assignment.get_x_axis_series_ids()
						var x_range := _compute_continuous_per_series_x(p_dataset, series_ids, is_log)
						xmin = x_range.x
						xmax = x_range.y

					if is_inf(xmin) or is_inf(xmax):
						# Empty plot or no-samples => provide default domain.
						if x_axis_cfg.scale == TauAxisConfig.Scale.LOGARITHMIC:
							xmin = 0.1
							xmax = 10.0
						else:
							xmin = 0.0
							xmax = 1.0
					else:
						# Save raw data bounds before padding.
						x_axis_domain.data_min = xmin
						x_axis_domain.data_max = xmax

						# Apply domain padding from TauAxisConfig.
						var padded := _apply_domain_padding(xmin, xmax, x_axis_cfg, false)
						xmin = padded.x
						xmax = padded.y

				var fixed := _ensure_non_degenerate_range(xmin, xmax, x_axis_cfg.scale)
				x_axis_domain.min_val = fixed.x
				x_axis_domain.max_val = fixed.y
				_compute_recompute_thresholds(x_axis_domain)

			_:
				push_error("Unexpected x axis type %d" % int(x_axis_cfg.type))


	func _compute_pane_y_domains(p_dataset: Dataset, p_pane_idx: int, p_y_axis_ids: Array[AxisId]) -> void:
		var pane_domain := PaneYDomains.new()

		var pane_config: TauPaneConfig = config.panes[p_pane_idx]
		pane_domain.pane_config = pane_config

		for y_axis_id in p_y_axis_ids:
			var y_axis_cfg: TauAxisConfig = pane_config.get_y_axis_config(y_axis_id)
			if y_axis_cfg == null:
				continue

			# Auto-disable include_zero for log scales
			if y_axis_cfg.scale == TauAxisConfig.Scale.LOGARITHMIC and y_axis_cfg.include_zero_in_domain:
				push_warning("Auto-disabling include_zero_in_domain for logarithmic %s axis (pane %d)" % [Axis.as_string(y_axis_id), p_pane_idx])
				y_axis_cfg.include_zero_in_domain = false

			var y_axis_domain := AxisDomain.new()
			y_axis_domain.config = y_axis_cfg
			y_axis_domain.scale = y_axis_cfg.scale

			# Scan raw data range for the y axis.
			var y_axis_series_ids: PackedInt64Array = series_assignment.get_y_axis_series_ids(p_pane_idx, y_axis_id)
			var is_log := y_axis_cfg.scale == TauAxisConfig.Scale.LOGARITHMIC
			var raw_range := _scan_series_y_range(p_dataset, y_axis_series_ids, p_pane_idx, y_axis_id, is_log)
			y_axis_domain.min_val = raw_range.x
			y_axis_domain.max_val = raw_range.y
			y_axis_domain.data_min = raw_range.x
			y_axis_domain.data_max = raw_range.y

			var y_range_forced := _is_y_range_forced(p_pane_idx, y_axis_id)
			if y_range_forced:
				y_axis_domain.min_val = _get_forced_y_min(p_pane_idx)
				y_axis_domain.max_val = _get_forced_y_max(p_pane_idx)
			else:
				var final_range := _finalize_y_axis_domain(y_axis_domain)
				y_axis_domain.min_val = final_range.x
				y_axis_domain.max_val = final_range.y

			_compute_recompute_thresholds(y_axis_domain)
			pane_domain.y_axis_domains[y_axis_id] = y_axis_domain

		pane_y_domains[p_pane_idx] = pane_domain


	func _finalize_y_axis_domain(y_axis_domain: AxisDomain) -> Vector2:
		var y_min := y_axis_domain.min_val
		var y_max := y_axis_domain.max_val

		var range_overridden := y_axis_domain.config.range_override_enabled
		var include_zero := y_axis_domain.config.include_zero_in_domain

		# Range override takes priority
		if range_overridden:
			y_min = y_axis_domain.config.min_override
			y_max = y_axis_domain.config.max_override
		else:
			# Empty axis => provide default domain
			if is_inf(y_min) or is_inf(y_max):
				if y_axis_domain.config.scale == TauAxisConfig.Scale.LOGARITHMIC:
					y_min = 0.1
					y_max = 10.0
				else:
					y_min = 0.0
					y_max = 1.0
			else:
				match y_axis_domain.config.scale:
					TauAxisConfig.Scale.LINEAR:
						if include_zero:
							var with_zero := _include_zero_in_range(y_min, y_max)
							y_min = with_zero.x
							y_max = with_zero.y

					TauAxisConfig.Scale.LOGARITHMIC:
						pass

					_:
						push_error("Unexpected axis scale %d" % y_axis_domain.config.scale)

				# Apply domain padding from TauAxisConfig.
				var padded := _apply_domain_padding(y_min, y_max, y_axis_domain.config, true)
				y_min = padded.x
				y_max = padded.y


		return _ensure_non_degenerate_range(y_min, y_max, y_axis_domain.config.scale)


	func _ensure_non_degenerate_range(p_min: float, p_max: float, p_scale: TauAxisConfig.Scale = TauAxisConfig.Scale.LINEAR) -> Vector2:
		const DEGENERATE_LOG_EXPAND := 1.1

		var min_v := p_min
		var max_v := p_max

		if is_inf(min_v) or is_inf(max_v) or is_nan(min_v) or is_nan(max_v):
			if p_scale == TauAxisConfig.Scale.LOGARITHMIC:
				return Vector2(0.1, 10.0)
			return Vector2(0.0, 1.0)

		match p_scale:
			TauAxisConfig.Scale.LOGARITHMIC:
				if is_equal_approx(min_v, max_v):
					# Degenerate: expand multiplicatively
					min_v /= DEGENERATE_LOG_EXPAND
					max_v *= DEGENERATE_LOG_EXPAND
				elif max_v / min_v < _LOG_MIN_DOMAIN_RATIO:
					var geometric_mean := sqrt(min_v * max_v)
					var half_ratio := sqrt(_LOG_MIN_DOMAIN_RATIO)
					if geometric_mean / half_ratio > 0.0:
						min_v = geometric_mean / half_ratio
						max_v = geometric_mean * half_ratio
				return Vector2(min_v, max_v)

			TauAxisConfig.Scale.LINEAR:
				# Degenerate: min == max
				if is_equal_approx(min_v, max_v):
					var v := min_v
					var expand := max(abs(v) * _RELATIVE_EXPAND_FRACTION, _MIN_ABSOLUTE_EXPAND)
					min_v = v - expand
					max_v = v + expand

				return Vector2(min_v, max_v)

			_:
				push_error("Unexpected scale %d" % p_scale)
				return Vector2(min_v, max_v)


	func _get_categories(p_dataset: Dataset) -> PackedStringArray:
		var categories := PackedStringArray()
		var n := p_dataset.get_shared_sample_count()
		for i in range(n):
			categories.push_back(String(p_dataset.get_shared_x(i)))
		return categories


	func _is_y_range_forced(p_pane_index: int, p_y_axis_id: AxisId) -> bool:
		if overrides == null:
			return false
		if p_pane_index < 0 or p_pane_index >= overrides.y_domain_overrides.size():
			return false
		var ydo := overrides.y_domain_overrides[p_pane_index]
		return ydo.force_y_range and ydo.target_y_axis_id == p_y_axis_id


	func _get_forced_y_min(p_pane_index: int) -> float:
		if overrides == null:
			return 0.0
		if p_pane_index < 0 or p_pane_index >= overrides.y_domain_overrides.size():
			return 0.0
		return overrides.y_domain_overrides[p_pane_index].force_y_min


	func _get_forced_y_max(p_pane_index: int) -> float:
		if overrides == null:
			return 1.0
		if p_pane_index < 0 or p_pane_index >= overrides.y_domain_overrides.size():
			return 1.0
		return overrides.y_domain_overrides[p_pane_index].force_y_max


	func _must_stack_y_values(p_pane_index: int, p_y_axis_id: AxisId) -> bool:
		if overrides == null:
			return false
		if p_pane_index < 0 or p_pane_index >= overrides.y_domain_overrides.size():
			return false
		var ydo := overrides.y_domain_overrides[p_pane_index]
		return ydo.stack_y_values and ydo.target_y_axis_id == p_y_axis_id


	func _scan_series_y_range(p_dataset: Dataset, p_y_axis_series_ids: PackedInt64Array, p_pane_idx: int, p_y_axis_id: AxisId, p_is_log: bool) -> Vector2:
		var y_min := INF
		var y_max := -INF

		match p_dataset.get_mode():
			Dataset.Mode.SHARED_X:
				for series_id in p_y_axis_series_ids:
					if not p_dataset.has_series(series_id):
						continue

					if _must_stack_y_values(p_pane_idx, p_y_axis_id):
						return _scan_stacked_series_y_range(p_dataset, p_y_axis_series_ids, p_is_log)

					var sample_count := p_dataset.get_shared_sample_count()
					for sample_index in range(sample_count):
						var y_value := p_dataset.get_series_y(series_id, sample_index)
						if is_nan(y_value) or is_inf(y_value):
							continue
						if p_is_log and y_value <= 0.0:
							continue
						y_min = minf(y_min, y_value)
						y_max = maxf(y_max, y_value)

			Dataset.Mode.PER_SERIES_X:
				for series_id in p_y_axis_series_ids:
					if not p_dataset.has_series(series_id):
						continue

					var sample_count := p_dataset.get_series_sample_count(series_id)
					for sample_index in range(sample_count):
						var y_value := p_dataset.get_series_y(series_id, sample_index)
						if is_nan(y_value) or is_inf(y_value):
							continue
						if p_is_log and y_value <= 0.0:
							continue
						y_min = minf(y_min, y_value)
						y_max = maxf(y_max, y_value)

		return Vector2(y_min, y_max)


	func _scan_stacked_series_y_range(p_dataset: Dataset, p_y_axis_series_ids: PackedInt64Array, p_is_log: bool) -> Vector2:
		var y_min := INF
		var y_max := -INF
		var sample_count := p_dataset.get_shared_sample_count()

		for sample_index in range(sample_count):
			var sum := 0.0
			for series_id in p_y_axis_series_ids:
				if not p_dataset.has_series(series_id):
					continue

				var y_value := p_dataset.get_series_y(series_id, sample_index)
				if is_nan(y_value) or is_inf(y_value):
					continue
				if p_is_log and y_value <= 0.0:
					continue
				sum += y_value
			y_min = minf(y_min, sum)
			y_max = maxf(y_max, sum)

		return Vector2(y_min, y_max)


	func _compute_continuous_shared_x(p_dataset: Dataset, p_is_log: bool) -> Vector2:
		var xmin := INF
		var xmax := -INF
		var sample_count := p_dataset.get_shared_sample_count()
		for sample_index in range(sample_count):
			var x_value := float(p_dataset.get_shared_x(sample_index))
			if is_nan(x_value) or is_inf(x_value):
				continue
			if p_is_log and x_value <= 0.0:
				continue
			xmin = minf(xmin, x_value)
			xmax = maxf(xmax, x_value)
		return Vector2(xmin, xmax)


	func _compute_continuous_per_series_x(p_dataset: Dataset, p_series_ids: PackedInt64Array, p_is_log: bool) -> Vector2:
		var xmin := INF
		var xmax := -INF
		for series_id_v in p_series_ids:
			var series_id := series_id_v
			if not p_dataset.has_series(series_id):
				continue
			var sample_count := p_dataset.get_series_sample_count(series_id)
			for sample_index in range(sample_count):
				var x_value := float(p_dataset.get_series_x(series_id, sample_index))
				if is_nan(x_value) or is_inf(x_value):
					continue
				if p_is_log and x_value <= 0.0:
					continue
				xmin = minf(xmin, x_value)
				xmax = maxf(xmax, x_value)
		return Vector2(xmin, xmax)


	func _align_y_axes_at_zero_for_pane(p_y_domain_a: AxisDomain, p_y_domain_b: AxisDomain, p_lock_a: bool = false, p_lock_b: bool = false) -> void:
		if not _range_contains_zero(p_y_domain_a.min_val, p_y_domain_a.max_val) or not _range_contains_zero(p_y_domain_b.min_val, p_y_domain_b.max_val):
			return

		var span_a := p_y_domain_a.max_val - p_y_domain_a.min_val
		var span_b := p_y_domain_b.max_val - p_y_domain_b.min_val
		if span_a <= 0.0 or span_b <= 0.0:
			return

		var ta := (0.0 - p_y_domain_a.min_val) / span_a
		var tb := (0.0 - p_y_domain_b.min_val) / span_b
		if is_equal_approx(ta, tb):
			return

		# When one domain is locked we can only adjust the other one.
		if p_lock_a and p_lock_b:
			return

		if p_lock_a:
			# A is fixed, adjust B to match A's zero position.
			var adj_b := _compute_range_for_zero_position(ta, p_y_domain_b.min_val, p_y_domain_b.max_val)
			if adj_b.x != INF:
				p_y_domain_b.min_val = adj_b.x
				p_y_domain_b.max_val = adj_b.y
			return

		if p_lock_b:
			# B is fixed, adjust A to match B's zero position.
			var adj_a := _compute_range_for_zero_position(tb, p_y_domain_a.min_val, p_y_domain_a.max_val)
			if adj_a.x != INF:
				p_y_domain_a.min_val = adj_a.x
				p_y_domain_a.max_val = adj_a.y
			return

		# Neither is locked. Pick the adjustment that expands the domain the least.
		var adj_a := _compute_range_for_zero_position(tb, p_y_domain_a.min_val, p_y_domain_a.max_val)
		var adj_b := _compute_range_for_zero_position(ta, p_y_domain_b.min_val, p_y_domain_b.max_val)

		if adj_a.x == INF and adj_b.x == INF:
			return

		if adj_a.x == INF:
			p_y_domain_b.min_val = adj_b.x
			p_y_domain_b.max_val = adj_b.y
			return

		if adj_b.x == INF:
			p_y_domain_a.min_val = adj_a.x
			p_y_domain_a.max_val = adj_a.y
			return

		var extra_a := (adj_a.y - adj_a.x) - (p_y_domain_a.max_val - p_y_domain_a.min_val)
		var extra_b := (adj_b.y - adj_b.x) - (p_y_domain_b.max_val - p_y_domain_b.min_val)

		# Tie-breaker: keep first domain stable when costs are equal.
		if extra_b < extra_a:
			p_y_domain_b.min_val = adj_b.x
			p_y_domain_b.max_val = adj_b.y
		else:
			p_y_domain_a.min_val = adj_a.x
			p_y_domain_a.max_val = adj_a.y


	func _include_zero_in_range(p_min: float, p_max: float) -> Vector2:
		var min_v := p_min
		var max_v := p_max
		if min_v > 0.0:
			min_v = 0.0
		if max_v < 0.0:
			max_v = 0.0
		return Vector2(min_v, max_v)


	func _range_contains_zero(p_min: float, p_max: float) -> bool:
		return p_min <= 0.0 and p_max >= 0.0


	func _compute_range_for_zero_position(p_t: float, p_min: float, p_max: float) -> Vector2:
		# Returns an expanded range [new_min, new_max] (never shrinks p_min/p_max)
		# such that 0 maps to normalized position p_t within that range:
		#   p_t = (0 - new_min) / (new_max - new_min)
		# Returns Vector2(INF, INF) on failure.

		var span := p_max - p_min
		if span <= 0.0:
			return Vector2(INF, INF)

		if not _range_contains_zero(p_min, p_max):
			return Vector2(INF, INF)

		# Handle boundary targets exactly.
		if is_equal_approx(p_t, 0.0):
			if is_equal_approx(p_min, 0.0):
				return Vector2(p_min, p_max)
			return Vector2(INF, INF)

		if is_equal_approx(p_t, 1.0):
			if is_equal_approx(p_max, 0.0):
				return Vector2(p_min, p_max)
			return Vector2(INF, INF)

		# Avoid division by zero for values extremely close to 0 or 1.
		var eps := 1e-12
		if p_t <= eps or p_t >= 1.0 - eps:
			return Vector2(INF, INF)

		var required_below := max(-p_min, 0.0)
		var required_above := max(p_max, 0.0)

		var s0: float = required_below / p_t
		var s1: float = required_above / (1.0 - p_t)
		var s := max(s0, s1)

		if s <= 0.0 or is_inf(s) or is_nan(s):
			return Vector2(INF, INF)

		var new_min: float = -p_t * s
		var new_max: float = (1.0 - p_t) * s
		return Vector2(new_min, new_max)


	# Resolves AUTO domain padding mode into a concrete (mode, pad_min, pad_max).
	# Returns Vector3(resolved_mode, resolved_pad_min, resolved_pad_max).
	#
	# Rules for Y axes:
	#   - Linear + include_zero_in_domain => FRACTION, pad_min=0.0, pad_max=0.05
	#   - Linear + not include_zero       => FRACTION, pad_min=0.05, pad_max=0.05
	#   - Logarithmic                     => FRACTION, pad_min=0.05, pad_max=0.05
	#
	# Rules for X axes:
	#   - Always => FRACTION, pad_min=0.05, pad_max=0.05
	#
	# On Y axes the deciding factor is include_zero_in_domain: when the domain
	# was expanded to include zero, padding on the zero side would push the
	# visible range below zero, wasting space.
	# Logarithmic axes always have include_zero disabled (enforced elsewhere),
	# so they always get symmetric padding.
	static func _resolve_auto_padding(p_axis_cfg: TauAxisConfig, p_is_y_axis: bool) -> Vector3:
		const DEFAULT_PAD := 0.05

		if p_is_y_axis and p_axis_cfg.scale == TauAxisConfig.Scale.LINEAR and p_axis_cfg.include_zero_in_domain:
			return Vector3(TauAxisConfig.DomainPaddingMode.FRACTION, 0.0, DEFAULT_PAD)

		return Vector3(TauAxisConfig.DomainPaddingMode.FRACTION, DEFAULT_PAD, DEFAULT_PAD)


	# Applies domain padding to a data range.
	# Returns Vector2(padded_min, padded_max).
	# When the mode is AUTO, it is resolved first via _resolve_auto_padding.
	# p_is_y_axis controls which AUTO rules apply (X vs Y).
	static func _apply_domain_padding(p_min: float, p_max: float, p_axis_cfg: TauAxisConfig, p_is_y_axis: bool) -> Vector2:
		var mode := p_axis_cfg.domain_padding_mode
		var pad_min := maxf(p_axis_cfg.domain_padding_min, 0.0)
		var pad_max := maxf(p_axis_cfg.domain_padding_max, 0.0)

		if mode == TauAxisConfig.DomainPaddingMode.AUTO:
			var resolved := _resolve_auto_padding(p_axis_cfg, p_is_y_axis)
			mode = int(resolved.x) as TauAxisConfig.DomainPaddingMode
			pad_min = resolved.y
			pad_max = resolved.z

		if mode == TauAxisConfig.DomainPaddingMode.NONE:
			return Vector2(p_min, p_max)

		var is_log := (p_axis_cfg.scale == TauAxisConfig.Scale.LOGARITHMIC)

		match mode:
			TauAxisConfig.DomainPaddingMode.FRACTION:
				if is_log:
					if p_min <= 0.0 or p_max <= 0.0:
						return Vector2(p_min, p_max)
					var log_min := log(p_min)
					var log_max := log(p_max)
					var log_span := log_max - log_min
					return Vector2(exp(log_min - pad_min * log_span), exp(log_max + pad_max * log_span))
				else:
					var span := p_max - p_min
					return Vector2(p_min - pad_min * span, p_max + pad_max * span)

			TauAxisConfig.DomainPaddingMode.DATA_UNITS:
				if is_log:
					# Additive in data space for log axes.
					var new_min := p_min - pad_min
					if new_min <= 0.0:
						new_min = p_min * 0.1  # Fallback: keep positive.
					return Vector2(new_min, p_max + pad_max)
				else:
					return Vector2(p_min - pad_min, p_max + pad_max)

			_:
				return Vector2(p_min, p_max)


	# Computes recompute thresholds on an AxisDomain.
	# The threshold sits at the midpoint between raw data bounds and padded
	# domain bounds. Half the padding absorbs incoming data without triggering
	# a recompute, the other half stays as visual headroom.
	static func _compute_recompute_thresholds(p_domain: AxisDomain) -> void:
		const FRACTION := 0.5
		p_domain.recompute_min = p_domain.min_val + FRACTION * (p_domain.data_min - p_domain.min_val)
		p_domain.recompute_max = p_domain.max_val - FRACTION * (p_domain.max_val - p_domain.data_max)
