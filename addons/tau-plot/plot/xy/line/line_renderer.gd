# Dependencies
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout
const SeriesAxisAssignment := preload("res://addons/tau-plot/plot/xy/series_axis_assignment.gd").SeriesAxisAssignment
const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const Axis = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis
const VisualAttributes = preload("res://addons/tau-plot/plot/xy/visual_attributes.gd").VisualAttributes
const LineVisualAttributes := preload("res://addons/tau-plot/plot/xy/line/line_visual_attributes.gd").LineVisualAttributes


# Draws line overlays from an XYLayout + Dataset.
#
# This renderer reads all samples through the Dataset public API (no direct
# buffer/series access). One contiguous run of valid samples produces one
# draw_polyline() call per series.
#
# Runtime behavior:
# - NaN and Inf X or Y values are treated according to TauLineConfig.gap_policy.
# - Logarithmic Y scales: y <= 0 is treated as invalid.
# - Logarithmic X scales: x <= 0 is treated as invalid.
# - GapPolicy.SKIP breaks the polyline at every invalid sample.
# - GapPolicy.BRIDGE drops invalid samples and keeps the polyline contiguous,
#   so the surrounding valid samples are connected directly.
#
# LineValidator is expected to enforce binding-level typing constraints.
class LineRenderer extends Control:
	var _layout: XYLayout = null
	var _dataset: Dataset = null
	var _line_config: TauLineConfig = null
	var _series_assignment: SeriesAxisAssignment = null
	var _visual_attributes: Array[LineVisualAttributes] = []

	# Pane index this renderer belongs to. Used for per-pane domain/layout queries.
	var _pane_index: int = 0

	# Line-specific series list: only series mapped as LINE are iterated.
	# Must be provided at construction. Empty means this renderer has no
	# series to draw.
	var _line_series_ids: PackedInt64Array = PackedInt64Array()

	# Resolved style instances pushed by xy_plot. Treat as read-only.
	var _line_style: TauLineStyle = null
	var _xy_style: TauXYStyle = null


	func _init(p_layout: XYLayout,
				p_dataset: Dataset,
				p_line_config: TauLineConfig,
				p_xy_style: TauXYStyle,
				p_series_assignment: SeriesAxisAssignment,
				p_pane_index: int = 0,
				p_visual_attributes: Array[LineVisualAttributes] = [],
				p_line_series_ids: PackedInt64Array = PackedInt64Array()) -> void:
		theme_type_variation = &"TauLine"
		_layout = p_layout
		_dataset = p_dataset
		_line_config = p_line_config
		_series_assignment = p_series_assignment
		_pane_index = p_pane_index
		_visual_attributes = p_visual_attributes
		_line_series_ids = p_line_series_ids
		_line_style = p_line_config.style
		_xy_style = p_xy_style


	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()


	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_RESIZED:
				queue_redraw()


	func get_config() -> TauLineConfig:
		return _line_config


	## Receives the resolved TauLineStyle from xy_plot after cascade resolution.
	func set_resolved_line_style(p_style: TauLineStyle) -> void:
		_line_style = p_style


	## Receives the resolved TauXYStyle from xy_plot after cascade resolution.
	func set_resolved_xy_style(p_style: TauXYStyle) -> void:
		_xy_style = p_style


	## Creates a legend key Control for a line overlay.
	func create_legend_key_control(_p_series_index: int) -> Control:
		# TODO: implement create_legend_key_control for lines
		return Control.new()


	####################################################################################################
	# Private
	####################################################################################################

	func _draw() -> void:
		if _line_style == null:
			push_error("LineRenderer: resolved TauLineStyle is null.")
			return

		var pane_rect := _layout.get_pane_rect(_pane_index)
		if pane_rect.size.x <= 0.0 or pane_rect.size.y <= 0.0:
			return

		var series_count := _get_line_series_count()
		if series_count <= 0:
			return

		var draw_order := _get_series_draw_order(series_count)
		var width_px: float = max(_line_style.line_width_px, 0.0)
		if width_px <= 0.0:
			return

		for draw_rank in range(draw_order.size()):
			var series_index: int = draw_order[draw_rank]
			_draw_series_independent(series_index, width_px)


	# Draws a single series as one or more polyline runs, respecting the
	# active gap policy. Run emission follows these rules:
	#   - A valid sample is appended to the current run.
	#   - An invalid sample (NaN/Inf X or Y, or a value forbidden by the
	#     active axis scale) is handled according to gap_policy:
	#     - SKIP   flushes the current run and starts a new one.
	#     - BRIDGE drops the sample and keeps appending into the same run.
	#   - A run of fewer than two points is discarded (no polyline).
	func _draw_series_independent(p_series_index: int, p_width_px: float) -> void:
		var x_cfg := _get_x_axis_config()
		if x_cfg != null and x_cfg.type == TauAxisConfig.Type.CATEGORICAL:
			_draw_series_categorical(p_series_index, p_width_px)
		else:
			_draw_series_continuous(p_series_index, p_width_px)


	func _draw_series_continuous(p_series_index: int, p_width_px: float) -> void:
		var series_id := _get_line_series_id(p_series_index)
		var global_series_index := _get_global_series_index(p_series_index)
		var color := _resolve_series_color(global_series_index)
		var y_axis_id := _get_y_axis_id_for_series(series_id)
		var bridge: bool = _line_config.gap_policy == TauLineConfig.GapPolicy.BRIDGE

		var run := PackedVector2Array()

		var is_shared_x := _dataset.get_mode() == Dataset.Mode.SHARED_X
		var sample_count := _dataset.get_series_sample_count(series_id)

		for i in range(sample_count):
			var x_value: float = float(_dataset.get_shared_x(i)) if is_shared_x else float(_dataset.get_series_x(series_id, i))
			if is_nan(x_value) or is_inf(x_value) or not _is_x_value_valid_for_scale(x_value):
				if not bridge:
					run = _flush_run(run, color, p_width_px)
				continue

			var y_value := _dataset.get_series_y(series_id, i)
			if is_nan(y_value) or is_inf(y_value) or not _is_y_value_valid_for_scale(series_id, y_value):
				if not bridge:
					run = _flush_run(run, color, p_width_px)
				continue

			var x_px := _layout.map_x_to_px(_pane_index, x_value)
			var y_px := _layout.map_y_to_px(_pane_index, y_value, y_axis_id)
			run.append(_layout.map_point_to_screen(x_px, y_px))

		if run.size() >= 2:
			draw_polyline(run, color, p_width_px)


	func _draw_series_categorical(p_series_index: int, p_width_px: float) -> void:
		var series_id := _get_line_series_id(p_series_index)
		var global_series_index := _get_global_series_index(p_series_index)
		var color := _resolve_series_color(global_series_index)
		var y_axis_id := _get_y_axis_id_for_series(series_id)
		var bridge: bool = _line_config.gap_policy == TauLineConfig.GapPolicy.BRIDGE

		var run := PackedVector2Array()
		var sample_count := _dataset.get_series_sample_count(series_id)

		for cat_idx in range(sample_count):
			var y_value := _dataset.get_series_y(series_id, cat_idx)
			if is_nan(y_value) or is_inf(y_value) or not _is_y_value_valid_for_scale(series_id, y_value):
				if not bridge:
					run = _flush_run(run, color, p_width_px)
				continue

			var x_px := _layout.map_x_category_center_to_px(_pane_index, cat_idx)
			var y_px := _layout.map_y_to_px(_pane_index, y_value, y_axis_id)
			run.append(_layout.map_point_to_screen(x_px, y_px))

		if run.size() >= 2:
			draw_polyline(run, color, p_width_px)


	func _flush_run(p_run: PackedVector2Array, p_color: Color, p_width_px: float) -> PackedVector2Array:
		if p_run.size() >= 2:
			draw_polyline(p_run, p_color, p_width_px)
		return PackedVector2Array()


	####################################################################################################
	# Series helpers
	####################################################################################################

	# Returns the number of series this renderer is responsible for.
	func _get_line_series_count() -> int:
		return _line_series_ids.size()


	# Returns the dataset series_id for a given line-local series index.
	func _get_line_series_id(p_line_index: int) -> int:
		return _line_series_ids[p_line_index]


	# Returns the dataset-global series index for a given pane-local series index.
	func _get_global_series_index(p_local_index: int) -> int:
		return _dataset.get_series_index_by_id(_line_series_ids[p_local_index])


	# Honors TauPaneOverlayConfig.z_order to decide which series is drawn on top.
	func _get_series_draw_order(p_series_count: int) -> Array[int]:
		var order: Array[int] = []
		for i in range(p_series_count):
			order.append(i)
		if _line_config.z_order == TauPaneOverlayConfig.ZOrder.REVERSE_SERIES_ORDER:
			order.reverse()
		return order


	# Returns the shared x axis config.
	func _get_x_axis_config() -> TauAxisConfig:
		return _layout.domain.config.x_axis


	####################################################################################################
	# Color resolution
	####################################################################################################

	# TODO: fully implement _resolve_series_color
	func _resolve_series_color(p_global_series_index: int) -> Color:
		var color := _xy_style.get_series_color(p_global_series_index)
		color.a = clampf(_xy_style.series_alpha, 0.0, 1.0)
		return color


	####################################################################################################
	# Axis helpers
	####################################################################################################

	func _get_y_axis_id_for_series(p_series_id: int) -> AxisId:
		var axis_id: int = _series_assignment.get_y_axis_id_for_series(p_series_id, _pane_index)
		if axis_id != -1:
			return axis_id as AxisId
		# Fallback: should not happen if validation passed.
		push_error("LineRenderer: series %d not assigned to any y-axis in pane %d" % [p_series_id, _pane_index])
		return Axis.get_orthogonal_axes(_layout.domain.config.x_axis_id)[0]


	####################################################################################################
	# Axis-scale validity checks
	####################################################################################################

	func _is_x_value_valid_for_scale(p_x_value: float) -> bool:
		var x_cfg := _layout.domain.config.x_axis
		if x_cfg == null:
			return true
		if x_cfg.scale == TauAxisConfig.Scale.LOGARITHMIC and p_x_value <= 0.0:
			return false
		return true


	func _is_y_value_valid_for_scale(p_series_id: int, p_y_value: float) -> bool:
		var y_axis_id := _get_y_axis_id_for_series(p_series_id)
		var pane_cfg: TauPaneConfig = _layout.domain.config.panes[_pane_index]
		var y_cfg: TauAxisConfig = pane_cfg.get_y_axis_config(y_axis_id)
		if y_cfg == null:
			return true
		if y_cfg.scale == TauAxisConfig.Scale.LOGARITHMIC and p_y_value <= 0.0:
			return false
		return true
