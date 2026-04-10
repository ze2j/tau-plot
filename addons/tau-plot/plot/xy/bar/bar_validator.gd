# Dependencies
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
const Axis = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis
const BarVisualAttributes = preload("res://addons/tau-plot/plot/xy/bar/bar_visual_attributes.gd").BarVisualAttributes
const BarVisualCallbacks = preload("res://addons/tau-plot/plot/xy/bar/bar_visual_callbacks.gd").BarVisualCallbacks
const ValidationResult = preload("res://addons/tau-plot/plot/validation_result.gd").ValidationResult


## Validates that the bar overlay configuration for a single pane is internally
## consistent: bar mode, width policy, visual types, and stacking constraints.
##
## This validator checks configuration only, not dataset values (sample data,
## sign of values, etc.). The dataset is mutable after plot_xy() is called, so
## runtime data issues are handled elsewhere.
##
## All errors are accumulated into the provided [ValidationResult].
class BarValidator extends RefCounted:

	static func validate(p_dataset: Dataset, p_domain_cfg: TauXYConfig, p_pane_index: int, p_bar_overlay_bindings: Array[TauXYSeriesBinding], p_result: ValidationResult) -> void:
		if p_dataset == null:
			p_result.add_error("BarValidator: p_dataset is null")
			return
		if p_domain_cfg == null:
			p_result.add_error("BarValidator: p_domain_cfg is null")
			return
		if p_pane_index < 0 or p_pane_index >= p_domain_cfg.panes.size():
			p_result.add_error("BarValidator: p_pane_index %d is out of range" % p_pane_index)
			return
		for binding in p_bar_overlay_bindings:
			if binding.pane_index != p_pane_index:
				p_result.add_error("BarValidator: binding has pane_index %d, expected %d" % [binding.pane_index, p_pane_index])
				return
			if binding.overlay_type != PaneOverlayType.BAR:
				p_result.add_error("BarValidator: binding has overlay_type %d, expected BAR" % int(binding.overlay_type))
				return

		var pane_cfg := p_domain_cfg.panes[p_pane_index]
		if pane_cfg == null:
			p_result.add_error("BarValidator: pane %d: pane config is null" % p_pane_index)
			return

		var bar_config := pane_cfg.get_overlay_config(PaneOverlayType.BAR) as TauBarConfig
		if bar_config == null:
			p_result.add_error("BarValidator: pane %d: no TauBarConfig found in pane overlays" % p_pane_index)
			return

		_validate_bar_visuals(p_pane_index, bar_config, p_bar_overlay_bindings, p_result)

		var is_shared_x := (p_dataset.get_mode() == Dataset.Mode.SHARED_X)
		_validate_bar_mode_constraints(p_pane_index, bar_config.mode, pane_cfg, p_bar_overlay_bindings, is_shared_x, p_result)

		var x_cfg := p_domain_cfg.x_axis
		if x_cfg != null:
			_validate_bar_width_config(p_pane_index, x_cfg, bar_config, p_result)


	####################################################################################################
	# Private
	####################################################################################################

	static func _validate_bar_visuals(p_pane_index: int, p_bar_config: TauPaneOverlayConfig, p_bar_overlay_bindings: Array[TauXYSeriesBinding], p_result: ValidationResult) -> void:
		if p_bar_config.visual_callbacks != null and p_bar_config.visual_callbacks is not BarVisualCallbacks:
			p_result.add_error("BarValidator: pane %d: visual_callbacks is not a BarVisualCallbacks" % p_pane_index)

		for i in range(0, p_bar_overlay_bindings.size()):
			var binding: TauXYSeriesBinding = p_bar_overlay_bindings[i]
			if binding.visual_attributes != null and binding.visual_attributes is not BarVisualAttributes:
				p_result.add_error("BarValidator: pane %d: series_id %d has visual_attributes that is not a BarVisualAttributes" % [p_pane_index, binding.series_id])


	static func _validate_bar_mode_constraints(p_pane_index: int, p_bar_mode: TauBarConfig.BarMode, p_pane_cfg: TauPaneConfig, p_bar_overlay_bindings: Array[TauXYSeriesBinding], p_is_shared_x: bool, p_result: ValidationResult) -> void:
		match p_bar_mode:
			TauBarConfig.BarMode.GROUPED:
				if not p_is_shared_x:
					p_result.add_error("BarValidator: pane %d: GROUPED mode requires SHARED_X dataset mode" % p_pane_index)

			TauBarConfig.BarMode.STACKED:
				if not p_is_shared_x:
					p_result.add_error("BarValidator: pane %d: STACKED mode requires SHARED_X dataset mode" % p_pane_index)

				if not p_bar_overlay_bindings.is_empty():
					# All stacked bar series must share the same y axis.
					var first_y_axis_id := p_bar_overlay_bindings[0].y_axis_id
					for i in range(1, p_bar_overlay_bindings.size()):
						var binding: TauXYSeriesBinding = p_bar_overlay_bindings[i]
						if binding.y_axis_id != first_y_axis_id:
							p_result.add_error("BarValidator: pane %d: STACKED mode requires all bar series on the same y axis, but series_id %d uses %s (expected %s)" % [p_pane_index, binding.series_id, Axis.as_string(binding.y_axis_id), Axis.as_string(first_y_axis_id)])

					var y_axis_config: TauAxisConfig = p_pane_cfg.get_y_axis_config(first_y_axis_id)
					if y_axis_config != null and y_axis_config.scale == TauAxisConfig.Scale.LOGARITHMIC:
						p_result.add_error("BarValidator: pane %d: STACKED mode is incompatible with logarithmic y axis" % p_pane_index)

			TauBarConfig.BarMode.INDEPENDENT:
				pass  # No mode-specific constraints

			_:
				p_result.add_error("BarValidator: pane %d: unsupported bar mode %d" % [p_pane_index, int(p_bar_mode)])


	static func _validate_bar_width_config(p_pane_index: int, p_x_axis_cfg: TauAxisConfig, p_bar_config: TauBarConfig, p_result: ValidationResult) -> void:
		var resolved_policy := p_bar_config.get_resolved_bar_width_policy(p_x_axis_cfg.type)

		_validate_bar_width_policy(p_pane_index, p_x_axis_cfg.type, resolved_policy, p_result)
		_validate_bar_width_policy_params(p_pane_index, p_x_axis_cfg.scale, resolved_policy, p_bar_config, p_result)


	static func _validate_bar_width_policy(p_pane_index: int, p_x_axis_type: TauAxisConfig.Type, p_policy: TauBarConfig.BarWidthPolicy, p_result: ValidationResult) -> void:
		match p_x_axis_type:
			TauAxisConfig.Type.CATEGORICAL:
				match p_policy:
					TauBarConfig.BarWidthPolicy.THEME, TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION:
						pass
					_:
						p_result.add_error("BarValidator: pane %d: bar_width_policy %d is not allowed for CATEGORICAL x-axis" % [p_pane_index, int(p_policy)])

			TauAxisConfig.Type.CONTINUOUS:
				match p_policy:
					TauBarConfig.BarWidthPolicy.THEME, TauBarConfig.BarWidthPolicy.DATA_UNITS, TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION:
						pass
					_:
						p_result.add_error("BarValidator: pane %d: bar_width_policy %d is not allowed for CONTINUOUS x-axis" % [p_pane_index, int(p_policy)])

			_:
				p_result.add_error("BarValidator: pane %d: unexpected x-axis type %d" % [p_pane_index, int(p_x_axis_type)])


	static func _validate_bar_width_policy_params(p_pane_index: int, p_x_axis_scale: TauAxisConfig.Scale, p_policy: TauBarConfig.BarWidthPolicy, p_bar_config: TauBarConfig, p_result: ValidationResult) -> void:
		match p_policy:
			TauBarConfig.BarWidthPolicy.THEME:
				pass

			TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION:
				if p_bar_config.category_width_fraction <= 0.0 or p_bar_config.category_width_fraction > 1.0:
					p_result.add_error("BarValidator: pane %d: category_width_fraction must be in ]0, 1]" % p_pane_index)

				if p_bar_config.mode == TauBarConfig.BarMode.GROUPED:
					if p_bar_config.intra_group_gap_fraction < 0.0 or p_bar_config.intra_group_gap_fraction > 1.0:
						p_result.add_error("BarValidator: pane %d: intra_group_gap_fraction must be in [0, 1]" % p_pane_index)

			TauBarConfig.BarWidthPolicy.DATA_UNITS:
				if p_x_axis_scale == TauAxisConfig.Scale.LOGARITHMIC:
					if p_bar_config.bar_width_log_factor < 1.0:
						p_result.add_error("BarValidator: pane %d: bar_width_log_factor must be >= 1 (got %f)" % [p_pane_index, p_bar_config.bar_width_log_factor])

					if p_bar_config.mode == TauBarConfig.BarMode.GROUPED:
						if p_bar_config.bar_gap_log_factor < 1.0:
							p_result.add_error("BarValidator: pane %d: bar_gap_log_factor must be >= 1 (got %f)" % [p_pane_index, p_bar_config.bar_gap_log_factor])
				else:
					if p_bar_config.bar_width_x_units < 0.0:
						p_result.add_error("BarValidator: pane %d: bar_width_x_units must be >= 0 (got %f)" % [p_pane_index, p_bar_config.bar_width_x_units])

					if p_bar_config.mode == TauBarConfig.BarMode.GROUPED:
						if p_bar_config.bar_gap_x_units < 0.0:
							p_result.add_error("BarValidator: pane %d: bar_gap_x_units must be >= 0 (got %f)" % [p_pane_index, p_bar_config.bar_gap_x_units])

			TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION:
				if p_bar_config.neighbor_spacing_fraction < 0.0 or p_bar_config.neighbor_spacing_fraction > 1.0:
					p_result.add_error("BarValidator: pane %d: neighbor_spacing_fraction must be in [0, 1]" % p_pane_index)

				if p_bar_config.mode == TauBarConfig.BarMode.GROUPED:
					if p_bar_config.neighbor_gap_fraction < 0.0:
						p_result.add_error("BarValidator: pane %d: neighbor_gap_fraction must be >= 0 (got %f)" % [p_pane_index, p_bar_config.neighbor_gap_fraction])

			_:
				p_result.add_error("BarValidator: pane %d: unsupported bar_width_policy %d" % [p_pane_index, int(p_policy)])
