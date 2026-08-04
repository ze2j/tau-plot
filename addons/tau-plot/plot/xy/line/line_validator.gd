# Dependencies
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
const Axis = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis
const LineVisualAttributes = preload("res://addons/tau-plot/plot/xy/line/line_visual_attributes.gd").LineVisualAttributes
const LineVisualCallbacks = preload("res://addons/tau-plot/plot/xy/line/line_visual_callbacks.gd").LineVisualCallbacks
const ValidationResult = preload("res://addons/tau-plot/plot/validation_result.gd").ValidationResult


## Validates that the line overlay configuration for a single pane is
## internally consistent.
##
## This validator checks configuration only, not dataset values. The dataset
## is mutable after plot_xy() is called, so runtime data issues are handled
## elsewhere.
##
## All errors are accumulated into the provided [ValidationResult].
class LineValidator extends RefCounted:

	static func validate(p_dataset: Dataset, p_domain_cfg: TauXYConfig, p_pane_index: int, p_line_overlay_bindings: Array[TauXYSeriesBinding], p_result: ValidationResult) -> void:
		if p_dataset == null:
			p_result.add_error("LineValidator: p_dataset is null")
			return
		if p_domain_cfg == null:
			p_result.add_error("LineValidator: p_domain_cfg is null")
			return
		if p_pane_index < 0 or p_pane_index >= p_domain_cfg.panes.size():
			p_result.add_error("LineValidator: p_pane_index %d is out of range" % p_pane_index)
			return
		for binding in p_line_overlay_bindings:
			if binding.pane_index != p_pane_index:
				p_result.add_error("LineValidator: binding has pane_index %d, expected %d" % [binding.pane_index, p_pane_index])
				return
			if binding.overlay_type != PaneOverlayType.LINE:
				p_result.add_error("LineValidator: binding has overlay_type %d, expected LINE" % int(binding.overlay_type))
				return

		var pane_cfg := p_domain_cfg.panes[p_pane_index]
		if pane_cfg == null:
			p_result.add_error("LineValidator: pane %d: pane config is null" % p_pane_index)
			return

		var line_config := pane_cfg.get_overlay_config(PaneOverlayType.LINE) as TauLineConfig
		if line_config == null:
			p_result.add_error("LineValidator: pane %d: no TauLineConfig found in pane overlays" % p_pane_index)
			return

		_validate_line_visuals(p_pane_index, line_config, p_line_overlay_bindings, p_result)

		var is_shared_x := (p_dataset.get_mode() == Dataset.Mode.SHARED_X)
		_validate_line_mode_constraints(p_pane_index, line_config, pane_cfg, p_line_overlay_bindings, is_shared_x, p_result)
		_validate_fill_constraints(p_pane_index, line_config, pane_cfg, p_domain_cfg.x_axis, p_line_overlay_bindings, p_result)


	####################################################################################################
	# Private
	####################################################################################################

	static func _validate_line_visuals(p_pane_index: int, p_line_config: TauPaneOverlayConfig, p_line_overlay_bindings: Array[TauXYSeriesBinding], p_result: ValidationResult) -> void:
		if p_line_config.visual_callbacks != null and p_line_config.visual_callbacks is not LineVisualCallbacks:
			p_result.add_error("LineValidator: pane %d: visual_callbacks is not a LineVisualCallbacks" % p_pane_index)

		for i in range(0, p_line_overlay_bindings.size()):
			var binding: TauXYSeriesBinding = p_line_overlay_bindings[i]
			if binding.visual_attributes != null and binding.visual_attributes is not LineVisualAttributes:
				p_result.add_error("LineValidator: pane %d: series_id %d has visual_attributes that is not a LineVisualAttributes" % [p_pane_index, binding.series_id])


	static func _validate_line_mode_constraints(p_pane_index: int, p_line_config: TauLineConfig, p_pane_cfg: TauPaneConfig, p_line_overlay_bindings: Array[TauXYSeriesBinding], p_is_shared_x: bool, p_result: ValidationResult) -> void:
		match p_line_config.mode:
			TauLineConfig.LineMode.INDEPENDENT:
				pass

			TauLineConfig.LineMode.STACKED:
				# STACKED computes a per-X cumulative across series, so all series
				# must share aligned X positions.
				if not p_is_shared_x:
					p_result.add_error("LineValidator: pane %d: STACKED mode requires SHARED_X dataset mode" % p_pane_index)

				if not p_line_overlay_bindings.is_empty():
					# All stacked line series must share the same y axis.
					var first_y_axis_id := p_line_overlay_bindings[0].y_axis_id
					for i in range(1, p_line_overlay_bindings.size()):
						var binding: TauXYSeriesBinding = p_line_overlay_bindings[i]
						if binding.y_axis_id != first_y_axis_id:
							p_result.add_error("LineValidator: pane %d: STACKED mode requires all line series on the same y axis, but series_id %d uses %s (expected %s)" % [p_pane_index, binding.series_id, Axis.as_string(binding.y_axis_id), Axis.as_string(first_y_axis_id)])

					# Cumulative sums on a logarithmic axis are not meaningful.
					var y_axis_config: TauAxisConfig = p_pane_cfg.get_y_axis_config(first_y_axis_id)
					if y_axis_config != null and y_axis_config.scale == TauAxisConfig.Scale.LOGARITHMIC:
						p_result.add_error("LineValidator: pane %d: STACKED mode is incompatible with logarithmic y axis" % p_pane_index)

			_:
				p_result.add_error("LineValidator: pane %d: unsupported line mode %d" % [p_pane_index, p_line_config.mode])


	# Fill validation is per entry of TauLineStyle.fills, since each entry
	# carries the whole fill for the series it cycles onto. A null entry takes
	# the built-in defaults, which are always valid.
	static func _validate_fill_constraints(p_pane_index: int, p_line_config: TauLineConfig, p_pane_cfg: TauPaneConfig, p_x_axis_cfg: TauAxisConfig, p_line_overlay_bindings: Array[TauXYSeriesBinding], p_result: ValidationResult) -> void:
		var has_logarithmic_y := _has_logarithmic_y_axis(p_pane_cfg, p_line_overlay_bindings)
		var fills: Array[TauLineFill] = p_line_config.style.fills
		for i in range(fills.size()):
			var fill: TauLineFill = fills[i]
			if fill == null:
				continue

			_validate_custom_stretch_range(p_pane_index, i, fill, p_x_axis_cfg, p_result)

			match fill.fill_mode:
				TauLineFill.FillMode.TO_BASELINE:
					_validate_baseline_fill(p_pane_index, i, fill, has_logarithmic_y, p_result)
				TauLineFill.FillMode.STACKED:
					_validate_stacked_fill(p_pane_index, i, fill, p_line_config.mode, p_result)


	static func _has_logarithmic_y_axis(p_pane_cfg: TauPaneConfig, p_line_overlay_bindings: Array[TauXYSeriesBinding]) -> bool:
		for binding in p_line_overlay_bindings:
			var y_axis_config: TauAxisConfig = p_pane_cfg.get_y_axis_config(binding.y_axis_id)
			if y_axis_config.scale == TauAxisConfig.Scale.LOGARITHMIC:
				return true
		return false


	# A non-positive baseline cannot be mapped on a logarithmic scale, so the
	# fill is rejected as soon as any line series in this pane binds to such an
	# axis. The fills array cycles onto series, so the offending pairing cannot
	# be narrowed down to a single series here.
	static func _validate_baseline_fill(p_pane_index: int, p_fill_index: int, p_fill: TauLineFill, p_has_logarithmic_y: bool, p_result: ValidationResult) -> void:
		if not p_has_logarithmic_y:
			return
		if p_fill.fill_baseline > 0.0:
			return
		p_result.add_error("LineValidator: pane %d: fills[%d]: TO_BASELINE fill_mode requires fill_baseline > 0 on a logarithmic y axis, got %s" % [p_pane_index, p_fill_index, p_fill.fill_baseline])


	# The band is drawn between a layer and the one below, so it only exists
	# when the overlay itself stacks, and it has no baseline for MAGNITUDE to
	# measure from.
	static func _validate_stacked_fill(p_pane_index: int, p_fill_index: int, p_fill: TauLineFill, p_line_mode: TauLineConfig.LineMode, p_result: ValidationResult) -> void:
		if p_line_mode != TauLineConfig.LineMode.STACKED:
			p_result.add_error("LineValidator: pane %d: fills[%d]: STACKED fill_mode requires mode STACKED" % [p_pane_index, p_fill_index])

		if p_fill.texture == null:
			return
		if p_fill.texture_mode != TauLineFill.FillTextureMode.STRETCH:
			return
		if p_fill.stretch_span != TauLineFill.FillStretchSpan.MAGNITUDE:
			return
		p_result.add_error("LineValidator: pane %d: fills[%d]: MAGNITUDE stretch_span is not supported under STACKED fill_mode, the band has no baseline to measure from" % [p_pane_index, p_fill_index])


	# Only a STRETCH fill with a non-LINE span reads the CUSTOM window. This
	# single pass flags the misconfigurations of that window:
	#   - the fill never reads it, so CUSTOM has no effect and DOMAIN was meant.
	#   - zero width, so the reader has no gradient to draw. DOMAIN can collapse
	#     the same way on flat data, but that is a runtime shape caught too
	#     late here.
	#   - VALUE_X on a categorical x axis, whose samples sit at category
	#     centers with no continuous x to place the ends on. DOMAIN spans those
	#     centers instead.
	static func _validate_custom_stretch_range(p_pane_index: int, p_fill_index: int, p_fill: TauLineFill, p_x_axis_cfg: TauAxisConfig, p_result: ValidationResult) -> void:
		if p_fill.stretch_range_policy != TauLineFill.StretchRangePolicy.CUSTOM:
			return

		if p_fill.texture_mode != TauLineFill.FillTextureMode.STRETCH or p_fill.stretch_span == TauLineFill.FillStretchSpan.LINE:
			p_result.add_error("LineValidator: pane %d: fills[%d]: CUSTOM stretch_range_policy is set but this fill never reads it, use DOMAIN or give the fill a VALUE_X, VALUE_Y or MAGNITUDE span" % [p_pane_index, p_fill_index])
			return

		if p_fill.stretch_range.x == p_fill.stretch_range.y:
			p_result.add_error("LineValidator: pane %d: fills[%d]: CUSTOM stretch_range is zero width (stretch_range.x == stretch_range.y), no gradient to draw" % [p_pane_index, p_fill_index])

		if p_x_axis_cfg.type == TauAxisConfig.Type.CATEGORICAL and p_fill.stretch_span == TauLineFill.FillStretchSpan.VALUE_X:
			p_result.add_error("LineValidator: pane %d: fills[%d]: CUSTOM stretch_range is not supported on a categorical x axis with VALUE_X span, use DOMAIN policy" % [p_pane_index, p_fill_index])
