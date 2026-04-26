# Dependencies
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const BarValidator := preload("res://addons/tau-plot/plot/xy/bar/bar_validator.gd").BarValidator
const ScatterValidator := preload("res://addons/tau-plot/plot/xy/scatter/scatter_validator.gd").ScatterValidator
const Axis = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis
const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const ValidationResult = preload("res://addons/tau-plot/plot/validation_result.gd").ValidationResult

## Validates that the configuration passed to plot_xy() is internally consistent.
##
## This validator checks the structural integrity of the configuration graph:
## dataset mode and element type, axis types, pane references, series bindings,
## and renderer-specific constraints. It does NOT validate dataset values (sample
## data, counts of points, sign of values, etc.) because the dataset is mutable
## after plot_xy() is called. Runtime data issues are handled elsewhere.
##
## All errors and warnings are accumulated into a [ValidationResult] instead of
## calling push_error/push_warning directly. The caller decides how to report.
##
## Validation is organized in phases. Within a phase, all checks run and errors
## accumulate. Between phases, validation stops if the previous phase produced
## any errors, so that later phases can safely assume earlier invariants hold.
class XYPlotValidator extends RefCounted:

	static func validate(p_dataset: Dataset, p_xy_config: TauXYConfig, p_series_bindings: Array[TauXYSeriesBinding], p_result: ValidationResult) -> bool:

		# -- Null guards --
		# These must pass before anything else can be checked safely.
		_validate_null_guards(p_dataset, p_xy_config, p_series_bindings, p_result)
		if p_result.has_errors():
			return false

		# -- Dataset structure and axis config --
		# Validates that the dataset mode and element type are compatible with
		# the x-axis configuration. These are structural properties of the
		# dataset set at creation time, not mutable sample data.
		_validate_dataset_structure(p_dataset, p_xy_config, p_result)
		_validate_secondary_x_axis(p_xy_config, p_result)
		_validate_pane_configs(p_xy_config, p_result)
		_validate_axis_range_overrides(p_xy_config, p_result)
		if p_result.has_errors():
			return false

		# -- Binding consistency --
		# Validates that all series bindings reference existing entities (series
		# IDs in dataset, pane indices, axis slots) and that no binding conflicts
		# exist (e.g. same series on two y axes in one pane).
		_validate_bindings(p_dataset, p_xy_config, p_series_bindings, p_result)
		if p_result.has_errors():
			return false

		# -- Renderer-specific constraints --
		# Delegates to BarValidator, ScatterValidator, etc. for overlay-specific
		# checks (bar width policy, stacked bar y-axis, marker size, visual types).
		_validate_renderer_specific_constraints(p_dataset, p_xy_config, p_series_bindings, p_result)
		if p_result.has_errors():
			return false

		# -- Warnings (never stop validation) --
		_collect_warnings(p_xy_config, p_result)

		return true


	####################################################################################################
	# Null guards
	####################################################################################################

	static func _validate_null_guards(p_dataset: Dataset, p_xy_config: TauXYConfig, p_series_bindings: Array[TauXYSeriesBinding], p_result: ValidationResult) -> void:
		if p_dataset == null:
			p_result.add_error("XYPlotValidator: p_dataset is null")
		if p_xy_config == null:
			p_result.add_error("XYPlotValidator: p_xy_config is null")
		if p_series_bindings == null or p_series_bindings.is_empty():
			p_result.add_error("XYPlotValidator: p_series_bindings is empty")
		if p_xy_config != null and p_xy_config.x_axis == null:
			p_result.add_error("XYPlotValidator: TauXYConfig.x_axis is null")


	####################################################################################################
	# Dataset structure
	####################################################################################################

	static func _validate_dataset_structure(p_dataset: Dataset, p_xy_config: TauXYConfig, p_result: ValidationResult) -> void:
		_validate_dataset_x_axis(p_xy_config.x_axis, p_dataset.get_x_element_type(), p_dataset.get_mode() == Dataset.Mode.SHARED_X, p_result)
		_validate_sample_count(p_dataset, p_dataset.get_mode() == Dataset.Mode.SHARED_X, p_result)


	## Validates that the x-axis type is compatible with the dataset element type
	## and mode. These are structural properties of the dataset that do not change
	## after creation, so checking them once at configuration time is appropriate.
	static func _validate_dataset_x_axis(p_x_axis: TauAxisConfig, p_x_element_type: Dataset.XElementType, p_is_shared_x: bool, p_result: ValidationResult) -> void:
		match p_x_axis.type:
			TauAxisConfig.Type.CATEGORICAL:
				if p_x_element_type != Dataset.XElementType.CATEGORY:
					p_result.add_error("XYPlotValidator: x-axis type is CATEGORICAL, but dataset X element type is not CATEGORY")
				if not p_is_shared_x:
					p_result.add_error("XYPlotValidator: CATEGORICAL x-axis requires SHARED_X dataset mode")

			TauAxisConfig.Type.CONTINUOUS:
				if p_x_element_type != Dataset.XElementType.NUMERIC:
					p_result.add_error("XYPlotValidator: x-axis type is CONTINUOUS, but dataset X element type is not NUMERIC")

			_:
				p_result.add_error("XYPlotValidator: unexpected x-axis type %d" % int(p_x_axis.type))


	## Validates that all series have the expected sample count in SHARED_X mode.
	## In SHARED_X mode, every series must have the same number of samples as the
	## shared x vector. This is a dataset invariant (not a per-sample data check)
	## so verifying it once at configuration time is appropriate.
	static func _validate_sample_count(p_dataset: Dataset, p_is_shared_x: bool, p_result: ValidationResult) -> void:
		if not p_is_shared_x:
			return

		var shared_sample_count := p_dataset.get_shared_sample_count()
		for series_index in range(p_dataset.get_series_count()):
			var series_id := p_dataset.get_series_id_by_index(series_index)
			var series_sample_count := p_dataset.get_series_sample_count(series_id)
			if series_sample_count != shared_sample_count:
				p_result.add_error("XYPlotValidator: SHARED_X requires all series to have %d samples, but series_index=%d has %d" % [shared_sample_count, series_index, series_sample_count])


	####################################################################################################
	# Secondary x axis
	####################################################################################################

	## Validates the secondary x axis configuration when present.
	## The secondary x axis is display-only and requires a transform callable
	## to derive its domain from the primary x axis. It must be CONTINUOUS
	## because a transform from primary values to categorical labels is not
	## supported.
	static func _validate_secondary_x_axis(p_xy_config: TauXYConfig, p_result: ValidationResult) -> void:
		var secondary := p_xy_config.secondary_x_axis
		if secondary == null:
			return

		if p_xy_config.secondary_x_axis_transform.is_null():
			p_result.add_error("XYPlotValidator: secondary_x_axis is set but secondary_x_axis_transform is null (a Callable mapping primary x values to secondary x values is required)")

		if secondary.type != TauAxisConfig.Type.CONTINUOUS:
			p_result.add_error("XYPlotValidator: secondary_x_axis.type must be CONTINUOUS (CATEGORICAL secondary x axes are not supported)")


	####################################################################################################
	# Pane configs
	####################################################################################################

	static func _validate_pane_configs(p_xy_config: TauXYConfig, p_result: ValidationResult) -> void:
		if p_xy_config.panes.is_empty():
			p_result.add_error("XYPlotValidator: TauXYConfig.panes is empty")


	####################################################################################################
	# Axis range overrides
	####################################################################################################

	## Validates that when an axis has range_override_enabled, the override bounds form a valid range.
	static func _validate_axis_range_overrides(p_xy_config: TauXYConfig, p_result: ValidationResult) -> void:
		if p_xy_config.x_axis != null:
			_validate_axis_range_override(p_xy_config.x_axis, "x_axis", p_result)
		if p_xy_config.secondary_x_axis != null:
			_validate_axis_range_override(p_xy_config.secondary_x_axis, "secondary_x_axis", p_result)

		for pane_index in range(p_xy_config.panes.size()):
			var pane: TauPaneConfig = p_xy_config.panes[pane_index]
			if pane == null:
				continue
			if pane.y_bottom_axis != null:
				_validate_axis_range_override(pane.y_bottom_axis, "pane %d y_bottom_axis" % pane_index, p_result)
			if pane.y_top_axis != null:
				_validate_axis_range_override(pane.y_top_axis, "pane %d y_top_axis" % pane_index, p_result)
			if pane.y_left_axis != null:
				_validate_axis_range_override(pane.y_left_axis, "pane %d y_left_axis" % pane_index, p_result)
			if pane.y_right_axis != null:
				_validate_axis_range_override(pane.y_right_axis, "pane %d y_right_axis" % pane_index, p_result)


	static func _validate_axis_range_override(p_axis: TauAxisConfig, p_axis_label: String, p_result: ValidationResult) -> void:
		if not p_axis.range_override_enabled:
			return

		var min_v := p_axis.min_override
		var max_v := p_axis.max_override

		if min_v > max_v:
			p_result.add_error("XYPlotValidator: %s has range_override_enabled with min_override (%f) > max_override (%f)" % [p_axis_label, min_v, max_v])

		if p_axis.scale == TauAxisConfig.Scale.LOGARITHMIC:
			if min_v <= 0.0:
				p_result.add_error("XYPlotValidator: %s is LOGARITHMIC but min_override (%f) is not strictly positive" % [p_axis_label, min_v])
			if max_v <= 0.0:
				p_result.add_error("XYPlotValidator: %s is LOGARITHMIC but max_override (%f) is not strictly positive" % [p_axis_label, max_v])


	####################################################################################################
	# Binding consistency
	####################################################################################################

	static func _validate_bindings(p_dataset: Dataset, p_xy_config: TauXYConfig, p_series_bindings: Array[TauXYSeriesBinding], p_result: ValidationResult) -> void:
		var series_count := p_dataset.get_series_count()
		var dataset_series_ids := {}
		for i in range(series_count):
			var series_id := p_dataset.get_series_id_by_index(i)
			dataset_series_ids[series_id] = true

		var pane_count := p_xy_config.panes.size()

		# Track (pane_index, series_id) -> first y_axis_id, for duplicate y-axis detection.
		var seen_y_axis: Dictionary = {}
		# Track (pane_index, overlay_type, series_id) for duplicate binding detection.
		var seen_overlay_binding: Dictionary = {}

		for i in range(p_series_bindings.size()):
			var binding: TauXYSeriesBinding = p_series_bindings[i]

			# Series exists in dataset
			if not dataset_series_ids.has(binding.series_id):
				p_result.add_error("XYPlotValidator: p_series_bindings[%d] references non-existent series_id %d" % [i, binding.series_id])
				continue

			# Pane index in range
			if binding.pane_index < 0 or binding.pane_index >= pane_count:
				p_result.add_error("XYPlotValidator: p_series_bindings[%d] (series_id %d) references pane_index %d, but only %d pane(s) configured" % [i, binding.series_id, binding.pane_index, pane_count])
				continue

			var pane_cfg: TauPaneConfig = p_xy_config.panes[binding.pane_index]
			if pane_cfg == null:
				p_result.add_error("XYPlotValidator: p_series_bindings[%d] (series_id %d) references pane_index %d, but that pane is null" % [i, binding.series_id, binding.pane_index])
				continue

			# Y axis orthogonal to x axis
			if not Axis.are_orthogonal(p_xy_config.x_axis_id, binding.y_axis_id):
				p_result.add_error("XYPlotValidator: p_series_bindings[%d] (series_id %d) y_axis_id %s is not orthogonal to x_axis_id %s" % [i, binding.series_id, Axis.as_string(binding.y_axis_id), Axis.as_string(p_xy_config.x_axis_id)])

			# Y axis slot exists in pane
			var axis_cfg: TauAxisConfig = pane_cfg.get_y_axis_config(binding.y_axis_id)
			if axis_cfg == null:
				p_result.add_error("XYPlotValidator: p_series_bindings[%d] (series_id %d) references y axis %s, but pane %d has no axis configured there" % [i, binding.series_id, Axis.as_string(binding.y_axis_id), binding.pane_index])

			# Same series must not be bound to two distinct y axes in the same pane
			var pane_series_key := "%d:%d" % [binding.pane_index, binding.series_id]
			if seen_y_axis.has(pane_series_key):
				var prev_axis_id = seen_y_axis[pane_series_key]
				if prev_axis_id != binding.y_axis_id:
					p_result.add_error("XYPlotValidator: series_id %d in pane %d is bound to two distinct y axes (%s and %s)" % [binding.series_id, binding.pane_index, Axis.as_string(prev_axis_id), Axis.as_string(binding.y_axis_id)])
			else:
				seen_y_axis[pane_series_key] = binding.y_axis_id

			# Same series must not appear twice in the same overlay in the same pane
			var overlay_key := "%d:%d:%d" % [binding.pane_index, int(binding.overlay_type), binding.series_id]
			if seen_overlay_binding.has(overlay_key):
				p_result.add_error("XYPlotValidator: series_id %d appears more than once in overlay_type %d of pane %d" % [binding.series_id, int(binding.overlay_type), binding.pane_index])
			else:
				seen_overlay_binding[overlay_key] = true


	####################################################################################################
	# Renderer-specific constraints
	####################################################################################################

	static func _validate_renderer_specific_constraints(p_dataset: Dataset, p_xy_config: TauXYConfig, p_series_bindings: Array[TauXYSeriesBinding], p_result: ValidationResult) -> void:
		# Group series by overlay type and pane
		var bar_bindings_by_pane: Dictionary[int, Array] = {}   # Array[TauXYSeriesBinding]. FIXME Godot 4.5 does not support nested typed collections.
		var scatter_bindings_by_pane: Dictionary[int, Array] = {} # Array[TauXYSeriesBinding]. FIXME Godot 4.5 does not support nested typed collections.

		for binding in p_series_bindings:
			match binding.overlay_type:
				TauXYSeriesBinding.PaneOverlayType.BAR:
					if not bar_bindings_by_pane.has(binding.pane_index):
						bar_bindings_by_pane[binding.pane_index] = []
					bar_bindings_by_pane[binding.pane_index].append(binding)
				TauXYSeriesBinding.PaneOverlayType.SCATTER:
					if not scatter_bindings_by_pane.has(binding.pane_index):
						scatter_bindings_by_pane[binding.pane_index] = []
					scatter_bindings_by_pane[binding.pane_index].append(binding)
				_:
					p_result.add_error("XYPlotValidator: unsupported overlay_type %d" % int(binding.overlay_type))

		for pane_index in bar_bindings_by_pane:
			var bar_overlay_bindings: Array[TauXYSeriesBinding] = []
			bar_overlay_bindings.assign(bar_bindings_by_pane[pane_index])
			BarValidator.validate(p_dataset, p_xy_config, pane_index, bar_overlay_bindings, p_result)

		for pane_index in scatter_bindings_by_pane:
			var scatter_overlay_bindings: Array[TauXYSeriesBinding] = []
			scatter_overlay_bindings.assign(scatter_bindings_by_pane[pane_index])
			ScatterValidator.validate(p_dataset, p_xy_config, pane_index, scatter_overlay_bindings, p_result)


	####################################################################################################
	# Warnings
	####################################################################################################

	static func _collect_warnings(p_xy_config: TauXYConfig, p_result: ValidationResult) -> void:
		if p_xy_config.x_axis.tick_count_preferred < 2:
			p_result.add_warning("XYPlotValidator: x-axis has tick_count_preferred=%d (will be clamped to 2 internally)" % p_xy_config.x_axis.tick_count_preferred)

		if p_xy_config.secondary_x_axis != null and p_xy_config.secondary_x_axis.tick_count_preferred < 2:
			p_result.add_warning("XYPlotValidator: secondary x-axis has tick_count_preferred=%d (will be clamped to 2 internally)" % p_xy_config.secondary_x_axis.tick_count_preferred)

		for i in range(p_xy_config.panes.size()):
			var pane: TauPaneConfig = p_xy_config.panes[i]

			if pane.y_bottom_axis != null and pane.y_bottom_axis.tick_count_preferred < 2:
				p_result.add_warning("XYPlotValidator: pane %d, y bottom axis has tick_count_preferred=%d (will be clamped to 2 internally)" % [i, pane.y_bottom_axis.tick_count_preferred])
			if pane.y_top_axis != null and pane.y_top_axis.tick_count_preferred < 2:
				p_result.add_warning("XYPlotValidator: pane %d, y top axis has tick_count_preferred=%d (will be clamped to 2 internally)" % [i, pane.y_top_axis.tick_count_preferred])
			if pane.y_left_axis != null and pane.y_left_axis.tick_count_preferred < 2:
				p_result.add_warning("XYPlotValidator: pane %d, y left axis has tick_count_preferred=%d (will be clamped to 2 internally)" % [i, pane.y_left_axis.tick_count_preferred])
			if pane.y_right_axis != null and pane.y_right_axis.tick_count_preferred < 2:
				p_result.add_warning("XYPlotValidator: pane %d, y right axis has tick_count_preferred=%d (will be clamped to 2 internally)" % [i, pane.y_right_axis.tick_count_preferred])
