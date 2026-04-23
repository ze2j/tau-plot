# Dependencies
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
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
