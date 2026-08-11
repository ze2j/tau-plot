# Dependencies
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const PaneOverlayType := preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
const Axis := preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis
const LineVisualAttributes := preload("res://addons/tau-plot/plot/xy/line/line_visual_attributes.gd").LineVisualAttributes
const LineVisualCallbacks := preload("res://addons/tau-plot/plot/xy/line/line_visual_callbacks.gd").LineVisualCallbacks
const ValidationResult := preload("res://addons/tau-plot/plot/validation_result.gd").ValidationResult


## Validates that the line overlay configuration for a single pane is
## internally consistent.
##
## This validator checks configuration only, not dataset values. The dataset
## is mutable after plot_xy() is called, so runtime data issues are handled
## elsewhere.
##
## Style resources are out of scope too. A style is resolved from the theme
## and the user resource together, so a constraint between style fields is
## not decidable from what the user typed and is reported once the cascade
## has run.
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

		var line_config := pane_cfg.get_overlay_config(PaneOverlayType.LINE) as TauLineConfig
		if line_config == null:
			p_result.add_error("LineValidator: pane %d: no TauLineConfig found in pane overlays" % p_pane_index)
			return

		_validate_line_visuals(p_pane_index, line_config, p_line_overlay_bindings, p_result)

		var is_shared_x := (p_dataset.get_mode() == Dataset.Mode.SHARED_X)
		_validate_line_mode_constraints(p_pane_index, line_config, pane_cfg, p_line_overlay_bindings, is_shared_x, p_result)


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
