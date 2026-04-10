# Dependencies
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
const ScatterVisualAttributes = preload("res://addons/tau-plot/plot/xy/scatter/scatter_visual_attributes.gd").ScatterVisualAttributes
const ScatterVisualCallbacks = preload("res://addons/tau-plot/plot/xy/scatter/scatter_visual_callbacks.gd").ScatterVisualCallbacks
const ValidationResult = preload("res://addons/tau-plot/plot/validation_result.gd").ValidationResult


## Validates that the scatter overlay configuration for a single pane is
## internally consistent: marker size policy, visual types.
##
## This validator checks configuration only, not dataset values. The dataset is
## mutable after plot_xy() is called, so runtime data issues are handled
## elsewhere.
##
## All errors are accumulated into the provided [ValidationResult].
class ScatterValidator extends RefCounted:

	static func validate(p_dataset: Dataset, p_domain_cfg: TauXYConfig, p_pane_index: int, p_scatter_overlay_bindings: Array[TauXYSeriesBinding], p_result: ValidationResult) -> void:
		if p_dataset == null:
			p_result.add_error("ScatterValidator: p_dataset is null")
			return
		if p_domain_cfg == null:
			p_result.add_error("ScatterValidator: p_domain_cfg is null")
			return
		if p_pane_index < 0 or p_pane_index >= p_domain_cfg.panes.size():
			p_result.add_error("ScatterValidator: p_pane_index %d is out of range" % p_pane_index)
			return
		for binding in p_scatter_overlay_bindings:
			if binding.pane_index != p_pane_index:
				p_result.add_error("ScatterValidator: binding has pane_index %d, expected %d" % [binding.pane_index, p_pane_index])
				return
			if binding.overlay_type != PaneOverlayType.SCATTER:
				p_result.add_error("ScatterValidator: binding has overlay_type %d, expected SCATTER" % int(binding.overlay_type))
				return

		var pane_cfg := p_domain_cfg.panes[p_pane_index]
		if pane_cfg == null:
			p_result.add_error("ScatterValidator: pane %d: pane config is null" % p_pane_index)
			return

		var scatter_config := pane_cfg.get_overlay_config(PaneOverlayType.SCATTER) as TauScatterConfig
		if scatter_config == null:
			p_result.add_error("ScatterValidator: pane %d: no TauScatterConfig found in pane overlays" % p_pane_index)
			return

		_validate_scatter_visuals(p_pane_index, scatter_config, p_scatter_overlay_bindings, p_result)
		_validate_marker_config(p_pane_index, scatter_config, p_result)


	####################################################################################################
	# Private
	####################################################################################################

	static func _validate_scatter_visuals(p_pane_index: int, p_scatter_config: TauPaneOverlayConfig, p_scatter_overlay_bindings: Array[TauXYSeriesBinding], p_result: ValidationResult) -> void:
		if p_scatter_config.visual_callbacks != null and p_scatter_config.visual_callbacks is not ScatterVisualCallbacks:
			p_result.add_error("ScatterValidator: pane %d: visual_callbacks is not a ScatterVisualCallbacks" % p_pane_index)

		for i in range(0, p_scatter_overlay_bindings.size()):
			var binding: TauXYSeriesBinding = p_scatter_overlay_bindings[i]
			if binding.visual_attributes != null and binding.visual_attributes is not ScatterVisualAttributes:
				p_result.add_error("ScatterValidator: pane %d: series_id %d has visual_attributes that is not a ScatterVisualAttributes" % [p_pane_index, binding.series_id])


	static func _validate_marker_config(p_pane_index: int, p_scatter_config: TauScatterConfig, p_result: ValidationResult) -> void:
		var resolved_policy := p_scatter_config.get_resolved_marker_size_policy()
		if resolved_policy == TauScatterConfig.MarkerSizePolicy.DATA_UNITS:
			if p_scatter_config.marker_size_data_units <= 0.0:
				p_result.add_error("ScatterValidator: pane %d: marker_size_data_units must be > 0 when using DATA_UNITS policy (got %f)" % [p_pane_index, p_scatter_config.marker_size_data_units])
