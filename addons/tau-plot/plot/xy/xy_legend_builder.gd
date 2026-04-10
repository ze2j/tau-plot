# Dependencies
const Legend := preload("res://addons/tau-plot/plot/legend/legend.gd").Legend
const LegendController := preload("res://addons/tau-plot/plot/legend/legend_controller.gd").LegendController
const Position = TauLegendConfig.Position
const FlowDirection = TauLegendConfig.FlowDirection
const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset


## XY-specific legend builder.
##
## Composes a reusable [LegendController] and adds XY-specific data collection:
## mapping [TauXYSeriesBinding] entries to [Legend.SeriesInfo] and resolving
## key factory callables via a plot-provided resolver.
class XYLegendBuilder extends RefCounted:

	## The reusable controller that handles placement, flow, and sizing.
	var controller: LegendController = null


	func _init(p_plot: PanelContainer, p_attach_outside: Callable) -> void:
		controller = LegendController.new(p_plot, p_attach_outside)


	## Collects series infos from XY bindings and delegates to the controller.
	##
	## [param p_key_factory_resolver] Callable with signature:
	##   func(p_overlay_type: int, p_pane_index: int) -> Callable
	## Returns the create_key_control callable for the renderer that owns
	## the given overlay type on the given pane. The Legend and this builder
	## never import any renderer class directly.
	##
	## Returns the resolved TauLegendStyle so the caller can cache it.
	func build(p_dataset: Dataset,
			p_series_bindings: Array[TauXYSeriesBinding],
			p_xy_config: TauXYConfig,
			p_key_factory_resolver: Callable,
			p_legend_config: TauLegendConfig,
			p_visible: bool) -> TauLegendStyle:
		var user_style: TauLegendStyle = p_legend_config.style if p_legend_config != null else null
		var position: Position = p_legend_config.position if p_legend_config != null else Position.OUTSIDE_TOP
		var flow: FlowDirection = p_legend_config.flow_direction if p_legend_config != null else FlowDirection.AUTO
		var series_infos := _collect_series_infos(p_dataset, p_series_bindings, p_xy_config, p_key_factory_resolver)
		return controller.build(series_infos, user_style, position, flow, p_visible)


	## Removes the legend from the scene tree and frees it.
	func destroy() -> void:
		controller.destroy()


	####################################################################################################
	# Private
	####################################################################################################


	## Collects SeriesInfo array from bindings.
	func _collect_series_infos(p_dataset: Dataset,
			p_bindings: Array[TauXYSeriesBinding],
			p_xy_config: TauXYConfig,
			p_key_factory_resolver: Callable
			) -> Array[Legend.SeriesInfo]:
		var result: Array[Legend.SeriesInfo] = []
		var seen: Dictionary[int, int] = {}  # series_id -> index in result

		for binding in p_bindings:
			var series_id := binding.series_id
			var series_idx := p_dataset.get_series_index_by_id(series_id)
			if series_idx < 0:
				push_error("XYLegendBuilder._collect_series_infos(): Series id %d not found in dataset" % series_id)
				continue

			var key := Legend.KeyInfo.new()

			# Validate pane index.
			if binding.pane_index < 0 or binding.pane_index >= p_xy_config.panes.size():
				push_error("XYLegendBuilder._collect_series_infos(): invalid pane index %d" % binding.pane_index)
				continue

			# Resolve the create_key_control callable via the plot-provided resolver.
			var factory: Callable = p_key_factory_resolver.call(binding.overlay_type, binding.pane_index)
			if not factory.is_valid():
				push_error("XYLegendBuilder._collect_series_infos(): no key factory for overlay type %d on pane %d" % [binding.overlay_type, binding.pane_index])
				continue
			key.create_key_control = factory

			if series_id in seen:
				var idx: int = seen[series_id]
				result[idx].keys.append(key)
			else:
				var info := Legend.SeriesInfo.new()
				info.series_id = series_id
				info.series_index = series_idx
				info.series_name = p_dataset.get_series_name(series_id)
				info.keys.append(key)

				seen[series_id] = result.size()
				result.append(info)

		result.sort_custom(func(a: Legend.SeriesInfo, b: Legend.SeriesInfo) -> bool:
			return a.series_index < b.series_index
		)
		return result
