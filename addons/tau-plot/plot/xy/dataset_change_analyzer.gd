# Analyzes DatasetChange events and classifies them by their impact on the plot pipeline.
#
# This is pure logic with no side effects: it reads the domain, dataset, config, and
# change object to determine whether a full recompute is needed or if shortcuts are possible.
#
# Multi-pane aware: checks all panes for Y bounds and the shared X axis for X bounds.

const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const DatasetChange := preload("res://addons/tau-plot/model/dataset_change.gd").DatasetChange
const XYDomain := preload("res://addons/tau-plot/plot/xy/xy_domain.gd").XYDomain
const PaneYDomains := preload("res://addons/tau-plot/plot/xy/xy_domain.gd").PaneYDomains
const AxisDomain := preload("res://addons/tau-plot/plot/xy/xy_domain.gd").AxisDomain
const XYDomainOverrides := preload("res://addons/tau-plot/plot/xy/xy_domain_overrides.gd").XYDomainOverrides
const YDomainOverride := preload("res://addons/tau-plot/plot/xy/xy_domain_overrides.gd").YDomainOverride
const SeriesAxisAssignment := preload("res://addons/tau-plot/plot/xy/series_axis_assignment.gd").SeriesAxisAssignment
const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId


class DatasetChangeAnalyzer extends RefCounted:

	enum Impact
	{
		NONE,             # Nothing needs updating.
		RENDERERS_ONLY,   # Only bar/scatter renderers need redrawing (domain unchanged).
		FULL_RECOMPUTE    # Domain may have changed: full pipeline recompute needed.
	}


	# Classifies the impact of a dataset change on the plot pipeline.
	static func classify(
		p_change: DatasetChange,
		p_domain: XYDomain,
		p_dataset: Dataset,
		p_xy_config: TauXYConfig,
		p_domain_overrides: XYDomainOverrides,
		p_series_assignment: SeriesAxisAssignment
	) -> Impact:
		var x_changed := (p_change.flags & DatasetChange.Flags.X_CHANGED) != 0
		var y_changed := (p_change.flags & DatasetChange.Flags.Y_CHANGED) != 0
		var structure_changed := (p_change.flags & DatasetChange.Flags.SERIES_STRUCTURE_CHANGED) != 0

		var series_added_or_removed := (
			p_change.type == DatasetChange.Type.SERIES_ADDED or
			p_change.type == DatasetChange.Type.SERIES_REMOVED
		)

		# Optimization 1: Skip domain recomputation for metadata-only changes
		# BUT: series add/remove always needs domain recomputation (might have data)
		if not x_changed and not y_changed and not series_added_or_removed:
			if structure_changed:
				return Impact.RENDERERS_ONLY
			return Impact.NONE

		# Optimization 2: For VALUE_CHANGED and VALUES_APPENDED, check if the new
		# or updated values still fall within the recompute thresholds. If so,
		# there is still enough visual headroom and we can skip a full domain
		# + tick recompute.
		var is_value_only_change := (
			p_change.type == DatasetChange.Type.VALUES_CHANGED or
			p_change.type == DatasetChange.Type.VALUES_APPENDED
		)
		if is_value_only_change and not structure_changed:
			if _can_skip_domain_update(p_change, p_domain, p_dataset, p_xy_config, p_domain_overrides, p_series_assignment, x_changed, y_changed):
				return Impact.RENDERERS_ONLY

		return Impact.FULL_RECOMPUTE


	# Checks whether all updated values fall within the recompute thresholds
	# stored on each AxisDomain. If so, domain and tick recomputations can be skipped.
	static func _can_skip_domain_update(
		p_change: DatasetChange,
		p_domain: XYDomain,
		p_dataset: Dataset,
		p_xy_config: TauXYConfig,
		p_domain_overrides: XYDomainOverrides,
		p_series_assignment: SeriesAxisAssignment,
		p_x_changed: bool,
		p_y_changed: bool
	) -> bool:
		var pane_count := p_domain.get_pane_count()

		# Check X bounds (shared axis)
		if p_x_changed:
			var x_axis_cfg := p_domain.get_x_axis_config()

			# Categorical X axis: X change always needs update
			if x_axis_cfg.type == TauAxisConfig.Type.CATEGORICAL:
				return false

			# Range override: user controls bounds, can skip
			if not x_axis_cfg.range_override_enabled:
				var x_axis_domain := p_domain.x_axis_domain
				for series_id in p_change.series_ids:
					if not _x_values_within_bounds(p_dataset, series_id, p_change, x_axis_domain.recompute_min, x_axis_domain.recompute_max):
						return false

		# Check Y bounds (per-pane, per-series)
		if p_y_changed:
			for series_id in p_change.series_ids:
				for pane_idx in range(pane_count):
					# Resolve the axis this series is assigned to in this pane.
					var y_axis_id: int = p_series_assignment.get_y_axis_id_for_series(series_id, pane_idx)
					if y_axis_id == -1:
						continue  # Series not in this pane.

					var pane_domain: PaneYDomains = p_domain.get_pane_domain(pane_idx)
					var axis_domain: AxisDomain = pane_domain.get_y_axis_domain(y_axis_id)
					if axis_domain == null:
						return false

					# User range override on this axis means the domain is pinned.
					if axis_domain.config != null and axis_domain.config.range_override_enabled:
						continue

					# Bar stacking override (FRACTION/PERCENT) pins the range on the target axis.
					var pane_override: YDomainOverride = p_domain_overrides.y_domain_overrides[pane_idx]
					if pane_override.force_y_range and pane_override.target_y_axis_id == y_axis_id:
						continue

					# include_zero could shift bounds even if the new values are in range.
					if axis_domain.config != null and axis_domain.config.include_zero_in_domain and not _range_contains_zero(axis_domain.min_val, axis_domain.max_val):
						return false

					# Check if the new Y values fit within the recompute thresholds.
					if not _y_values_within_axis_bounds(p_dataset, series_id, p_change, axis_domain):
						return false

		return true


	# Checks if X values for a series fall within the recompute thresholds.
	static func _x_values_within_bounds(
		p_dataset: Dataset,
		p_series_id: int,
		p_change: DatasetChange,
		p_recompute_min: float,
		p_recompute_max: float
	) -> bool:
		var start_idx := p_change.start_index
		var end_idx := p_change.end_index_exclusive

		if p_dataset.get_mode() == Dataset.Mode.SHARED_X:
			for i in range(start_idx, end_idx):
				if i >= p_dataset.get_shared_sample_count():
					break
				var x := float(p_dataset.get_shared_x(i))
				if x < p_recompute_min or x > p_recompute_max:
					return false
		else:
			# PER_SERIES_X: check affected series
			var count := p_dataset.get_series_sample_count(p_series_id)
			for i in range(start_idx, min(end_idx, count)):
				var x := float(p_dataset.get_series_x(p_series_id, i))
				if x < p_recompute_min or x > p_recompute_max:
					return false

		return true


	# Checks if Y values for a series fall within the recompute thresholds of a
	# single axis domain.
	static func _y_values_within_axis_bounds(
		p_dataset: Dataset,
		p_series_id: int,
		p_change: DatasetChange,
		p_axis_domain: AxisDomain
	) -> bool:
		var start_idx := p_change.start_index
		var end_idx := p_change.end_index_exclusive
		var count := p_dataset.get_series_sample_count(p_series_id)

		var effective_end := min(end_idx, count)
		if p_dataset.get_mode() == Dataset.Mode.SHARED_X:
			effective_end = end_idx

		for i in range(start_idx, effective_end):
			if p_dataset.get_mode() == Dataset.Mode.SHARED_X:
				if i >= p_dataset.get_series_sample_count(p_series_id):
					break

			var y := p_dataset.get_series_y(p_series_id, i)
			if y < p_axis_domain.recompute_min or y > p_axis_domain.recompute_max:
				return false

		return true


	static func _range_contains_zero(p_min: float, p_max: float) -> bool:
		return p_min <= 0.0 and p_max >= 0.0
