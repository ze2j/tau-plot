# Dependencies
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const PaneOverlayType := preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
const VisualAttributes := preload("res://addons/tau-plot/plot/xy/visual_attributes.gd").VisualAttributes
const BarVisualAttributes := preload("res://addons/tau-plot/plot/xy/bar/bar_visual_attributes.gd").BarVisualAttributes
const LineVisualAttributes := preload("res://addons/tau-plot/plot/xy/line/line_visual_attributes.gd").LineVisualAttributes
const ScatterVisualAttributes := preload("res://addons/tau-plot/plot/xy/scatter/scatter_visual_attributes.gd").ScatterVisualAttributes


## What one overlay of one pane holds: the series bound to it, the config they
## were bound through, and the per-sample attributes of each of them.
class OverlaySeries extends RefCounted:

	var overlay_type: PaneOverlayType

	## The overlay config the pane carries for this type. Never null.
	var config: TauPaneOverlayConfig = null

	## In dataset order. Never empty, since an overlay exists only where a
	## binding named it.
	var series_ids := PackedInt64Array()

	## Parallel to series_ids. Every element is of the concrete type the
	## overlay indexes, never null.
	var visual_attributes: Array[VisualAttributes] = []


## What one pane holds.
class PaneSeries extends RefCounted:

	## At most one entry per overlay type, ordered from the widest footprint to
	## the narrowest: bars, then lines, then scatter markers.
	var overlays: Array[OverlaySeries] = []


	## Returns the overlay of the given type, null when the pane holds none.
	func find_overlay(p_overlay_type: PaneOverlayType) -> OverlaySeries:
		for overlay: OverlaySeries in overlays:
			if overlay.overlay_type == p_overlay_type:
				return overlay
		return null


## Groups the series bindings the user gave the plot by pane and by overlay.
##
## A binding names one series, one pane and one overlay type, and the list comes
## in whatever order the user built it. This reads it the other way round, so
## that a pane can be asked what it draws, and lays each group out in the order
## the renderers index it by.
class SeriesPartition extends RefCounted:

	## One entry per pane of TauXYConfig.panes, in pane order. A pane no binding
	## named holds no overlay.
	var panes: Array[PaneSeries] = []

	# Overlay order inside a pane, from the widest footprint to the narrowest.
	# TauPaneConfig.overlays does not reorder this.
	const _OVERLAY_ORDER := [PaneOverlayType.BAR, PaneOverlayType.LINE, PaneOverlayType.SCATTER]


	func _init(p_xy_config: TauXYConfig, p_bindings: Array[TauXYSeriesBinding], p_dataset: Dataset) -> void:
		var pane_count := p_xy_config.panes.size()

		# One dictionary per pane, keyed by overlay type. Nothing can be laid out
		# in order while the bindings are being walked, since a series only gets
		# its index once the whole list is in.
		var builders_per_pane: Array[Dictionary] = []
		for pane_index in range(pane_count):
			builders_per_pane.append({})

		for binding in p_bindings:
			var pane_builders: Dictionary = builders_per_pane[binding.pane_index]
			if binding.overlay_type not in pane_builders:
				var created := _OverlayBuilder.new()
				# The validators reject a binding whose pane carries no config of the bound overlay type.
				created.config = p_xy_config.panes[binding.pane_index].get_overlay_config(binding.overlay_type)
				pane_builders[binding.overlay_type] = created

			var builder: _OverlayBuilder = pane_builders[binding.overlay_type]
			if binding.series_id not in builder.series_ids:
				builder.series_ids.append(binding.series_id)
			if binding.visual_attributes != null:
				# The validators reject attributes whose type does not match the bound overlay type.
				builder.attributes_by_series_id[binding.series_id] = binding.visual_attributes

		panes.resize(pane_count)
		for pane_index in range(pane_count):
			var pane_series := PaneSeries.new()
			panes[pane_index] = pane_series

			var pane_builders: Dictionary = builders_per_pane[pane_index]
			for overlay_type in _OVERLAY_ORDER:
				if overlay_type in pane_builders:
					pane_series.overlays.append(_build_overlay(overlay_type, pane_builders[overlay_type], p_dataset))


	## Returns the series ids of the given overlay type, one entry per pane and
	## an empty one for a pane holding no overlay of that type.
	func collect_series_ids(p_overlay_type: PaneOverlayType) -> Array[PackedInt64Array]:
		var per_pane: Array[PackedInt64Array] = []
		per_pane.resize(panes.size())
		for pane_index in range(panes.size()):
			var overlay := panes[pane_index].find_overlay(p_overlay_type)
			if overlay != null:
				per_pane[pane_index] = overlay.series_ids
		return per_pane


	####################################################################################################
	# Private
	####################################################################################################

	# What one overlay gathers while the bindings are walked. Its two
	# collections are reference types, so a binding appends to the record the
	# dictionary holds rather than to a copy of it.
	class _OverlayBuilder extends RefCounted:
		var config: TauPaneOverlayConfig = null
		var series_ids: Array[int] = []
		var attributes_by_series_id: Dictionary = {}	# series id -> VisualAttributes


	static func _build_overlay(p_overlay_type: PaneOverlayType, p_builder: _OverlayBuilder, p_dataset: Dataset) -> OverlaySeries:
		var overlay := OverlaySeries.new()
		overlay.overlay_type = p_overlay_type
		overlay.config = p_builder.config
		overlay.series_ids = _to_dataset_order(p_builder.series_ids, p_dataset)
		overlay.visual_attributes = _align_visual_attributes(p_overlay_type, overlay.series_ids, p_builder.attributes_by_series_id)
		return overlay


	# Bindings come in any order, so the ids gathered from them are in no useful
	# one. Both z_order and the stacking layers are defined on dataset order, so
	# that is the order the renderers must get.
	static func _to_dataset_order(p_series_ids: Array[int], p_dataset: Dataset) -> PackedInt64Array:
		var ordered := p_series_ids.duplicate()
		ordered.sort_custom(func(p_left: int, p_right: int) -> bool:
			return p_dataset.get_series_index_by_id(p_left) < p_dataset.get_series_index_by_id(p_right))
		return PackedInt64Array(ordered)


	# Lays the attributes out in the series id order, which is the order the
	# renderers index them by. Only one instance can exist per series, since
	# xy_plot_validator rejects duplicate (pane_index, overlay_type, series_id)
	# bindings.
	static func _align_visual_attributes(p_overlay_type: PaneOverlayType, p_series_ids: PackedInt64Array, p_by_series_id: Dictionary) -> Array[VisualAttributes]:
		var aligned: Array[VisualAttributes] = []
		aligned.resize(p_series_ids.size())
		for i in range(p_series_ids.size()):
			var series_id := p_series_ids[i]
			if p_by_series_id.has(series_id):
				aligned[i] = p_by_series_id[series_id]
			else:
				aligned[i] = _make_empty_visual_attributes(p_overlay_type)
		return aligned


	# A series the user gave no attributes gets an empty instance rather than
	# null: every buffer inside it is already null, so the existing per-buffer
	# null checks cover the gap and the per-sample path needs no element check.
	static func _make_empty_visual_attributes(p_overlay_type: PaneOverlayType) -> VisualAttributes:
		match p_overlay_type:
			PaneOverlayType.BAR:
				return BarVisualAttributes.new()
			PaneOverlayType.LINE:
				return LineVisualAttributes.new()
			PaneOverlayType.SCATTER:
				return ScatterVisualAttributes.new()
		return null
