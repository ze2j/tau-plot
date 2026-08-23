# Dependencies
const Legend := preload("res://addons/tau-plot/plot/legend/legend.gd").Legend
const LegendController := preload("res://addons/tau-plot/plot/legend/legend_controller.gd").LegendController
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const PaneOverlayType := preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType


## XY-specific legend builder.
##
## Composes a reusable [LegendController] and adds XY-specific data collection:
## mapping [TauXYSeriesBinding] entries to [Legend.SeriesInfo] and resolving
## key factory callables via a plot-provided resolver.
class XYLegendBuilder extends RefCounted:

	# Overlay paint order within a pane, lowest painted first. Mirrors the
	# renderer creation order in XYPlot so a row of keys reads as a cross
	# section of the pane it describes.
	const _PAINT_ORDER := {
		PaneOverlayType.BAR: 0,
		PaneOverlayType.LINE: 1,
		PaneOverlayType.SCATTER: 2,
	}

	# Width of a key box as a multiple of its height, per overlay type. A line
	# key is wider than tall because it has to show a dash pattern, and a
	# segment together with the band under it. A swatch and a marker read fine
	# in a square.
	const _KEY_ASPECT_RATIO := {
		PaneOverlayType.BAR: 1.0,
		PaneOverlayType.LINE: 2.0,
		PaneOverlayType.SCATTER: 1.0,
	}

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
	## [param p_key_refresh_resolver] Same shape, for the refresh_key_control
	## callable of that renderer.
	##
	## [param p_legend_config] Required. TauPlot substitutes a default config
	## when the user leaves the property unset.
	##
	## Returns the resolved TauLegendStyle so the caller can cache it.
	func build(p_dataset: Dataset,
			p_series_bindings: Array[TauXYSeriesBinding],
			p_key_factory_resolver: Callable,
			p_key_refresh_resolver: Callable,
			p_legend_config: TauLegendConfig,
			p_visible: bool) -> TauLegendStyle:
		var series_infos := _collect_series_infos(p_dataset, p_series_bindings,
				p_key_factory_resolver, p_key_refresh_resolver)
		return controller.build(series_infos, p_legend_config.style, p_legend_config.position,
				p_legend_config.flow_direction, p_visible)


	## Removes the legend from the scene tree and frees it.
	func destroy() -> void:
		controller.destroy()


	####################################################################################################
	# Private
	####################################################################################################


	## Collects SeriesInfo array from bindings, skipping those opting out of the legend.
	## A series contributes an entry as soon as one of its bindings opts in.
	## Rows come out ordered by series index, and the keys within a row by
	## overlay paint order.
	func _collect_series_infos(p_dataset: Dataset,
			p_bindings: Array[TauXYSeriesBinding],
			p_key_factory_resolver: Callable,
			p_key_refresh_resolver: Callable
			) -> Array[Legend.SeriesInfo]:
		var result: Array[Legend.SeriesInfo] = []
		var seen: Dictionary[int, int] = {}  # series_id -> index in result

		# Keys are appended in traversal order, so the bindings are walked in
		# paint order. Two bindings of one series never share an overlay type,
		# so the unstable sort cannot reshuffle a row.
		var ordered_bindings := p_bindings.duplicate()
		ordered_bindings.sort_custom(func(a: TauXYSeriesBinding, b: TauXYSeriesBinding) -> bool:
			return _PAINT_ORDER[a.overlay_type] < _PAINT_ORDER[b.overlay_type]
		)

		for binding in ordered_bindings:
			if not binding.show_in_legend:
				continue

			var series_id: int = binding.series_id
			var key := Legend.KeyInfo.new()
			key.create_key_control = p_key_factory_resolver.call(binding.overlay_type, binding.pane_index)
			key.refresh_key_control = p_key_refresh_resolver.call(binding.overlay_type, binding.pane_index)
			key.key_aspect_ratio = _KEY_ASPECT_RATIO[binding.overlay_type]

			if series_id in seen:
				var idx: int = seen[series_id]
				result[idx].keys.append(key)
			else:
				var info := Legend.SeriesInfo.new()
				info.series_id = series_id
				info.series_index = p_dataset.get_series_index_by_id(series_id)
				info.series_name = p_dataset.get_series_name(series_id)
				info.keys.append(key)

				seen[series_id] = result.size()
				result.append(info)

		result.sort_custom(func(a: Legend.SeriesInfo, b: Legend.SeriesInfo) -> bool:
			return a.series_index < b.series_index
		)
		return result
