# Dependencies
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout
const SeriesAxisAssignment := preload("res://addons/tau-plot/plot/xy/series_axis_assignment.gd").SeriesAxisAssignment
const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const Axis = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis
const VisualAttributes = preload("res://addons/tau-plot/plot/xy/visual_attributes.gd").VisualAttributes
const LineVisualAttributes := preload("res://addons/tau-plot/plot/xy/line/line_visual_attributes.gd").LineVisualAttributes
const LineHitRecord := preload("res://addons/tau-plot/plot/xy/line/line_hit_record.gd").LineHitRecord
const StackedSeriesValues := preload("res://addons/tau-plot/plot/xy/stacked_series_values.gd").StackedSeriesValues


# Draws line overlays from an XYLayout + Dataset.
#
# This renderer reads all samples through the Dataset public API (no direct
# buffer/series access). Each contiguous run of valid samples is drawn with
# one Godot draw call when no hover emphasis applies, or up to three
# draw calls when the hovered sample lies inside the run.
#
# Runtime behavior:
# - NaN and Inf X or Y values are treated according to TauLineConfig.gap_policy.
# - Logarithmic Y scales: y <= 0 is treated as invalid.
# - Logarithmic X scales: x <= 0 is treated as invalid.
# - GapPolicy.SKIP breaks the polyline at every invalid sample.
# - GapPolicy.BRIDGE drops invalid samples and keeps the polyline contiguous,
#   so the surrounding valid samples are connected directly.
# - TauLineConfig.interpolation_mode controls the curve drawn between two
#   consecutive valid samples. LINEAR draws straight segments. The step
#   modes (STEP_BEFORE, STEP_AFTER, STEP_MIDDLE) insert synthetic
#   intermediate points in screen space into the polyline. SMOOTH_MONOTONE
#   replaces each segment with a fixed number of sub-samples from a
#   Fritsch-Carlson piecewise cubic Hermite curve evaluated in screen space.
#
# Rendering path selection (per series):
# - The active line width for a series is resolved from
#   TauLineStyle.line_widths_px through the helper
#   TauLineStyle.get_series_width_px(global_series_index). A series whose
#   resolved width is 0 is skipped entirely.
# - The active dash length for a series is resolved from
#   TauLineStyle.dash_lengths_px through the helper
#   TauLineStyle.get_series_dash_px(global_series_index). Path selection is
#   therefore per series: two series in the same overlay can run on
#   different paths in the same frame.
# - Fast path: resolved per-series dash length is 0. The run is
#   drawn with a single draw_polyline_colors() call.
# - Dashed batched path: resolved per-series dash length is positive.
#   Dash phase is precomputed across the full run, the "on" intervals are
#   collected into a flat segment array, and the run is drawn with a single
#   draw_multiline_colors() call. The dash phase is continuous across all
#   segments of the polyline.
#
# Hover behavior:
# - When TauLineConfig.hoverable is true and set_hover_state() has flagged a
#   sample as hovered, the per-sample color is routed through
#   TauHoverConfig.hover_highlight_callback (or a built-in dim/brighten
#   default) so non-hovered samples are de-emphasized.
# - When the hovered sample lies inside a drawn run, the polyline is split
#   into up to three contiguous parts at the hovered sample's adjacent real
#   neighbors. The middle part is drawn at the per-series resolved hovered
#   width from TauLineStyle.hovered_line_widths_px, clamped to be at least
#   the per-series base width. The outer two parts keep the base width.
#   Each part is one draw call. For dashed lines, each part inherits the
#   cumulative arc-length offset from the polyline start, so the dash
#   pattern stays continuous through the slices.
#
# Per-sample color and alpha resolution:
# - Color resolution order: LineVisualAttributes.color_buffer, then
#   LineVisualCallbacks.color_callback, then the per-series color from
#   TauXYStyle.series_colors.
# - Alpha resolution order: LineVisualAttributes.alpha_buffer, then
#   LineVisualCallbacks.alpha_callback, then TauXYStyle.series_alpha.
# - The resolved alpha overwrites the alpha channel of the resolved color.
# - When the highlight feature is active, the resulting color is then
#   routed through TauHoverConfig.hover_highlight_callback.
# - Each vertex of the polyline carries its own resolved color. Colors are
#   linearly interpolated by Godot between consecutive vertices.
# - Synthetic step-mode intermediate vertices and SMOOTH_MONOTONE sub-samples
#   are colored consistently with the underlying segment endpoints so the
#   resulting interpolation matches the chosen interpolation mode.
#
# STACKED mode:
# - Each polyline is drawn at the per-X cumulative top of its layer.
#   Layer 0 sits at the bottom, ordered by dataset index.
# - Color and alpha callbacks always receive the original dataset value,
#   never the cumulative or the normalized value.
# - LineHitRecord.y_plotted_value carries the cumulative top.
#   LineHitRecord.y_raw_value carries the original dataset value.
#
# Area fill:
# - When TauLineConfig.fill_mode is TO_BASELINE, the area between the line
#   and the constant TauLineConfig.fill_baseline is filled before the line
#   is drawn. The polygon is built from the rendered polyline (after
#   interpolation has materialized any synthetic vertices) and is split at
#   every baseline crossing into same-side sub-polygons, each emitted as
#   one draw_colored_polygon call. The line itself is unaffected by the
#   split and remains one draw call per contiguous run.
# - Fill resolution is against one TauLineFill per series, resolved through
#   TauLineStyle.get_series_fill (modulo-cycled per series, like
#   line_widths_px). The fill is drawn either as a flat color or as a
#   texture, never as both:
#     - If the resolved fill's texture is null, the fill is a flat color.
#       The color comes from TauLineFill.color, except when it equals
#       TauLineFill.NO_COLOR, in which case the per-series color from
#       TauXYStyle.series_colors is used instead. The color is passed as-is
#       to the draw call.
#     - If the resolved fill's texture is non-null, the fill is the
#       texture. TauLineFill.color and the per-series color are both
#       ignored for this series. The draw call passes white as the
#       modulation color so the texture shows its own colors without
#       tinting.
#   In both cases, the alpha of whatever color was passed to the draw call
#   is then multiplied by TauLineFill.alpha.
# - Each sub-polygon is emitted with a per-vertex UV array driven by
#   TauLineFill.texture_mode. STRETCH samples the texture once across
#   a chosen span (pane, polygon bbox, or line-to-closing-edge), with axis
#   inversion applied for the pane and polygon spans so U/V align with the
#   data x/y direction. TILE samples the texture at native pixel size on
#   screen, with a square-pixel-correct grid rotated around the pane center
#   and translated in screen pixels, independent of pane shape.
class LineRenderer extends Control:
	# Number of sub-segments inserted between two consecutive samples by
	# SMOOTH_MONOTONE. The value balances visual smoothness on a typical
	# screen against the per-segment cost paid by draw_polyline_colors().
	const _SMOOTH_SUBDIVISIONS: int = 16

	var _layout: XYLayout = null
	var _dataset: Dataset = null
	var _line_config: TauLineConfig = null
	var _series_assignment: SeriesAxisAssignment = null
	var _visual_attributes: Array[LineVisualAttributes] = []

	# Pane index this renderer belongs to.
	var _pane_index: int = 0

	# Line-specific series list: only series mapped as LINE are iterated.
	# Must be provided at construction. Empty means this renderer has no
	# series to draw.
	var _line_series_ids: PackedInt64Array = PackedInt64Array()

	# Resolved style instances. Treat as read-only.
	var _line_style: TauLineStyle = null
	var _xy_style: TauXYStyle = null

	# One-shot guard for the non-monotonic SMOOTH_MONOTONE fallback warning.
	# Reset is intentionally absent: a single warning per renderer instance
	# is enough to surface the misconfiguration without flooding the output
	# on every redraw.
	var _smooth_non_monotonic_warned: bool = false

	# Per-frame cache of every real sample drawn onto a polyline this frame.
	# Rebuilt every _draw() so the cache never drifts from what is on screen.
	var _hit_records: Array[LineHitRecord] = []

	# Hover highlight state. When _highlight_active is true, the per-sample
	# color is routed through the hover color callback (or a built-in
	# dim/brighten default). When the hovered sample lies within a drawn
	# run, the two segments adjacent to it are drawn at the per-series
	# resolved hovered width clamped to be at least the per-series base width.
	var _highlight_active: bool = false
	var _hovered_series_id: int = -1
	var _hovered_sample_index: int = -1
	var _hover_highlight_callback: Callable = Callable()


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
		# Required for TILE-mode fill: draw_colored_polygon honors the
		# CanvasItem's texture_repeat setting, and the default clamps UVs
		# outside [0, 1] to the edge, collapsing the tile grid into a
		# single stretched copy.
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		queue_redraw()


	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_RESIZED:
				queue_redraw()


	func get_config() -> TauLineConfig:
		return _line_config


	## Sets the resolved [TauLineStyle] used for subsequent draws.
	func set_resolved_line_style(p_style: TauLineStyle) -> void:
		_line_style = p_style


	## Sets the resolved [TauXYStyle] used for subsequent draws.
	func set_resolved_xy_style(p_style: TauXYStyle) -> void:
		_xy_style = p_style


	## Updates the hover highlight state. A change triggers a redraw so the
	## line is repainted with the new emphasis slice and dimming pattern.
	func set_hover_state(p_active: bool, p_series_id: int, p_sample_index: int, p_color_callback: Callable) -> void:
		var changed := p_active != _highlight_active or p_series_id != _hovered_series_id or p_sample_index != _hovered_sample_index
		_highlight_active = p_active
		_hovered_series_id = p_series_id
		_hovered_sample_index = p_sample_index
		_hover_highlight_callback = p_color_callback
		if changed:
			queue_redraw()


	## Returns the per-frame hit records cache. Treat as read-only.
	func get_hit_records() -> Array[LineHitRecord]:
		return _hit_records


	## Creates a legend key Control for a line overlay.
	func create_legend_key_control(_p_series_index: int) -> Control:
		# TODO: implement create_legend_key_control for lines
		return Control.new()


	####################################################################################################
	# Private
	####################################################################################################

	func _draw() -> void:
		_hit_records.clear()

		var pane_rect := _layout.get_pane_rect(_pane_index)
		if pane_rect.size.x <= 0.0 or pane_rect.size.y <= 0.0:
			return

		var stacked_values: StackedSeriesValues = null
		if _line_config.mode == TauLineConfig.LineMode.STACKED:
			stacked_values = StackedSeriesValues.new(_dataset, _line_series_ids,
					_line_config.stacked_normalization,
					_line_config.stacked_negative_policy)

		var draw_order := _get_series_draw_order(_get_line_series_count())
		for draw_rank in range(draw_order.size()):
			var series_index: int = draw_order[draw_rank]
			_draw_series(series_index, stacked_values)


	# Run emission rules, applied by both variants:
	#   - A valid sample is appended to the current run.
	#   - An invalid sample (NaN/Inf X or Y, value forbidden by the active
	#     axis scale, or dropped by the negative policy in STACKED mode)
	#     is handled according to gap_policy:
	#     - SKIP   flushes the current run and starts a new one.
	#     - BRIDGE drops the sample and keeps appending into the same run.
	#   - A run of fewer than two points is discarded.
	func _draw_series(p_series_index: int, p_stacked: StackedSeriesValues) -> void:
		if _get_x_axis_config().type == TauAxisConfig.Type.CATEGORICAL:
			_draw_series_categorical(p_series_index, p_stacked)
		else:
			_draw_series_continuous(p_series_index, p_stacked)


	func _draw_series_continuous(p_series_index: int, p_stacked: StackedSeriesValues) -> void:
		var series_id := _get_line_series_id(p_series_index)
		var global_series_index := _get_global_series_index(p_series_index)
		var width_px: float = _line_style.get_series_width_px(global_series_index)
		if width_px <= 0.0:
			return
		var dash_px: int = _line_style.get_series_dash_px(global_series_index)
		var hover_width_px: float = max(_line_style.get_series_hovered_width_px(global_series_index), width_px)
		var y_axis_id := _get_y_axis_id_for_series(series_id)
		var bridge: bool = _line_config.gap_policy == TauLineConfig.GapPolicy.BRIDGE
		var interpolation: TauLineConfig.InterpolationMode = _line_config.interpolation_mode

		# Resolved once per series: every run of this series fills against the
		# same baseline and the same color, and uses the same UV reference frame.
		var fill: TauLineFill = _line_style.get_series_fill(global_series_index)
		var fill_color: Color = _resolve_series_fill_color(global_series_index, fill)
		var baseline_y_px: float = _resolve_fill_baseline_y_px(y_axis_id)
		var fill_uv_ctx: _FillUVContext = _resolve_fill_uv_context(fill, y_axis_id)

		var independent_y: PackedFloat64Array
		if p_stacked == null:
			independent_y = _build_independent_y_row(series_id)

		var run := PackedVector2Array()
		var run_colors := PackedColorArray()
		# Parallel arrays describing the real samples appended to the current
		# run. real_polyline_indices[k] is the index into `run` where the k-th
		# real sample of this run landed before any post-processing
		# (SMOOTH_MONOTONE resampling). The dataset index is needed so the
		# finalizer can locate the hovered sample within the current run.
		var real_polyline_indices := PackedInt32Array()
		var real_dataset_indices := PackedInt32Array()

		var is_shared_x := _dataset.get_mode() == Dataset.Mode.SHARED_X
		var sample_count := _dataset.get_series_sample_count(series_id)

		for i in range(sample_count):
			var x_value: float = float(_dataset.get_shared_x(i)) if is_shared_x else float(_dataset.get_series_x(series_id, i))
			if is_nan(x_value) or is_inf(x_value) or not _is_x_value_valid_for_scale(x_value):
				if not bridge:
					_finalize_run(run, run_colors, real_polyline_indices, real_dataset_indices, series_id, width_px, hover_width_px, interpolation, dash_px, fill, fill_color, baseline_y_px, fill_uv_ctx)
					run = PackedVector2Array()
					run_colors = PackedColorArray()
					real_polyline_indices = PackedInt32Array()
					real_dataset_indices = PackedInt32Array()
				continue

			var y_plotted: float
			var y_raw: float
			if p_stacked != null:
				y_plotted = p_stacked.get_y_plotted(p_series_index, i)
				y_raw = p_stacked.get_y_raw(p_series_index, i)
			else:
				y_plotted = independent_y[i]
				y_raw = y_plotted

			if is_nan(y_plotted):
				if not bridge:
					_finalize_run(run, run_colors, real_polyline_indices, real_dataset_indices, series_id, width_px, hover_width_px, interpolation, dash_px, fill, fill_color, baseline_y_px, fill_uv_ctx)
					run = PackedVector2Array()
					run_colors = PackedColorArray()
					real_polyline_indices = PackedInt32Array()
					real_dataset_indices = PackedInt32Array()
				continue

			var x_px := _layout.map_x_to_px(_pane_index, x_value)
			var y_px := _layout.map_y_to_px(_pane_index, y_plotted, y_axis_id)
			var screen_pos := _layout.map_point_to_screen(x_px, y_px)
			var sample_color := _resolve_sample_color(p_series_index, i, x_value, y_raw)
			_append_with_interpolation(run, run_colors, screen_pos, sample_color, interpolation)
			# The real sample is always the last vertex appended by
			# _append_with_interpolation, regardless of the interpolation mode.
			real_polyline_indices.append(run.size() - 1)
			real_dataset_indices.append(i)

			var record := LineHitRecord.new()
			record.series_id = series_id
			record.sample_index = i
			record.x_value = x_value
			record.y_plotted_value = y_plotted
			record.y_raw_value = y_raw
			record.screen_position = screen_pos
			_hit_records.append(record)

		_finalize_run(run, run_colors, real_polyline_indices, real_dataset_indices, series_id, width_px, hover_width_px, interpolation, dash_px, fill, fill_color, baseline_y_px, fill_uv_ctx)


	func _draw_series_categorical(p_series_index: int, p_stacked: StackedSeriesValues) -> void:
		var series_id := _get_line_series_id(p_series_index)
		var global_series_index := _get_global_series_index(p_series_index)
		var width_px: float = _line_style.get_series_width_px(global_series_index)
		if width_px <= 0.0:
			return
		var dash_px: int = _line_style.get_series_dash_px(global_series_index)
		var hover_width_px: float = max(_line_style.get_series_hovered_width_px(global_series_index), width_px)
		var y_axis_id := _get_y_axis_id_for_series(series_id)
		var bridge: bool = _line_config.gap_policy == TauLineConfig.GapPolicy.BRIDGE
		var interpolation: TauLineConfig.InterpolationMode = _line_config.interpolation_mode

		# Resolved once per series: every run of this series fills against the
		# same baseline and the same color, and uses the same UV reference frame.
		var fill: TauLineFill = _line_style.get_series_fill(global_series_index)
		var fill_color: Color = _resolve_series_fill_color(global_series_index, fill)
		var baseline_y_px: float = _resolve_fill_baseline_y_px(y_axis_id)
		var fill_uv_ctx: _FillUVContext = _resolve_fill_uv_context(fill, y_axis_id)

		var independent_y: PackedFloat64Array
		if p_stacked == null:
			independent_y = _build_independent_y_row(series_id)

		var categories := _layout.domain.x_categories
		var run := PackedVector2Array()
		var run_colors := PackedColorArray()
		var real_polyline_indices := PackedInt32Array()
		var real_dataset_indices := PackedInt32Array()
		var sample_count := _dataset.get_series_sample_count(series_id)

		for cat_idx in range(sample_count):
			var y_plotted: float
			var y_raw: float
			if p_stacked != null:
				y_plotted = p_stacked.get_y_plotted(p_series_index, cat_idx)
				y_raw = p_stacked.get_y_raw(p_series_index, cat_idx)
			else:
				y_plotted = independent_y[cat_idx]
				y_raw = y_plotted

			if is_nan(y_plotted):
				if not bridge:
					_finalize_run(run, run_colors, real_polyline_indices, real_dataset_indices, series_id, width_px, hover_width_px, interpolation, dash_px, fill, fill_color, baseline_y_px, fill_uv_ctx)
					run = PackedVector2Array()
					run_colors = PackedColorArray()
					real_polyline_indices = PackedInt32Array()
					real_dataset_indices = PackedInt32Array()
				continue

			var x_px := _layout.map_x_category_center_to_px(_pane_index, cat_idx)
			var y_px := _layout.map_y_to_px(_pane_index, y_plotted, y_axis_id)
			var screen_pos := _layout.map_point_to_screen(x_px, y_px)
			var x_value: Variant = categories[cat_idx]
			var sample_color := _resolve_sample_color(p_series_index, cat_idx, x_value, y_raw)
			_append_with_interpolation(run, run_colors, screen_pos, sample_color, interpolation)
			real_polyline_indices.append(run.size() - 1)
			real_dataset_indices.append(cat_idx)

			var record := LineHitRecord.new()
			record.series_id = series_id
			record.sample_index = cat_idx
			record.x_value = x_value
			record.y_plotted_value = y_plotted
			record.y_raw_value = y_raw
			record.screen_position = screen_pos
			_hit_records.append(record)

		_finalize_run(run, run_colors, real_polyline_indices, real_dataset_indices, series_id, width_px, hover_width_px, interpolation, dash_px, fill, fill_color, baseline_y_px, fill_uv_ctx)


	# Marks dropped samples (NaN, Inf, log-axis violations) as NAN up front
	# so the inner draw loop only needs a single is_nan() check per sample.
	func _build_independent_y_row(p_series_id: int) -> PackedFloat64Array:
		var sample_count := _dataset.get_series_sample_count(p_series_id)
		var y_plotted := PackedFloat64Array()
		y_plotted.resize(sample_count)
		y_plotted.fill(NAN)
		for i in range(sample_count):
			var y := _dataset.get_series_y(p_series_id, i)
			if is_nan(y) or is_inf(y):
				continue
			if not _is_y_value_valid_for_scale(p_series_id, y):
				continue
			y_plotted[i] = y
		return y_plotted


	# Each appended sample (real or synthetic) gets the new sample's color.
	# Combined with linear interpolation by draw_polyline_colors() between
	# consecutive vertices, this places the color transition at the segment
	# leading INTO the new sample, leaving the staircase tail solid.
	func _append_with_interpolation(p_run: PackedVector2Array, p_run_colors: PackedColorArray, p_point: Vector2, p_color: Color, p_mode: TauLineConfig.InterpolationMode) -> void:
		# SMOOTH_MONOTONE buffers raw sample points untouched: cubic resampling
		# requires the full neighborhood of every sample to compute tangents and
		# is therefore deferred to _finalize_run().
		if p_run.size() == 0 or p_mode == TauLineConfig.InterpolationMode.LINEAR or p_mode == TauLineConfig.InterpolationMode.SMOOTH_MONOTONE:
			p_run.append(p_point)
			p_run_colors.append(p_color)
			return

		var last_pt: Vector2 = p_run[p_run.size() - 1]
		match p_mode:
			TauLineConfig.InterpolationMode.STEP_BEFORE:
				p_run.append(Vector2(last_pt.x, p_point.y))
				p_run_colors.append(p_color)
			TauLineConfig.InterpolationMode.STEP_AFTER:
				p_run.append(Vector2(p_point.x, last_pt.y))
				p_run_colors.append(p_color)
			TauLineConfig.InterpolationMode.STEP_MIDDLE:
				var mid_x: float = (last_pt.x + p_point.x) * 0.5
				p_run.append(Vector2(mid_x, last_pt.y))
				p_run_colors.append(p_color)
				p_run.append(Vector2(mid_x, p_point.y))
				p_run_colors.append(p_color)
		p_run.append(p_point)
		p_run_colors.append(p_color)


	# Draw the polyline for one buffered run.
	# For LINEAR and the step modes the buffered run is already the final polyline.
	# For SMOOTH_MONOTONE the run is first replaced by its Fritsch-Carlson piecewise cubic resampling.
	# Runs of fewer than two points are silently dropped.
	#
	# When p_fill_color has non-zero alpha and p_baseline_y_px is finite,
	# the area between the rendered polyline and the horizontal baseline
	# is filled before the line is drawn. The polygon is split at every
	# baseline crossing into same-side sub-polygons, each emitted as one
	# draw call. The line itself is unaffected by splitting.
	#
	# Path selection per series (no hover):
	#   - p_dash_px == 0: one draw_polyline_colors call.
	#   - p_dash_px  > 0: one draw_multiline_colors call after dash precomputation.
	#
	# When the hovered sample belongs to this run, the polyline is split into
	# up to three contiguous parts and each part is drawn with its own draw
	# call:
	#   - Part A: vertices [0 .. slice_start], drawn at p_width_px.
	#   - Part B: vertices [slice_start .. slice_end], drawn at p_hover_width_px.
	#   - Part C: vertices [slice_end .. last], drawn at p_width_px.
	# slice_start is the polyline index of the hovered sample's previous real
	# neighbor, or the hovered sample itself when it has no previous neighbor
	# in this run. slice_end is the index of the next real neighbor, or the
	# hovered sample itself when it has none. For dashed lines, the dash phase
	# is carried across parts using each part's cumulative arc-length offset
	# from the polyline start, so the dash pattern stays continuous through
	# the slices.
	#
	# p_real_polyline_indices and p_real_dataset_indices are parallel arrays
	# whose length equals the number of real samples appended to this run.
	# real_polyline_indices[k] is the index in p_run where the k-th real
	# sample landed. real_dataset_indices[k] is the dataset sample index for
	# that real sample.
	func _finalize_run(p_run: PackedVector2Array, p_run_colors: PackedColorArray, p_real_polyline_indices: PackedInt32Array, p_real_dataset_indices: PackedInt32Array, p_series_id: int, p_width_px: float, p_hover_width_px: float, p_mode: TauLineConfig.InterpolationMode, p_dash_px: int, p_fill: TauLineFill, p_fill_color: Color, p_baseline_y_px: float, p_fill_uv_ctx: _FillUVContext) -> void:
		var polyline: PackedVector2Array = p_run
		var polyline_colors: PackedColorArray = p_run_colors
		var real_polyline_indices: PackedInt32Array = p_real_polyline_indices
		if p_mode == TauLineConfig.InterpolationMode.SMOOTH_MONOTONE and p_run.size() > 2:
			var resampled := _resample_smooth_monotone(p_run, p_run_colors)
			polyline = resampled[0]
			polyline_colors = resampled[1]
			# In SMOOTH_MONOTONE the input run holds only real samples, so
			# every entry in p_real_polyline_indices is its own input index
			# and the resample's input-to-output map is the new mapping.
			real_polyline_indices = resampled[2]
		if polyline.size() < 2:
			return

		# Fill is drawn first so the polyline lands on top of it. A NaN
		# baseline or zero-alpha color means no fill for this run.
		if not is_nan(p_baseline_y_px) and p_fill_color.a > 0.0:
			_draw_fill_to_baseline(polyline, p_fill, p_fill_color, p_baseline_y_px, p_fill_uv_ctx)

		var dash_px: int = max(p_dash_px, 0)
		var slice_bounds := _resolve_hover_slice_bounds(real_polyline_indices, p_real_dataset_indices, p_series_id)

		if slice_bounds.is_empty():
			# No hover emphasis: draw the entire polyline in a single call.
			_draw_polyline_segment(polyline, polyline_colors, 0, polyline.size() - 1, p_width_px, dash_px, 0.0)
			return

		var slice_start: int = slice_bounds[0]
		var slice_end: int = slice_bounds[1]
		var last: int = polyline.size() - 1

		# Precompute cumulative arc length so each part inherits a starting
		# phase that keeps the dash pattern continuous across the slices.
		# When dash_px is 0 the offsets are still computed but ignored by the
		# solid path.
		var arc_at_slice_start: float = _arc_length_to_index(polyline, slice_start)
		var arc_at_slice_end: float = arc_at_slice_start + _arc_length_between(polyline, slice_start, slice_end)

		# Part A: from the polyline start up to and including slice_start.
		_draw_polyline_segment(polyline, polyline_colors, 0, slice_start, p_width_px, dash_px, 0.0)
		# Part B: the two adjacent portions, emphasized.
		_draw_polyline_segment(polyline, polyline_colors, slice_start, slice_end, p_hover_width_px, dash_px, arc_at_slice_start)
		# Part C: from slice_end to the polyline end.
		_draw_polyline_segment(polyline, polyline_colors, slice_end, last, p_width_px, dash_px, arc_at_slice_end)


	# Resolves the polyline-vertex bounds of the hover-emphasized slice for
	# the current run, or an empty array when no emphasis applies.
	#
	# Returns [slice_start, slice_end] when the hovered sample belongs to the
	# current run and has at least one real neighbor that produces a non-zero
	# slice. slice_start is the polyline index of the previous real neighbor
	# (or the hovered sample itself when it has no previous neighbor).
	# slice_end is the polyline index of the next real neighbor (or the
	# hovered sample itself when it has none).
	#
	# When the hovered sample has been deduplicated by SMOOTH_MONOTONE
	# resampling (consecutive real samples sharing the same screen X), it
	# shares its polyline index with the surviving neighbor it was deduped
	# against, so the slice still covers the right neighborhood.
	func _resolve_hover_slice_bounds(p_real_polyline_indices: PackedInt32Array, p_real_dataset_indices: PackedInt32Array, p_series_id: int) -> PackedInt32Array:
		if not _highlight_active or _hovered_series_id != p_series_id or _hovered_sample_index < 0:
			return PackedInt32Array()
		var real_count: int = p_real_dataset_indices.size()
		if real_count <= 1:
			return PackedInt32Array()

		var hover_pos_in_run: int = -1
		for k in range(real_count):
			if p_real_dataset_indices[k] == _hovered_sample_index:
				hover_pos_in_run = k
				break
		if hover_pos_in_run < 0:
			return PackedInt32Array()

		var hovered_idx: int = p_real_polyline_indices[hover_pos_in_run]
		var slice_start: int = hovered_idx
		if hover_pos_in_run > 0:
			slice_start = p_real_polyline_indices[hover_pos_in_run - 1]
		var slice_end: int = hovered_idx
		if hover_pos_in_run < real_count - 1:
			slice_end = p_real_polyline_indices[hover_pos_in_run + 1]

		if slice_end <= slice_start:
			return PackedInt32Array()

		var bounds := PackedInt32Array()
		bounds.append(slice_start)
		bounds.append(slice_end)
		return bounds


	# Draws a contiguous polyline part bounded by the given vertex indices,
	# inclusive on both ends. Dispatches to draw_polyline_colors or _draw_dashed_polyline
	# based on p_dash_px. p_phase_offset seeds the dash phase tracker so
	# callers can chain multiple parts with continuous phase across slice
	# boundaries.
	#
	# Parts of length less than 2 are skipped: a single-vertex slice cannot
	# produce any drawable segment.
	func _draw_polyline_segment(p_polyline: PackedVector2Array, p_polyline_colors: PackedColorArray, p_first: int, p_last: int, p_width_px: float, p_dash_px: int, p_phase_offset: float) -> void:
		if p_last <= p_first:
			return
		# A non-fragmented full run is the common case: avoid the slice copy.
		if p_first == 0 and p_last == p_polyline.size() - 1:
			if p_dash_px <= 0:
				draw_polyline_colors(p_polyline, p_polyline_colors, p_width_px)
			else:
				_draw_dashed_polyline(p_polyline, p_polyline_colors, p_width_px, float(p_dash_px), p_phase_offset)
			return

		var sub_polyline := PackedVector2Array()
		var sub_colors := PackedColorArray()
		var sub_size: int = p_last - p_first + 1
		sub_polyline.resize(sub_size)
		sub_colors.resize(sub_size)
		for j in range(sub_size):
			sub_polyline[j] = p_polyline[p_first + j]
			sub_colors[j] = p_polyline_colors[p_first + j]

		if p_dash_px <= 0:
			draw_polyline_colors(sub_polyline, sub_colors, p_width_px)
		else:
			_draw_dashed_polyline(sub_polyline, sub_colors, p_width_px, float(p_dash_px), p_phase_offset)


	func _arc_length_to_index(p_polyline: PackedVector2Array, p_index: int) -> float:
		if p_index <= 0:
			return 0.0
		var total: float = 0.0
		for i in range(p_index):
			total += p_polyline[i].distance_to(p_polyline[i + 1])
		return total


	func _arc_length_between(p_polyline: PackedVector2Array, p_first: int, p_last: int) -> float:
		if p_last <= p_first:
			return 0.0
		var total: float = 0.0
		for i in range(p_first, p_last):
			total += p_polyline[i].distance_to(p_polyline[i + 1])
		return total


	# Builds the flat segment array of "on" dash intervals along p_polyline and
	# draws it with a single draw_multiline_colors() call. The dash period is
	# 2 * p_dash_px (one "on" length followed by one "off" length of equal
	# size). Dash phase is tracked as a single scalar that advances along the
	# polyline arc length, so the pattern is continuous across consecutive
	# segments and does not reset at sample positions.
	#
	# p_phase_offset seeds the phase tracker at the start of the polyline,
	# expressed in pixels of arc length. It lets a caller draw a contiguous
	# polyline as multiple back-to-back parts (each with its own draw call)
	# and keep the dash pattern continuous across the part boundaries: each
	# subsequent part passes the cumulative arc length from the original
	# polyline start as its phase offset.
	#
	# draw_multiline_colors takes one solid color per drawn segment (a pair
	# of points). Each "on" interval gets the color of its midpoint along the
	# enclosing polyline segment, computed by linear interpolation between the
	# two flanking polyline-vertex colors. For typical dash sizes this is a
	# good approximation of the per-vertex color gradient produced by the
	# undashed path.
	#
	# Degenerate segments (zero length) are skipped: they cannot carry any
	# dash and do not advance the phase.
	func _draw_dashed_polyline(p_polyline: PackedVector2Array, p_polyline_colors: PackedColorArray, p_width_px: float, p_dash_px: float, p_phase_offset: float = 0.0) -> void:
		var period: float = p_dash_px * 2.0
		var n := p_polyline.size()
		var phase: float = fposmod(p_phase_offset, period)
		var segments := PackedVector2Array()
		var segment_colors := PackedColorArray()

		for i in range(n - 1):
			var seg_start: Vector2 = p_polyline[i]
			var seg_end: Vector2 = p_polyline[i + 1]
			var seg_vec: Vector2 = seg_end - seg_start
			var seg_len: float = seg_vec.length()
			if seg_len <= 0.0:
				continue

			var seg_dir: Vector2 = seg_vec / seg_len
			var col_start: Color = p_polyline_colors[i]
			var col_end: Color = p_polyline_colors[i + 1]

			# Position along the current segment, in pixels from seg_start.
			# Phase 0..p_dash_px is "on", p_dash_px..period is "off".
			var pos: float = 0.0
			while pos < seg_len:
				var phase_in_period: float = phase
				if phase_in_period < p_dash_px:
					# Currently inside an "on" interval.
					var remaining_on: float = p_dash_px - phase_in_period
					var on_end: float = min(pos + remaining_on, seg_len)
					segments.append(seg_start + seg_dir * pos)
					segments.append(seg_start + seg_dir * on_end)
					var midpoint_t: float = ((pos + on_end) * 0.5) / seg_len
					segment_colors.append(col_start.lerp(col_end, midpoint_t))
					var consumed: float = on_end - pos
					phase += consumed
					pos = on_end
				else:
					# Currently inside an "off" interval.
					var remaining_off: float = period - phase_in_period
					var off_end: float = min(pos + remaining_off, seg_len)
					var consumed_off: float = off_end - pos
					phase += consumed_off
					pos = off_end

				if phase >= period:
					phase -= period

		if segments.size() >= 2:
			draw_multiline_colors(segments, segment_colors, p_width_px)

	####################################################################################################
	# Area fill
	####################################################################################################

	# Bundle of values driving the per-vertex UV array computed for one
	# textured fill polygon. Built once per series, then consumed by
	# _build_polygon_uvs for every sub-polygon of that series.
	#
	# Two parameter sets coexist, selected by mode:
	#   - STRETCH samples the texture once across stretch_span along
	#     stretch_axis. pane_rect, u_flip, and v_flip drive PANE and POLYGON
	#     spans. BASELINE reads V from the polygon's top vs closing-edge
	#     vertex layout and ignores the flip flags.
	#   - TILE samples the texture in screen pixels around pane_center.
	#     rotation_cos and rotation_sin hold cos/sin of -rotation_deg, so
	#     the per-vertex math runs the standard rotation formula on the
	#     centered screen pixel. inv_tile_size is the reciprocal of
	#     (texture native size * scale) along each axis.
	#
	# texture is null for flat fills. In that case the polygon UV array is
	# not built at all, every other field is unused, and the draw call's
	# uv argument stays empty.
	class _FillUVContext extends RefCounted:
		var texture: Texture2D = null

		# STRETCH
		var pane_rect: Rect2 = Rect2()
		var u_flip: bool = false
		var v_flip: bool = false

		# TILE
		var pane_center: Vector2 = Vector2.ZERO
		var rotation_cos: float = 1.0
		var rotation_sin: float = 0.0
		var offset_px: Vector2 = Vector2.ZERO
		var inv_tile_size: Vector2 = Vector2.ZERO


	# Resolves the fill UV context for p_fill bound to p_y_axis_id.
	# Returns a context with texture = null when fill_mode is not
	# TO_BASELINE or when p_fill has no texture, so the caller can skip UV
	# construction entirely. mode, stretch_axis, and stretch_span are not
	# derived and are read directly from p_fill by the callers that need
	# them.
	func _resolve_fill_uv_context(p_fill: TauLineFill, p_y_axis_id: AxisId) -> _FillUVContext:
		var ctx := _FillUVContext.new()
		if _line_config.fill_mode != TauLineConfig.FillMode.TO_BASELINE:
			return ctx
		ctx.texture = p_fill.texture
		if ctx.texture == null:
			return ctx

		var pane_rect: Rect2 = _layout.get_pane_rect(_pane_index)

		match p_fill.texture_mode:
			TauLineFill.FillTextureMode.STRETCH:
				ctx.pane_rect = pane_rect
				# Axis-direction flips match the data-axis convention used
				# by XYLayout.map_x_to_px / map_y_to_px, so PANE and POLYGON
				# UVs align with the data x/y direction regardless of pane
				# orientation or axis inversion. BASELINE reads V from the
				# polygon layout instead, so these flags do not apply there.
				var x_is_horizontal: bool = _layout._x_is_horizontal
				var x_axis_cfg: TauAxisConfig = _layout.domain.config.x_axis
				ctx.u_flip = (not x_is_horizontal) != x_axis_cfg.inverted
				var pane_domain := _layout.domain.get_pane_domain(_pane_index)
				var y_axis_domain := pane_domain.get_y_axis_domain(p_y_axis_id)
				var y_axis_cfg: TauAxisConfig = y_axis_domain.config
				ctx.v_flip = x_is_horizontal != y_axis_cfg.inverted

			TauLineFill.FillTextureMode.TILE:
				ctx.pane_center = pane_rect.position + pane_rect.size * 0.5
				ctx.offset_px = p_fill.tile_offset_px
				# The screen pixel is rotated into the texture's frame,
				# which is the inverse of rotating the tile grid on screen.
				# Negating the user-facing angle once here keeps the
				# per-vertex math on the standard rotation formula.
				var theta: float = deg_to_rad(-p_fill.tile_rotation_deg)
				ctx.rotation_cos = cos(theta)
				ctx.rotation_sin = sin(theta)
				var tex_size: Vector2 = ctx.texture.get_size()
				var scale: float = p_fill.tile_scale
				var tile_w: float = tex_size.x * scale
				var tile_h: float = tex_size.y * scale
				var inv_w: float = 1.0 / tile_w if tile_w > 0.0 else 0.0
				var inv_h: float = 1.0 / tile_h if tile_h > 0.0 else 0.0
				ctx.inv_tile_size = Vector2(inv_w, inv_h)

		return ctx


	# Dispatches to the active UV path. p_top_count is the number of
	# leading vertices in p_polygon that lie on the line (the polyline run
	# the fill was built from). The remaining vertices are the closing
	# edge. Only the BASELINE stretch path reads p_top_count, the others
	# treat every vertex uniformly.
	func _build_polygon_uvs(p_polygon: PackedVector2Array, p_top_count: int, p_fill: TauLineFill, p_fill_uv_ctx: _FillUVContext) -> PackedVector2Array:
		match p_fill.texture_mode:
			TauLineFill.FillTextureMode.STRETCH:
				match p_fill.stretch_span:
					TauLineFill.FillStretchSpan.PANE:
						return _build_polygon_uvs_stretch_pane(p_polygon, p_fill, p_fill_uv_ctx)
					TauLineFill.FillStretchSpan.POLYGON:
						return _build_polygon_uvs_stretch_polygon(p_polygon, p_fill, p_fill_uv_ctx)
					TauLineFill.FillStretchSpan.BASELINE:
						return _build_polygon_uvs_stretch_baseline(p_polygon, p_top_count)
			TauLineFill.FillTextureMode.TILE:
				return _build_polygon_uvs_tile(p_polygon, p_fill_uv_ctx)
		return PackedVector2Array()


	# STRETCH + PANE. The texture spans the whole pane in the stretch
	# direction. The non-stretch axis reads at UV coordinate 0. A degenerate
	# pane with zero extent on the stretch axis collapses every vertex to
	# UV 0.
	static func _build_polygon_uvs_stretch_pane(p_polygon: PackedVector2Array, p_fill: TauLineFill, p_fill_uv_ctx: _FillUVContext) -> PackedVector2Array:
		var count: int = p_polygon.size()
		var uvs := PackedVector2Array()
		uvs.resize(count)
		var pane: Rect2 = p_fill_uv_ctx.pane_rect
		if p_fill.stretch_axis == TauLineFill.FillStretchAxis.Y:
			var inv_h: float = 1.0 / pane.size.y if pane.size.y > 0.0 else 0.0
			var origin: float = pane.position.y
			var flip: bool = p_fill_uv_ctx.v_flip
			for k in range(count):
				var v: float = (p_polygon[k].y - origin) * inv_h
				if flip:
					v = 1.0 - v
				uvs[k] = Vector2(0.0, v)
		else:
			var inv_w: float = 1.0 / pane.size.x if pane.size.x > 0.0 else 0.0
			var origin: float = pane.position.x
			var flip: bool = p_fill_uv_ctx.u_flip
			for k in range(count):
				var u: float = (p_polygon[k].x - origin) * inv_w
				if flip:
					u = 1.0 - u
				uvs[k] = Vector2(u, 0.0)
		return uvs


	# STRETCH + POLYGON. The texture spans the polygon's axis-aligned
	# bounding box in the stretch direction. The non-stretch axis reads at
	# UV coordinate 0. A degenerate polygon with zero extent on the stretch
	# axis collapses every vertex to UV 0.
	static func _build_polygon_uvs_stretch_polygon(p_polygon: PackedVector2Array, p_fill: TauLineFill, p_fill_uv_ctx: _FillUVContext) -> PackedVector2Array:
		var count: int = p_polygon.size()
		var uvs := PackedVector2Array()
		uvs.resize(count)
		var bb: Rect2 = _compute_polygon_bounds(p_polygon)
		if p_fill.stretch_axis == TauLineFill.FillStretchAxis.Y:
			var inv_h: float = 1.0 / bb.size.y if bb.size.y > 0.0 else 0.0
			var origin: float = bb.position.y
			var flip: bool = p_fill_uv_ctx.v_flip
			for k in range(count):
				var v: float = (p_polygon[k].y - origin) * inv_h
				if flip:
					v = 1.0 - v
				uvs[k] = Vector2(0.0, v)
		else:
			var inv_w: float = 1.0 / bb.size.x if bb.size.x > 0.0 else 0.0
			var origin: float = bb.position.x
			var flip: bool = p_fill_uv_ctx.u_flip
			for k in range(count):
				var u: float = (p_polygon[k].x - origin) * inv_w
				if flip:
					u = 1.0 - u
				uvs[k] = Vector2(u, 0.0)
		return uvs


	# STRETCH + BASELINE. The polygon's first p_top_count vertices sit on
	# the line and get V = 0, the remaining vertices sit on the closing
	# edge and get V = 1. The texture's V = 0 edge therefore always lands
	# on the line, no axis-inversion flip needed. U is 0 for every vertex.
	# Only valid with stretch_axis = Y, enforced by LineValidator.
	static func _build_polygon_uvs_stretch_baseline(p_polygon: PackedVector2Array, p_top_count: int) -> PackedVector2Array:
		var count: int = p_polygon.size()
		var uvs := PackedVector2Array()
		uvs.resize(count)
		for k in range(count):
			var v: float = 0.0 if k < p_top_count else 1.0
			uvs[k] = Vector2(0.0, v)
		return uvs


	# TILE. The screen pixel is centered on the pane center, rotated into
	# the texture's frame, translated by offset_px, then divided by
	# (texture_size * scale) to produce the texture coordinate. The grid
	# stays square-pixel correct because both axes share the same screen
	# pixel units.
	static func _build_polygon_uvs_tile(p_polygon: PackedVector2Array, p_fill_uv_ctx: _FillUVContext) -> PackedVector2Array:
		var count: int = p_polygon.size()
		var uvs := PackedVector2Array()
		uvs.resize(count)
		var cx: float = p_fill_uv_ctx.pane_center.x
		var cy: float = p_fill_uv_ctx.pane_center.y
		var c: float = p_fill_uv_ctx.rotation_cos
		var s: float = p_fill_uv_ctx.rotation_sin
		var ox: float = p_fill_uv_ctx.offset_px.x
		var oy: float = p_fill_uv_ctx.offset_px.y
		var inv_w: float = p_fill_uv_ctx.inv_tile_size.x
		var inv_h: float = p_fill_uv_ctx.inv_tile_size.y
		for k in range(count):
			var v: Vector2 = p_polygon[k]
			var dx: float = v.x - cx
			var dy: float = v.y - cy
			var rx: float = c * dx - s * dy
			var ry: float = s * dx + c * dy
			uvs[k] = Vector2((rx + ox) * inv_w, (ry + oy) * inv_h)
		return uvs


	# Returns the color passed as the modulation argument of the fill draw
	# call for one series. Three cases:
	#
	#   1. fill_mode is not TO_BASELINE. No flat fill is drawn for this
	#      series, so the return value is fully transparent black and the
	#      draw call is skipped upstream.
	#   2. p_fill has a texture. The fill is the texture and must not be
	#      tinted, so the modulation color is white. Its alpha carries
	#      p_fill.alpha, which is the only thing that scales the texture.
	#   3. p_fill has no texture. The fill is a flat color: p_fill.color,
	#      or the per-series color from TauXYStyle.series_colors when
	#      p_fill.color is TauLineFill.NO_COLOR. p_fill.alpha is then
	#      applied to its alpha channel.
	func _resolve_series_fill_color(p_global_series_index: int, p_fill: TauLineFill) -> Color:
		if _line_config.fill_mode != TauLineConfig.FillMode.TO_BASELINE:
			return Color(0, 0, 0, 0)
		if p_fill.texture != null:
			return Color(1.0, 1.0, 1.0, p_fill.alpha)
		var color: Color = p_fill.color
		if color == TauLineFill.NO_COLOR:
			color = _xy_style.get_series_color(p_global_series_index)
		color.a = clampf(color.a * p_fill.alpha, 0.0, 1.0)
		return color


	# Returns the screen-space Y coordinate of the TO_BASELINE baseline, or
	# NAN when no flat baseline applies.
	func _resolve_fill_baseline_y_px(p_y_axis_id: AxisId) -> float:
		if _line_config.fill_mode != TauLineConfig.FillMode.TO_BASELINE:
			return NAN
		var y_px: float = _layout.map_y_to_px(_pane_index, _line_config.fill_baseline, p_y_axis_id)
		var screen_pos: Vector2 = _layout.map_point_to_screen(0.0, y_px)
		return screen_pos.y


	# Builds and draws the fill polygon between p_polyline and the horizontal
	# line y = p_baseline_y_px in screen space. The polygon is split at every
	# baseline crossing, producing one sub-polygon per same-side run, each
	# emitted as a single draw_colored_polygon call.
	#
	# Crossing detection runs on the rendered polyline, so the synthetic
	# vertices inserted by step interpolation and the sub-samples emitted by
	# SMOOTH_MONOTONE are treated uniformly. A crossing point lies at the
	# linear interpolation of the two flanking polyline vertices against
	# the baseline. Both polyline orderings (ascending or descending screen
	# X) are accepted because the builder never assumes a direction.
	func _draw_fill_to_baseline(p_polyline: PackedVector2Array, p_fill: TauLineFill, p_fill_color: Color, p_baseline_y_px: float, p_fill_uv_ctx: _FillUVContext) -> void:
		var n: int = p_polyline.size()
		if n < 2:
			return

		# Same-side accumulator. The current sub-polygon's top edge is the
		# vertices buffered in `top`. `side` is the sign of (y - baseline_y)
		# for the first non-on-baseline vertex of the run, and stays 0 until
		# one is found. On-baseline vertices are appended to `top` and do
		# not constrain `side`.
		var top := PackedVector2Array()
		var side: int = 0

		for i in range(n):
			var v: Vector2 = p_polyline[i]
			var v_side: int = _baseline_side(v.y, p_baseline_y_px)

			if top.is_empty():
				top.append(v)
				side = v_side
				continue

			# Treat on-baseline as a degenerate crossing: the vertex sits on
			# both half-planes, so it can extend the current run AND open a
			# new one without a synthetic crossing.
			if v_side == 0 or side == 0 or v_side == side:
				top.append(v)
				if side == 0:
					side = v_side
				continue

			# v_side and side are non-zero and opposite: a real crossing
			# between top[-1] and v. The crossing point closes the current
			# sub-polygon and seeds the next one.
			var prev: Vector2 = top[top.size() - 1]
			var crossing: Vector2 = _baseline_crossing(prev, v, p_baseline_y_px)
			top.append(crossing)
			_draw_fill_subpolygon(top, p_fill, p_fill_color, p_baseline_y_px, p_fill_uv_ctx)
			top = PackedVector2Array()
			top.append(crossing)
			top.append(v)
			side = v_side

		_draw_fill_subpolygon(top, p_fill, p_fill_color, p_baseline_y_px, p_fill_uv_ctx)


	# Closes one sub-polygon by dropping its endpoints to the baseline and
	# draws it as a single colored polygon. The per-vertex UV array and the
	# texture, if any, are taken from p_fill_uv_ctx. Runs that contain fewer
	# than two points or that are entirely on the baseline have zero area
	# and are skipped.
	func _draw_fill_subpolygon(p_top: PackedVector2Array, p_fill: TauLineFill, p_fill_color: Color, p_baseline_y_px: float, p_fill_uv_ctx: _FillUVContext) -> void:
		var top_count: int = p_top.size()
		if top_count < 2:
			return
		# A run sitting exactly on the baseline has zero area.
		var any_off_baseline: bool = false
		for k in range(top_count):
			if p_top[k].y != p_baseline_y_px:
				any_off_baseline = true
				break
		if not any_off_baseline:
			return

		var polygon := PackedVector2Array()
		polygon.resize(top_count + 2)
		# Top edge in forward order, then closing edge down to the baseline.
		for k in range(top_count):
			polygon[k] = p_top[k]
		polygon[top_count] = Vector2(p_top[top_count - 1].x, p_baseline_y_px)
		polygon[top_count + 1] = Vector2(p_top[0].x, p_baseline_y_px)

		# UVs are only sampled when a texture is set. draw_colored_polygon
		# ignores its uv argument otherwise, so the flat-fill path skips the
		# per-vertex computation entirely.
		var uvs: PackedVector2Array = PackedVector2Array()
		if p_fill_uv_ctx.texture != null:
			uvs = _build_polygon_uvs(polygon, top_count, p_fill, p_fill_uv_ctx)
		draw_colored_polygon(polygon, p_fill_color, uvs, p_fill_uv_ctx.texture)


	# Axis-aligned bounding box of a polygon in screen space.
	static func _compute_polygon_bounds(p_polygon: PackedVector2Array) -> Rect2:
		var first: Vector2 = p_polygon[0]
		var min_x: float = first.x
		var max_x: float = first.x
		var min_y: float = first.y
		var max_y: float = first.y
		for k in range(1, p_polygon.size()):
			var v: Vector2 = p_polygon[k]
			if v.x < min_x:
				min_x = v.x
			elif v.x > max_x:
				max_x = v.x
			if v.y < min_y:
				min_y = v.y
			elif v.y > max_y:
				max_y = v.y
		return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


	# Returns +1 above the baseline (smaller screen Y), -1 below, 0 on it.
	# Screen space is Y-down so "above the baseline in data space" means
	# "smaller Y in screen space".
	static func _baseline_side(p_y: float, p_baseline_y: float) -> int:
		if p_y < p_baseline_y:
			return 1
		if p_y > p_baseline_y:
			return -1
		return 0


	# Linear interpolation along segment (p_a, p_b) at the parameter where
	# y reaches p_baseline_y. Precondition: p_a.y and p_b.y straddle
	# p_baseline_y with a non-zero gap, which is guaranteed by the caller.
	static func _baseline_crossing(p_a: Vector2, p_b: Vector2, p_baseline_y: float) -> Vector2:
		var t: float = (p_baseline_y - p_a.y) / (p_b.y - p_a.y)
		return Vector2(p_a.x + t * (p_b.x - p_a.x), p_baseline_y)


	####################################################################################################
	# Smooth-monotone (Fritsch-Carlson) resampling
	####################################################################################################

	# Builds the Fritsch-Carlson piecewise cubic Hermite curve through p_points
	# and returns it sampled at _SMOOTH_SUBDIVISIONS sub-segments per input
	# segment, paired with a colors array sampled in lock-step. Operates in
	# screen space (the input is already in pixels), which keeps the curve
	# visually smooth regardless of axis scale.
	#
	# The algorithm requires strictly monotonic X. The expected case is
	# monotonically increasing screen X, but a user-inverted X axis produces
	# monotonically decreasing screen X. Both directions are accepted: the
	# input is processed internally on a strictly increasing X copy and the
	# output is reversed back when needed. Consecutive points sharing the same
	# screen X are dropped since the secant slope is undefined at h = 0. The
	# matching color entries are dropped at the same indices.
	# Inputs that are not monotonic in either direction fall back to the raw
	# polyline for that run and push a one-shot warning.
	#
	# Sub-sample colors are linearly interpolated between the two flanking
	# kept-sample colors so that the visual color gradient matches what
	# draw_polyline_colors would produce on a LINEAR polyline through the
	# same kept samples.
	#
	# Returns [points: PackedVector2Array, colors: PackedColorArray, input_to_output: PackedInt32Array].
	# input_to_output[i] is the index in the returned points array where input point i lands.
	# Dropped inputs (consecutive same-screen-X duplicates) inherit the output index of the
	# neighbor they were deduplicated against.
	func _resample_smooth_monotone(p_points: PackedVector2Array, p_colors: PackedColorArray) -> Array:
		var input_count := p_points.size()
		var direction := _detect_monotonic_x_direction(p_points)
		if direction == 0:
			if not _smooth_non_monotonic_warned:
				push_warning("LineRenderer: SMOOTH_MONOTONE received samples whose screen X is not monotonic. Falling back to a straight polyline for the affected run. Use LINEAR interpolation if your data does not have a monotonic X parameter.")
				_smooth_non_monotonic_warned = true
			var identity := PackedInt32Array()
			identity.resize(input_count)
			for i in range(input_count):
				identity[i] = i
			return [p_points, p_colors, identity]

		var ascending: bool = direction > 0

		# Build strictly increasing X arrays, dropping flat-X duplicates.
		# Colors are kept in lock-step with the kept points. kept_of[i] is the
		# kept-array index for original input i, used later to remap real
		# samples to their output-polyline position. Dropped inputs share
		# their surviving neighbor's kept index.
		var xs := PackedFloat32Array()
		var ys := PackedFloat32Array()
		var cs := PackedColorArray()
		var kept_of := PackedInt32Array()
		kept_of.resize(input_count)
		if ascending:
			xs.append(p_points[0].x)
			ys.append(p_points[0].y)
			cs.append(p_colors[0])
			kept_of[0] = 0
			for i in range(1, input_count):
				if p_points[i].x > xs[xs.size() - 1]:
					xs.append(p_points[i].x)
					ys.append(p_points[i].y)
					cs.append(p_colors[i])
				kept_of[i] = xs.size() - 1
		else:
			xs.append(p_points[input_count - 1].x)
			ys.append(p_points[input_count - 1].y)
			cs.append(p_colors[input_count - 1])
			kept_of[input_count - 1] = 0
			for i in range(input_count - 2, -1, -1):
				if p_points[i].x > xs[xs.size() - 1]:
					xs.append(p_points[i].x)
					ys.append(p_points[i].y)
					cs.append(p_colors[i])
				kept_of[i] = xs.size() - 1

		var n := xs.size()
		if n < 2:
			# All inputs collapsed to a single screen X. Nothing to draw.
			var empty_map := PackedInt32Array()
			empty_map.resize(input_count)
			return [PackedVector2Array(), PackedColorArray(), empty_map]
		if n == 2:
			# Two distinct X values produce a straight line through Hermite
			# with both tangents equal to the secant slope. Short-circuit.
			var trivial := PackedVector2Array()
			var trivial_colors := PackedColorArray()
			trivial.append(Vector2(xs[0], ys[0]))
			trivial.append(Vector2(xs[1], ys[1]))
			trivial_colors.append(cs[0])
			trivial_colors.append(cs[1])
			if not ascending:
				trivial.reverse()
				trivial_colors.reverse()
			var trivial_map := PackedInt32Array()
			trivial_map.resize(input_count)
			for i in range(input_count):
				var kept_idx: int = kept_of[i]
				if ascending:
					trivial_map[i] = kept_idx
				else:
					trivial_map[i] = 1 - kept_idx
			return [trivial, trivial_colors, trivial_map]

		var tangents := _fritsch_carlson_tangents(xs, ys)

		var out := PackedVector2Array()
		var out_colors := PackedColorArray()
		# Pre-size the outputs for speed: n-1 segments times subdivisions plus
		# the very first sample.
		var out_size: int = 1 + (n - 1) * _SMOOTH_SUBDIVISIONS
		out.resize(out_size)
		out_colors.resize(out_size)
		out[0] = Vector2(xs[0], ys[0])
		out_colors[0] = cs[0]

		var write_index: int = 1
		var inv_subs: float = 1.0 / float(_SMOOTH_SUBDIVISIONS)
		for k in range(n - 1):
			var x0: float = xs[k]
			var x1: float = xs[k + 1]
			var y0: float = ys[k]
			var y1: float = ys[k + 1]
			var h: float = x1 - x0
			var m0: float = tangents[k]
			var m1: float = tangents[k + 1]
			var c0: Color = cs[k]
			var c1: Color = cs[k + 1]

			# Sub-points at t = 1/N, 2/N, ..., 1. The endpoint t=1 is the next
			# sample, included here so the next segment begins at t=1/N.
			for s in range(1, _SMOOTH_SUBDIVISIONS + 1):
				var t: float = float(s) * inv_subs
				var t2: float = t * t
				var t3: float = t2 * t
				var h00: float = 2.0 * t3 - 3.0 * t2 + 1.0
				var h10: float = t3 - 2.0 * t2 + t
				var h01: float = -2.0 * t3 + 3.0 * t2
				var h11: float = t3 - t2
				var x: float = x0 + t * h
				var y: float = h00 * y0 + h10 * h * m0 + h01 * y1 + h11 * h * m1
				out[write_index] = Vector2(x, y)
				out_colors[write_index] = c0.lerp(c1, t)
				write_index += 1

		if not ascending:
			out.reverse()
			out_colors.reverse()

		# Build the input-to-output index map. In the ascending output, kept
		# input k sits at out[k * SUBS]. When the output is reversed for a
		# descending input, that position becomes (out_size - 1 - k * SUBS).
		var input_to_output := PackedInt32Array()
		input_to_output.resize(input_count)
		for i in range(input_count):
			var kept_idx: int = kept_of[i]
			var out_idx: int = kept_idx * _SMOOTH_SUBDIVISIONS
			if not ascending:
				out_idx = out_size - 1 - out_idx
			input_to_output[i] = out_idx

		return [out, out_colors, input_to_output]


	# Returns +1 if screen X is strictly monotonically increasing across the
	# whole run, -1 if strictly decreasing, 0 if neither (some pair has equal
	# X) or the run has fewer than 2 points. Equal consecutive X is allowed
	# only as a single-point run (n < 2 case).
	func _detect_monotonic_x_direction(p_points: PackedVector2Array) -> int:
		var n := p_points.size()
		if n < 2:
			return 0
		var first_diff: float = p_points[1].x - p_points[0].x
		# Find the first non-zero diff to set the direction. Equal-X pairs in
		# the middle of an otherwise increasing run are tolerated and dropped
		# by the caller, so they do not invalidate monotonicity here.
		var direction: int = 0
		if first_diff > 0.0:
			direction = 1
		elif first_diff < 0.0:
			direction = -1
		for i in range(2, n):
			var diff: float = p_points[i].x - p_points[i - 1].x
			if diff > 0.0:
				if direction == -1:
					return 0
				direction = 1
			elif diff < 0.0:
				if direction == 1:
					return 0
				direction = -1
		return direction


	# Fritsch-Carlson tangent computation. Returns one tangent per input point
	# such that the resulting piecewise cubic Hermite curve is monotone where
	# the data is monotone and never overshoots its data values.
	#
	# Reference: Fritsch, F. N. and Carlson, R. E. (1980), "Monotone Piecewise
	# Cubic Interpolation", SIAM Journal on Numerical Analysis, 17 (2): 238-246.
	#
	# Precondition: xs is strictly increasing and xs.size() == ys.size() >= 2.
	func _fritsch_carlson_tangents(p_xs: PackedFloat32Array, p_ys: PackedFloat32Array) -> PackedFloat32Array:
		var n := p_xs.size()
		var m := PackedFloat32Array()
		m.resize(n)

		# Secant slopes between consecutive samples.
		var d := PackedFloat32Array()
		d.resize(n - 1)
		for k in range(n - 1):
			d[k] = (p_ys[k + 1] - p_ys[k]) / (p_xs[k + 1] - p_xs[k])

		# Initial tangents: endpoint tangents copy the adjacent secant slope.
		# Interior tangents are zero at extrema and the average of the two
		# adjacent secants otherwise.
		m[0] = d[0]
		m[n - 1] = d[n - 2]
		for k in range(1, n - 1):
			if d[k - 1] * d[k] <= 0.0:
				m[k] = 0.0
			else:
				m[k] = 0.5 * (d[k - 1] + d[k])

		# Fritsch-Carlson monotonicity correction. For each segment, project
		# the (m[k], m[k+1]) pair onto the disk of radius 3 in the (alpha,
		# beta) plane to guarantee no overshoot.
		for k in range(n - 1):
			if d[k] == 0.0:
				m[k] = 0.0
				m[k + 1] = 0.0
				continue
			var alpha: float = m[k] / d[k]
			var beta: float = m[k + 1] / d[k]
			if alpha < 0.0:
				m[k] = 0.0
				alpha = 0.0
			if beta < 0.0:
				m[k + 1] = 0.0
				beta = 0.0
			var sq: float = alpha * alpha + beta * beta
			if sq > 9.0:
				var tau: float = 3.0 / sqrt(sq)
				m[k] = tau * alpha * d[k]
				m[k + 1] = tau * beta * d[k]

		return m


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
	# Per-sample color and alpha resolution
	####################################################################################################

	# Combined per-sample color resolution. Alpha overwrites the resolved
	# color's alpha channel, then the result is routed through the
	# hover-highlight callback when active.
	func _resolve_sample_color(p_series_index: int, p_sample_index: int, p_x_value: Variant, p_y_value: float) -> Color:
		var base := _resolve_sample_color_only(p_series_index, p_sample_index, p_x_value, p_y_value)
		var alpha := _resolve_sample_alpha(p_series_index, p_sample_index, p_x_value, p_y_value)
		base.a = clampf(alpha, 0.0, 1.0)
		return _apply_hover_color(base, _get_line_series_id(p_series_index), p_sample_index)


	# Applies the hover-highlight callback (or the built-in dim/brighten
	# default) to a resolved per-sample color. Returns the color unchanged
	# when the highlight feature is off.
	func _apply_hover_color(p_color: Color, p_series_id: int, p_sample_index: int) -> Color:
		if not _highlight_active:
			return p_color
		var is_hovered: bool = (p_series_id == _hovered_series_id) and (p_sample_index == _hovered_sample_index)
		if _hover_highlight_callback.is_valid():
			return _hover_highlight_callback.call(p_color, is_hovered)
		if is_hovered:
			return p_color.lightened(0.15)
		return Color(p_color, 0.5)


	func _resolve_sample_color_only(p_series_index: int, p_sample_index: int, p_x_value: Variant, p_y_value: float) -> Color:
		# Per-sample override from LineVisualAttributes.color_buffer.
		if p_series_index >= 0 and p_series_index < _visual_attributes.size():
			var color_buffer: VisualAttributes.ColorBuffer = _visual_attributes[p_series_index].color_buffer
			if color_buffer != null and p_sample_index >= 0 and p_sample_index < color_buffer.size():
				var c := color_buffer.get_value(p_sample_index)
				if c != VisualAttributes.ColorBuffer.NO_COLOR:
					return c

		var global_series_index := _get_global_series_index(p_series_index)

		# Per-sample override from LineVisualCallbacks.color_callback.
		var vc := _line_config.line_visual_callbacks
		if vc != null and vc.color_callback.is_valid():
			return vc.color_callback.call(global_series_index, p_sample_index, p_x_value, p_y_value)

		return _xy_style.get_series_color(global_series_index)


	func _resolve_sample_alpha(p_series_index: int, p_sample_index: int, p_x_value: Variant, p_y_value: float) -> float:
		# Per-sample override from LineVisualAttributes.alpha_buffer.
		if p_series_index >= 0 and p_series_index < _visual_attributes.size():
			var alpha_buffer: VisualAttributes.AlphaBuffer = _visual_attributes[p_series_index].alpha_buffer
			if alpha_buffer != null and p_sample_index >= 0 and p_sample_index < alpha_buffer.size():
				var a := alpha_buffer.get_value(p_sample_index)
				if a >= 0.0:
					return a

		# Per-sample override from LineVisualCallbacks.alpha_callback.
		var vc := _line_config.line_visual_callbacks
		if vc != null and vc.alpha_callback.is_valid():
			var a: float = vc.alpha_callback.call(_get_global_series_index(p_series_index), p_sample_index, p_x_value, p_y_value)
			if a >= 0.0:
				return a

		return _xy_style.series_alpha


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
		return _layout.domain.config.x_axis.scale != TauAxisConfig.Scale.LOGARITHMIC or p_x_value > 0.0


	func _is_y_value_valid_for_scale(p_series_id: int, p_y_value: float) -> bool:
		var y_axis_id := _get_y_axis_id_for_series(p_series_id)
		var pane_cfg: TauPaneConfig = _layout.domain.config.panes[_pane_index]
		var y_cfg: TauAxisConfig = pane_cfg.get_y_axis_config(y_axis_id)
		return y_cfg.scale != TauAxisConfig.Scale.LOGARITHMIC or p_y_value > 0.0
