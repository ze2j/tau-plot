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
# - NaN and Inf X or Y values are treated according to the per-series gap
#   policy from TauLineConfig.get_series_gap_policy(global_series_index).
# - Logarithmic Y scales: y <= 0 is treated as invalid.
# - Logarithmic X scales: x <= 0 is treated as invalid.
# - GapPolicy.SKIP breaks the polyline at every invalid sample.
# - GapPolicy.BRIDGE drops invalid samples and keeps the polyline contiguous,
#   so the surrounding valid samples are connected directly.
# - The per-series interpolation mode from
#   TauLineConfig.get_series_interpolation(global_series_index) controls the
#   curve drawn between two consecutive valid samples. LINEAR draws straight
#   segments. The step
#   modes (STEP_BEFORE, STEP_AFTER, STEP_MIDDLE) insert synthetic
#   intermediate points along the parameter axis into the polyline.
#   SMOOTH_MONOTONE replaces each segment with a fixed number of sub-samples
#   from a Fritsch-Carlson piecewise cubic Hermite curve. Both run in axis
#   space and the finished polyline is mapped to screen space before drawing.
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
# - The fill is a strip of columns between two index-aligned axis-space
#   edges, an upper edge and a lower edge sharing one x per vertex. TO_BASELINE
#   and STACKED differ only in the lower edge:
#     - TO_BASELINE fills between the line and the constant
#       TauLineFill.fill_baseline. The lower edge is that flat level dropped
#       under every upper vertex.
#     - STACKED fills the band between this layer's painted top and the top of
#       the layer below (StackedSeriesValues.get_y_baseline), so a stacked line
#       overlay reads as a stacked area chart. Requires LineMode.STACKED.
#   The strip is built from the rendered edges (after interpolation has
#   materialized any synthetic vertices), one quad per pair of neighbouring
#   columns, with a crossing point inserted wherever the band flips sign so the
#   straddling column closes cleanly. The whole strip is emitted in one
#   canvas_item_add_triangle_array call. The line itself is one draw call per
#   contiguous run.
# - Fill resolution is against one TauLineFill per series, resolved through
#   TauLineStyle.get_series_fill (modulo-cycled per series, like
#   line_widths_px). That resource carries the whole fill for the series, its
#   fill_mode included, so two series in the same overlay can fill to
#   different baselines or not fill at all. The fill is drawn either as a flat
#   color or as a texture, never as both:
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
# - The strip carries a per-vertex UV array driven by
#   TauLineFill.texture_mode. STRETCH samples the texture once across a
#   chosen span. TILE samples the texture at native pixel size on screen,
#   with a square-pixel-correct grid rotated around the pane center and
#   translated in screen pixels, independent of pane shape.
# - A fill mixes themed fields with user fields, so the constraints between
#   them are checked here rather than by validation, once per resolved style
#   and never per draw. A fill that breaks one still draws, degraded.
class LineRenderer extends Control:
	# Number of sub-segments inserted between two consecutive samples by
	# SMOOTH_MONOTONE. The value balances visual smoothness on a typical
	# screen against the per-segment cost paid by draw_polyline_colors().
	const _SMOOTH_SUBDIVISIONS: int = 16

	# Fill subdivision for the LINE stretch span. A wedge column fades by band
	# fraction, which is nonlinear, so a single affine quad leaves an error
	# sliver at the thin end. Slicing the segment into strips about
	# _FILL_LINE_SLICE_PX wide keeps that sliver small. _FILL_LINE_MAX_SLICES
	# bounds the triangle count on a long steep segment, and a segment whose
	# band height changes by less than _FILL_LINE_WEDGE_EPS reads as
	# rectangular and fades exactly at one slice.
	const _FILL_LINE_SLICE_PX: float = 6.0
	const _FILL_LINE_MAX_SLICES: int = 16
	const _FILL_LINE_WEDGE_EPS: float = 0.05

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
		# TILE-mode fill tiles the texture by sampling UVs outside [0, 1],
		# which needs texture repeat enabled on the canvas item. The default
		# clamp would fold the whole tile grid into a single stretched copy.
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		queue_redraw()


	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_RESIZED:
				queue_redraw()


	func get_config() -> TauLineConfig:
		return _line_config


	## Sets the resolved [TauLineStyle] used for subsequent draws, and reports
	## the fill settings that cannot be drawn as configured.
	func set_resolved_line_style(p_style: TauLineStyle) -> void:
		_line_style = p_style
		_report_fill_issues()


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


	# Routes a series to the x layout that resolves its parameter axis, then the
	# shared run loop applies the emission rules for both:
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
		if _line_style.get_series_width_px(global_series_index) <= 0.0:
			return

		# Precompute the x plan for the shared run loop. A sample whose x is NaN,
		# Inf, or forbidden by the axis scale gets a NAN x pixel, which the loop
		# reads as a run break. Every other sample maps its x to an axis pixel.
		# The value stored alongside is the raw float, handed to color resolution
		# and hit records unchanged.
		var is_shared_x := _dataset.get_mode() == Dataset.Mode.SHARED_X
		var sample_count := _dataset.get_series_sample_count(series_id)
		var x_px := PackedFloat64Array()
		x_px.resize(sample_count)
		var x_values: Array = []
		x_values.resize(sample_count)
		for i in range(sample_count):
			var xv: float = float(_dataset.get_shared_x(i)) if is_shared_x else float(_dataset.get_series_x(series_id, i))
			x_values[i] = xv
			if is_nan(xv) or is_inf(xv) or not _is_x_value_valid_for_scale(xv):
				x_px[i] = NAN
			else:
				x_px[i] = _layout.map_x_to_px(_pane_index, xv)

		_draw_series_runs(p_series_index, p_stacked, x_px, x_values)


	func _draw_series_categorical(p_series_index: int, p_stacked: StackedSeriesValues) -> void:
		var series_id := _get_line_series_id(p_series_index)
		var global_series_index := _get_global_series_index(p_series_index)
		if _line_style.get_series_width_px(global_series_index) <= 0.0:
			return

		# Precompute the x plan for the shared run loop. Category centers are
		# always valid, so no x pixel is ever NAN and a run only breaks on an
		# invalid y. The value stored alongside is the category itself.
		var categories := _layout.domain.x_categories
		var sample_count := _dataset.get_series_sample_count(series_id)
		var x_px := PackedFloat64Array()
		x_px.resize(sample_count)
		var x_values: Array = []
		x_values.resize(sample_count)
		for cat_idx in range(sample_count):
			x_px[cat_idx] = _layout.map_x_category_center_to_px(_pane_index, cat_idx)
			x_values[cat_idx] = categories[cat_idx]

		_draw_series_runs(p_series_index, p_stacked, x_px, x_values)


	# Builds and finalizes every run of one series from a precomputed x plan,
	# shared by the continuous and categorical layouts so the run-break and
	# emission rules live in one place. p_x_px carries the axis-space x pixel per
	# sample, NAN where the sample's x breaks the run. p_x_values carries the
	# value handed to color resolution and hit records, a float for a continuous
	# x and a category for a categorical one. The y plan (scale validity,
	# stacking, normalization) is resolved here per sample.
	func _draw_series_runs(p_series_index: int, p_stacked: StackedSeriesValues, p_x_px: PackedFloat64Array, p_x_values: Array) -> void:
		var series_id := _get_line_series_id(p_series_index)
		var global_series_index := _get_global_series_index(p_series_index)
		var width_px: float = _line_style.get_series_width_px(global_series_index)
		var dash_px: int = _line_style.get_series_dash_px(global_series_index)
		var hover_width_px: float = max(_line_style.get_series_hovered_width_px(global_series_index), width_px)
		var y_axis_id := _get_y_axis_id_for_series(series_id)
		var bridge: bool = _line_config.get_series_gap_policy(global_series_index) == TauLineConfig.GapPolicy.BRIDGE
		var interpolation: TauLineConfig.InterpolationMode = _line_config.get_series_interpolation(global_series_index)

		# Resolved once per series: every run of this series fills against the
		# same baseline and the same color, and uses the same UV reference frame.
		var fill: TauLineFill = _line_style.get_series_fill(global_series_index)
		var fill_color: Color = _resolve_series_fill_color(global_series_index, fill)
		var baseline_y_px: float = _resolve_fill_baseline_y_px(fill, y_axis_id)
		var fill_uv_ctx: _FillUVContext = _resolve_fill_uv_context(fill, y_axis_id)

		# STACKED fill needs a per-vertex lower edge, the painted top of the layer
		# below, which exists only in stacked mode. The mismatch is reported at
		# resolve time and the fill is dropped here. TO_BASELINE and NONE leave the
		# lower run empty and unused.
		var stacked_fill: bool = fill.fill_mode == TauLineFill.FillMode.STACKED and p_stacked != null

		var independent_y: PackedFloat64Array
		if p_stacked == null:
			independent_y = _build_independent_y_row(series_id)

		var run := PackedVector2Array()
		var run_colors := PackedColorArray()
		# Lower fill edge for STACKED, buffered in lockstep with the upper run so
		# both share one x per index. Stays empty for TO_BASELINE and NONE.
		var run_baseline := PackedVector2Array()
		# Parallel arrays describing the real samples appended to the current
		# run. real_polyline_indices[k] is the index into `run` where the k-th
		# real sample of this run landed before any post-processing
		# (SMOOTH_MONOTONE resampling). The dataset index is needed so the
		# finalizer can locate the hovered sample within the current run.
		var real_polyline_indices := PackedInt32Array()
		var real_dataset_indices := PackedInt32Array()

		var sample_count := p_x_px.size()
		for i in range(sample_count):
			var x_px: float = p_x_px[i]
			# The y plan is only read for an x-valid sample, so an invalid x
			# never pays for a stacked lookup it would discard.
			var y_plotted: float = NAN
			var y_raw: float = NAN
			if not is_nan(x_px):
				if p_stacked != null:
					y_plotted = p_stacked.get_y_plotted(p_series_index, i)
					y_raw = p_stacked.get_y_raw(p_series_index, i)
				else:
					y_plotted = independent_y[i]
					y_raw = y_plotted

			# A sample breaks the run when its x is invalid (NAN x pixel) or its
			# plotted y is NaN. SKIP finalizes and starts a fresh run, BRIDGE
			# drops the sample and keeps appending into the same run.
			if is_nan(x_px) or is_nan(y_plotted):
				if not bridge:
					_finalize_run(run, run_colors, run_baseline, real_polyline_indices, real_dataset_indices, series_id, width_px, hover_width_px, interpolation, dash_px, fill, fill_color, baseline_y_px, fill_uv_ctx)
					run = PackedVector2Array()
					run_colors = PackedColorArray()
					run_baseline = PackedVector2Array()
					real_polyline_indices = PackedInt32Array()
					real_dataset_indices = PackedInt32Array()
				continue

			var y_px := _layout.map_y_to_px(_pane_index, y_plotted, y_axis_id)
			var axis_point := Vector2(x_px, y_px)
			var screen_pos := _layout.map_point_to_screen(x_px, y_px)
			var x_value: Variant = p_x_values[i]
			var sample_color := _resolve_sample_color(p_series_index, i, x_value, y_raw)
			# The run is buffered in axis space so interpolation runs along the
			# parameter and value axes directly. _finalize_run maps it to screen.
			_append_with_interpolation(run, run_colors, axis_point, sample_color, interpolation)
			# Lower edge in lockstep: same x, dropped to the layer below's top. The
			# shared step-riser logic keeps it index-aligned with the upper run.
			if stacked_fill:
				var baseline_axis_point := Vector2(x_px, _layout.map_y_to_px(_pane_index, p_stacked.get_y_baseline(p_series_index, i), y_axis_id))
				_append_lower_with_interpolation(run_baseline, baseline_axis_point, interpolation)
			# The real sample is always the last vertex appended by
			# _append_with_interpolation, regardless of the interpolation mode.
			real_polyline_indices.append(run.size() - 1)
			real_dataset_indices.append(i)

			var record := LineHitRecord.new()
			record.series_id = series_id
			record.series_index = global_series_index
			record.sample_index = i
			record.x_value = x_value
			record.y_plotted_value = y_plotted
			record.y_raw_value = y_raw
			record.screen_position = screen_pos
			_hit_records.append(record)

		_finalize_run(run, run_colors, run_baseline, real_polyline_indices, real_dataset_indices, series_id, width_px, hover_width_px, interpolation, dash_px, fill, fill_color, baseline_y_px, fill_uv_ctx)


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


	# Appends p_axis_point to the run, materializing the synthetic vertices the
	# step modes need. Works in axis space: .x is the x-axis (parameter) pixel
	# and .y is the y-axis (value) pixel. The step riser is therefore always
	# built along the parameter axis, so the result is correct whichever screen
	# direction the x axis points in. The swap to screen space is deferred to
	# _finalize_run.
	#
	# Each appended vertex (real or synthetic) gets the new sample's color.
	# Combined with linear interpolation by draw_polyline_colors() between
	# consecutive vertices, this places the color transition on the segment
	# leading INTO the new sample, leaving the staircase tail solid.
	func _append_with_interpolation(p_run: PackedVector2Array, p_run_colors: PackedColorArray, p_axis_point: Vector2, p_color: Color, p_mode: TauLineConfig.InterpolationMode) -> void:
		# SMOOTH_MONOTONE buffers raw sample points untouched: cubic resampling
		# requires the full neighborhood of every sample to compute tangents and
		# is therefore deferred to _finalize_run().
		if p_run.size() == 0 or p_mode == TauLineConfig.InterpolationMode.LINEAR or p_mode == TauLineConfig.InterpolationMode.SMOOTH_MONOTONE:
			p_run.append(p_axis_point)
			p_run_colors.append(p_color)
			return

		var last_axis_pt: Vector2 = p_run[p_run.size() - 1]
		match p_mode:
			TauLineConfig.InterpolationMode.STEP_BEFORE:
				# Jump the value at the previous parameter, then hold it across.
				p_run.append(Vector2(last_axis_pt.x, p_axis_point.y))
				p_run_colors.append(p_color)
			TauLineConfig.InterpolationMode.STEP_AFTER:
				# Hold the previous value across the interval, jump at the new parameter.
				p_run.append(Vector2(p_axis_point.x, last_axis_pt.y))
				p_run_colors.append(p_color)
			TauLineConfig.InterpolationMode.STEP_MIDDLE:
				# Hold to the parameter midpoint, jump the value there, then hold on.
				var mid_x_axis_px: float = (last_axis_pt.x + p_axis_point.x) * 0.5
				p_run.append(Vector2(mid_x_axis_px, last_axis_pt.y))
				p_run_colors.append(p_color)
				p_run.append(Vector2(mid_x_axis_px, p_axis_point.y))
				p_run_colors.append(p_color)
		p_run.append(p_axis_point)
		p_run_colors.append(p_color)


	# Colorless counterpart of _append_with_interpolation for the STACKED lower
	# edge. It mirrors the step-riser logic on the same shared x, so the lower
	# edge lands the same synthetic vertices at the same indices as the upper
	# run. The fill strip colors every vertex uniformly, so the lower edge needs
	# no parallel color array.
	func _append_lower_with_interpolation(p_run: PackedVector2Array, p_axis_point: Vector2, p_mode: TauLineConfig.InterpolationMode) -> void:
		if p_run.size() == 0 or p_mode == TauLineConfig.InterpolationMode.LINEAR or p_mode == TauLineConfig.InterpolationMode.SMOOTH_MONOTONE:
			p_run.append(p_axis_point)
			return

		var last_axis_pt: Vector2 = p_run[p_run.size() - 1]
		match p_mode:
			TauLineConfig.InterpolationMode.STEP_BEFORE:
				p_run.append(Vector2(last_axis_pt.x, p_axis_point.y))
			TauLineConfig.InterpolationMode.STEP_AFTER:
				p_run.append(Vector2(p_axis_point.x, last_axis_pt.y))
			TauLineConfig.InterpolationMode.STEP_MIDDLE:
				var mid_x_axis_px: float = (last_axis_pt.x + p_axis_point.x) * 0.5
				p_run.append(Vector2(mid_x_axis_px, last_axis_pt.y))
				p_run.append(Vector2(mid_x_axis_px, p_axis_point.y))
		p_run.append(p_axis_point)


	# Draw the polyline for one buffered run. The run arrives in axis space.
	# For LINEAR and the step modes it is already the final polyline. For
	# SMOOTH_MONOTONE it is first replaced by its Fritsch-Carlson piecewise
	# cubic resampling. The fill is built from that axis-space polyline and
	# maps its own strip to screen space, then the line polyline is mapped to
	# screen space and drawn. Runs of fewer than two points are silently dropped.
	#
	# When p_fill_color has non-zero alpha and a lower edge resolves, the band
	# between the rendered polyline and that lower edge is filled before the line
	# is drawn. The lower edge is the flat baseline for TO_BASELINE and the
	# buffered p_run_baseline (the layer below's top) for STACKED, resampled with
	# the upper edge so the two stay index-aligned. The line itself is unaffected.
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
	# p_run_baseline is the buffered lower fill edge for a STACKED run, aligned
	# with p_run one x per index. It is empty for TO_BASELINE and NONE, where the
	# lower edge is synthesized or no fill is drawn.
	#
	# p_real_polyline_indices and p_real_dataset_indices are parallel arrays
	# whose length equals the number of real samples appended to this run.
	# real_polyline_indices[k] is the index in p_run where the k-th real
	# sample landed. real_dataset_indices[k] is the dataset sample index for
	# that real sample.
	func _finalize_run(p_run: PackedVector2Array, p_run_colors: PackedColorArray, p_run_baseline: PackedVector2Array, p_real_polyline_indices: PackedInt32Array, p_real_dataset_indices: PackedInt32Array, p_series_id: int, p_width_px: float, p_hover_width_px: float, p_mode: TauLineConfig.InterpolationMode, p_dash_px: int, p_fill: TauLineFill, p_fill_color: Color, p_baseline_y_px: float, p_fill_uv_ctx: _FillUVContext) -> void:
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

		# The fill is computed in axis space, where the value lies on .y, and
		# maps its own strip to screen space at emission. It runs first so the
		# line lands on top of it. A zero-alpha color or an empty lower edge means
		# no fill for this run. The strip builder pairs the upper polyline against
		# the resolved lower edge, both index-aligned.
		if p_fill_color.a > 0.0:
			var lower_edge := _resolve_fill_lower_edge(polyline, p_run_baseline, p_baseline_y_px, p_mode, p_fill)
			if not lower_edge.is_empty():
				_draw_fill(polyline, lower_edge, p_fill, p_fill_color, p_fill_uv_ctx)

		# The line is drawn in screen space. The mapping preserves vertex
		# order, so real_polyline_indices stay valid.
		polyline = _layout.map_points_to_screen(polyline)

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
	# resampling (consecutive real samples sharing the same x-axis pixel), it
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
	# Resolved fill checks
	####################################################################################################

	# Reports the fill settings that cannot be drawn as configured. Each rule
	# reads fields the theme writes next to fields only the user writes, so it
	# is decidable on the resolved cycle and nowhere earlier. Every message
	# names the pane, the series and the position in the cycle the fill was
	# read from.
	func _report_fill_issues() -> void:
		# An empty cycle leaves every series on the built-in defaults, which
		# paint nothing.
		if _line_style.fills.is_empty():
			return

		for i in range(_get_line_series_count()):
			var series_id := _get_line_series_id(i)
			var global_series_index := _get_global_series_index(i)
			var cycle_index: int = global_series_index % _line_style.fills.size()
			var fill: TauLineFill = _line_style.get_series_fill(global_series_index)

			_report_stretch_range_issues(series_id, cycle_index, fill)

			match fill.fill_mode:
				TauLineFill.FillMode.TO_BASELINE:
					_report_baseline_issues(series_id, cycle_index, fill)
				TauLineFill.FillMode.STACKED:
					_report_stacked_fill_issues(series_id, cycle_index, fill)


	func _fill_issue_prefix(p_series_id: int, p_cycle_index: int) -> String:
		return "LineRenderer: pane %d: series %d: fills[%d]" % [_pane_index, p_series_id, p_cycle_index]


	# Only a STRETCH fill with a non-LINE span reads the CUSTOM window. This
	# single pass flags the misconfigurations of that window:
	#   - the fill never reads it, so CUSTOM has no effect and DOMAIN was meant.
	#     Harmless, the fill draws as authored.
	#   - zero width, so the reader has no gradient to draw and falls back to
	#     the texture middle. DOMAIN can collapse the same way on flat data,
	#     but that is a data shape, not a setting.
	#   - VALUE_X on a categorical x axis, whose samples sit at category
	#     centers with no continuous x to place the ends on. DOMAIN spans those
	#     centers instead.
	func _report_stretch_range_issues(p_series_id: int, p_cycle_index: int, p_fill: TauLineFill) -> void:
		if p_fill.stretch_range_policy != TauLineFill.StretchRangePolicy.CUSTOM:
			return

		if p_fill.texture_mode != TauLineFill.FillTextureMode.STRETCH or p_fill.stretch_span == TauLineFill.FillStretchSpan.LINE:
			push_warning("%s: CUSTOM stretch_range_policy is set but this fill never reads it, use DOMAIN or give the fill a VALUE_X, VALUE_Y or MAGNITUDE span" % _fill_issue_prefix(p_series_id, p_cycle_index))
			return

		if p_fill.stretch_range.x == p_fill.stretch_range.y:
			push_error("%s: CUSTOM stretch_range is zero width (stretch_range.x == stretch_range.y), no gradient to draw" % _fill_issue_prefix(p_series_id, p_cycle_index))

		if _get_x_axis_config().type == TauAxisConfig.Type.CATEGORICAL and p_fill.stretch_span == TauLineFill.FillStretchSpan.VALUE_X:
			push_error("%s: CUSTOM stretch_range is not supported on a categorical x axis with VALUE_X span, use DOMAIN policy" % _fill_issue_prefix(p_series_id, p_cycle_index))


	# The baseline is mapped like a data value on the series y axis, so a
	# logarithmic scale cannot take it at or below zero.
	func _report_baseline_issues(p_series_id: int, p_cycle_index: int, p_fill: TauLineFill) -> void:
		if _is_y_value_valid_for_scale(p_series_id, p_fill.fill_baseline):
			return
		push_error("%s: TO_BASELINE fill_mode requires fill_baseline > 0 on a logarithmic y axis, got %s" % [_fill_issue_prefix(p_series_id, p_cycle_index), p_fill.fill_baseline])


	# The band is drawn between a layer and the one below, so it only exists
	# when the overlay itself stacks, and it has no baseline for MAGNITUDE to
	# measure from.
	func _report_stacked_fill_issues(p_series_id: int, p_cycle_index: int, p_fill: TauLineFill) -> void:
		if _line_config.mode != TauLineConfig.LineMode.STACKED:
			push_error("%s: STACKED fill_mode requires mode STACKED, the fill is dropped" % _fill_issue_prefix(p_series_id, p_cycle_index))

		if p_fill.texture == null:
			return
		if p_fill.texture_mode != TauLineFill.FillTextureMode.STRETCH:
			return
		if p_fill.stretch_span != TauLineFill.FillStretchSpan.MAGNITUDE:
			return
		push_error("%s: MAGNITUDE stretch_span is not supported under STACKED fill_mode, the band has no baseline to measure from" % _fill_issue_prefix(p_series_id, p_cycle_index))


	####################################################################################################
	# Area fill
	####################################################################################################

	# Bundle of values driving the per-vertex UV array for one textured fill
	# strip. Built once per series, then consumed by _build_strip_uvs_stretch
	# and _build_strip_uvs_tile for every run of that series.
	#
	# Two parameter sets coexist, selected by TauLineFill.texture_mode:
	#   - STRETCH samples the texture once across the span. half_texel gives
	#     the clamp bounds that reproduce clamped sampling without relying on
	#     the node's texture_repeat. range_px0 and range_px1 are the value
	#     span's two ends in axis pixels, read off the span's own axis (.x for
	#     VALUE_X, .y for VALUE_Y and MAGNITUDE). baseline_px is the origin
	#     MAGNITUDE measures from. degenerate flags a DOMAIN range that
	#     collapsed to a point on flat data, so the builder samples the texture
	#     middle instead of dividing by a zero span. LINE ignores every value
	#     field.
	#   - TILE samples the texture in screen pixels around pane_center.
	#     rotation_cos and rotation_sin hold cos/sin of -rotation_deg, so
	#     the per-vertex math runs the standard rotation formula on the
	#     centered screen pixel. inv_tile_size is the reciprocal of
	#     (texture native size * scale) along each axis.
	#
	# texture is null for flat fills. In that case no UV array is built,
	# every other field is unused, and the draw call's uv argument stays
	# empty.
	class _FillUVContext extends RefCounted:
		var texture: Texture2D = null

		# STRETCH
		var half_texel: Vector2 = Vector2.ZERO
		var range_px0: float = 0.0
		var range_px1: float = 0.0
		var baseline_px: float = 0.0
		var degenerate: bool = false

		# TILE
		var pane_center: Vector2 = Vector2.ZERO
		var rotation_cos: float = 1.0
		var rotation_sin: float = 0.0
		var offset_px: Vector2 = Vector2.ZERO
		var inv_tile_size: Vector2 = Vector2.ZERO


	# Resolves the fill UV context for p_fill bound to p_y_axis_id. Returns a
	# context with texture = null when p_fill's mode is NONE or when p_fill has
	# no texture, so the caller skips UV construction entirely. The value spans
	# read the vertex on their own axis, so they apply unchanged to the band
	# edges of a STACKED fill. MAGNITUDE is the exception: it measures from
	# fill_baseline, which the band does not sit on, so the pairing is reported
	# at resolve time and the colors it produces mean nothing. texture_mode and
	# stretch_span are read directly from p_fill by the strip UV builder and are
	# not stored on the context.
	func _resolve_fill_uv_context(p_fill: TauLineFill, p_y_axis_id: AxisId) -> _FillUVContext:
		var ctx := _FillUVContext.new()
		if p_fill.fill_mode == TauLineFill.FillMode.NONE:
			return ctx
		ctx.texture = p_fill.texture
		if ctx.texture == null:
			return ctx

		match p_fill.texture_mode:
			TauLineFill.FillTextureMode.STRETCH:
				_resolve_stretch_uv_context(ctx, p_fill, p_y_axis_id)

			TauLineFill.FillTextureMode.TILE:
				var pane_rect: Rect2 = _layout.get_pane_rect(_pane_index)
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


	# Fills the STRETCH fields of p_ctx for the given span. LINE reads only the
	# strip parity, so it stops after half_texel with no range. The value spans
	# map their resolved data range to axis pixels through map_x_to_px /
	# map_y_to_px, which already carry axis inversion and log scale, then flag a
	# degenerate range so the builder can fall back to the texture middle.
	# Mapping both MAGNITUDE ends upward from the baseline keeps them symmetric
	# on a linear scale and never asks a log axis for a value it cannot take.
	func _resolve_stretch_uv_context(p_ctx: _FillUVContext, p_fill: TauLineFill, p_y_axis_id: AxisId) -> void:
		p_ctx.half_texel = Vector2(0.5, 0.5) / p_ctx.texture.get_size()
		var span: TauLineFill.FillStretchSpan = p_fill.stretch_span
		if span == TauLineFill.FillStretchSpan.LINE:
			return

		var value_range: Vector2 = _resolve_stretch_range(p_fill, p_y_axis_id)
		match span:
			TauLineFill.FillStretchSpan.VALUE_X:
				if _get_x_axis_config().type == TauAxisConfig.Type.CATEGORICAL:
					p_ctx.range_px0 = _layout.map_x_category_center_to_px(_pane_index, 0)
					p_ctx.range_px1 = _layout.map_x_category_center_to_px(_pane_index, _layout.domain.x_categories.size() - 1)
				else:
					p_ctx.range_px0 = _layout.map_x_to_px(_pane_index, value_range.x)
					p_ctx.range_px1 = _layout.map_x_to_px(_pane_index, value_range.y)
			TauLineFill.FillStretchSpan.VALUE_Y:
				p_ctx.range_px0 = _layout.map_y_to_px(_pane_index, value_range.x, p_y_axis_id)
				p_ctx.range_px1 = _layout.map_y_to_px(_pane_index, value_range.y, p_y_axis_id)
			TauLineFill.FillStretchSpan.MAGNITUDE:
				var baseline: float = p_fill.fill_baseline
				p_ctx.baseline_px = _layout.map_y_to_px(_pane_index, baseline, p_y_axis_id)
				p_ctx.range_px0 = absf(_layout.map_y_to_px(_pane_index, baseline + value_range.x, p_y_axis_id) - p_ctx.baseline_px)
				p_ctx.range_px1 = absf(_layout.map_y_to_px(_pane_index, baseline + value_range.y, p_y_axis_id) - p_ctx.baseline_px)

		# Exact equality, so a near flat range stays a steep gradient. A DOMAIN
		# range on flat data and a zero width CUSTOM window both land here and
		# sample the texture middle.
		p_ctx.degenerate = p_ctx.range_px0 == p_ctx.range_px1


	# Resolves the value window for a value span in data units. CUSTOM returns
	# p_fill.stretch_range as authored. DOMAIN spans the raw data bounds before
	# padding, so the texture ends land on the data extremes the user drew and
	# not in the padding beyond them. MAGNITUDE measures distance from
	# p_fill.fill_baseline, so its window runs from the baseline to the farthest
	# point.
	func _resolve_stretch_range(p_fill: TauLineFill, p_y_axis_id: AxisId) -> Vector2:
		if p_fill.stretch_range_policy == TauLineFill.StretchRangePolicy.CUSTOM:
			return p_fill.stretch_range

		if p_fill.stretch_span == TauLineFill.FillStretchSpan.VALUE_X:
			var x_domain := _layout.domain.x_axis_domain
			return Vector2(x_domain.data_min, x_domain.data_max)

		var y_domain := _layout.domain.get_pane_domain(_pane_index).get_y_axis_domain(p_y_axis_id)
		if p_fill.stretch_span == TauLineFill.FillStretchSpan.VALUE_Y:
			return Vector2(y_domain.data_min, y_domain.data_max)

		# MAGNITUDE
		var baseline: float = p_fill.fill_baseline
		var d_max: float = maxf(absf(y_domain.data_min - baseline), absf(y_domain.data_max - baseline))
		return Vector2(0.0, d_max)


	# Builds one UV per strip point for a STRETCH fill. p_axis_points is the
	# strip in axis space: even index 2k sits on the line, odd index 2k+1 on the
	# baseline side.
	#
	# LINE reads that parity, the line at the texture top and the baseline at
	# its bottom. The value spans read the vertex on the span's own axis (.x for
	# VALUE_X, .y for VALUE_Y and MAGNITUDE), turn it into a fraction between the
	# two range ends, then clamp to the half-texel margin so sampling matches a
	# clamped texture regardless of the node's texture_repeat. The vertical spans
	# invert the fraction so the higher value reads the texture top. A degenerate
	# value range samples the texture middle everywhere, the honest look when
	# there is no room for a gradient.
	func _build_strip_uvs_stretch(p_axis_points: PackedVector2Array, p_fill: TauLineFill, p_fill_uv_ctx: _FillUVContext) -> PackedVector2Array:
		var count: int = p_axis_points.size()
		var uvs := PackedVector2Array()
		uvs.resize(count)
		var hy: float = p_fill_uv_ctx.half_texel.y

		if p_fill.stretch_span == TauLineFill.FillStretchSpan.LINE:
			for k in range(count):
				var t: float = hy if k % 2 == 0 else 1.0 - hy
				uvs[k] = Vector2(0.5, t)
			return uvs

		if p_fill_uv_ctx.degenerate:
			uvs.fill(Vector2(0.5, 0.5))
			return uvs

		var hx: float = p_fill_uv_ctx.half_texel.x
		var range_px0: float = p_fill_uv_ctx.range_px0
		var span: float = p_fill_uv_ctx.range_px1 - range_px0

		match p_fill.stretch_span:
			TauLineFill.FillStretchSpan.VALUE_X:
				for k in range(count):
					var t: float = clampf((p_axis_points[k].x - range_px0) / span, hx, 1.0 - hx)
					uvs[k] = Vector2(t, 0.5)
			TauLineFill.FillStretchSpan.VALUE_Y:
				for k in range(count):
					var t: float = clampf(1.0 - (p_axis_points[k].y - range_px0) / span, hy, 1.0 - hy)
					uvs[k] = Vector2(0.5, t)
			TauLineFill.FillStretchSpan.MAGNITUDE:
				var baseline_px: float = p_fill_uv_ctx.baseline_px
				for k in range(count):
					var m: float = absf(p_axis_points[k].y - baseline_px)
					var t: float = clampf(1.0 - (m - range_px0) / span, hy, 1.0 - hy)
					uvs[k] = Vector2(0.5, t)

		return uvs


	# TILE. The screen pixel is centered on the pane center, rotated into
	# the texture's frame, translated by offset_px, then divided by
	# (texture_size * scale) to produce the texture coordinate. The grid
	# stays square-pixel correct because both axes share the same screen
	# pixel units.
	static func _build_strip_uvs_tile(p_points: PackedVector2Array, p_fill_uv_ctx: _FillUVContext) -> PackedVector2Array:
		var count: int = p_points.size()
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
			var v: Vector2 = p_points[k]
			var dx: float = v.x - cx
			var dy: float = v.y - cy
			var rx: float = c * dx - s * dy
			var ry: float = s * dx + c * dy
			uvs[k] = Vector2((rx + ox) * inv_w, (ry + oy) * inv_h)
		return uvs


	# Returns the color passed as the modulation argument of the fill draw
	# call for one series. TO_BASELINE and STACKED resolve a color the same way,
	# since both paint the same strip. Three cases:
	#
	#   1. p_fill's mode is NONE. No fill is drawn for this series, so the
	#      return value is fully transparent black and the draw call is skipped
	#      upstream.
	#   2. p_fill has a texture. The fill is the texture and must not be
	#      tinted, so the modulation color is white. Its alpha carries
	#      p_fill.alpha, which is the only thing that scales the texture.
	#   3. p_fill has no texture. The fill is a flat color: p_fill.color,
	#      or the per-series color from TauXYStyle.series_colors when
	#      p_fill.color is TauLineFill.NO_COLOR. p_fill.alpha is then
	#      applied to its alpha channel.
	func _resolve_series_fill_color(p_global_series_index: int, p_fill: TauLineFill) -> Color:
		if p_fill.fill_mode == TauLineFill.FillMode.NONE:
			return Color(0, 0, 0, 0)
		if p_fill.texture != null:
			return Color(1.0, 1.0, 1.0, p_fill.alpha)
		var color: Color = p_fill.color
		if color == TauLineFill.NO_COLOR:
			color = _xy_style.get_series_color(p_global_series_index)
		color.a = clampf(color.a * p_fill.alpha, 0.0, 1.0)
		return color


	# Returns the fill baseline's coordinate on the y (value) axis, or NAN when
	# no flat baseline applies. The fill strip is built in axis space, so this
	# is the .y the strip builder compares its vertices against.
	func _resolve_fill_baseline_y_px(p_fill: TauLineFill, p_y_axis_id: AxisId) -> float:
		if p_fill.fill_mode != TauLineFill.FillMode.TO_BASELINE:
			return NAN
		return _layout.map_y_to_px(_pane_index, p_fill.fill_baseline, p_y_axis_id)


	# Synthesizes the flat lower edge for a TO_BASELINE fill from the final upper
	# polyline. Each lower vertex shares its upper vertex's .x and drops to the
	# constant baseline, so the two edges are index-aligned by construction and
	# the strip builder pairs them without a constant special case.
	func _synthesize_flat_lower_edge(p_upper: PackedVector2Array, p_baseline_y_px: float) -> PackedVector2Array:
		var lower := PackedVector2Array()
		var n: int = p_upper.size()
		lower.resize(n)
		for i in range(n):
			lower[i] = Vector2(p_upper[i].x, p_baseline_y_px)
		return lower


	# Resolves the lower fill edge index-aligned with p_upper for p_fill's mode,
	# or an empty array when no fill applies to this run. TO_BASELINE drops
	# the constant baseline under every upper vertex. STACKED finalizes the
	# buffered lower run the same way the upper run was finalized, so both edges
	# stay index-aligned. NONE and a non-finite TO_BASELINE baseline return empty.
	func _resolve_fill_lower_edge(p_upper: PackedVector2Array, p_run_baseline: PackedVector2Array, p_baseline_y_px: float, p_mode: TauLineConfig.InterpolationMode, p_fill: TauLineFill) -> PackedVector2Array:
		match p_fill.fill_mode:
			TauLineFill.FillMode.TO_BASELINE:
				if is_nan(p_baseline_y_px):
					return PackedVector2Array()
				return _synthesize_flat_lower_edge(p_upper, p_baseline_y_px)
			TauLineFill.FillMode.STACKED:
				return _finalize_lower_run(p_run_baseline, p_mode)
		return PackedVector2Array()


	# Materializes the final STACKED lower edge from its buffered run. LINEAR and
	# step runs are already final. SMOOTH_MONOTONE resamples with the same routine
	# as the upper run: the two runs share their x sequence, so the resampler
	# makes identical flat-x dedup and subdivision choices and the outputs stay
	# index-aligned. The fill strip colors every vertex uniformly, so a throwaway
	# color array sized to the run feeds the resampler.
	func _finalize_lower_run(p_run_baseline: PackedVector2Array, p_mode: TauLineConfig.InterpolationMode) -> PackedVector2Array:
		if p_mode == TauLineConfig.InterpolationMode.SMOOTH_MONOTONE and p_run_baseline.size() > 2:
			var throwaway_colors := PackedColorArray()
			throwaway_colors.resize(p_run_baseline.size())
			var resampled := _resample_smooth_monotone(p_run_baseline, throwaway_colors)
			return resampled[0]
		return p_run_baseline


	# Builds and draws the fill between the upper and lower edges. Both are in
	# axis space and index-aligned, sharing one .x per vertex, so a column is a
	# quad between paired vertices running along the parameter axis. The strip is
	# mapped to screen space at emission inside _build_fill_strip. The lower edge
	# is the synthesized flat baseline for TO_BASELINE and the layer below's top
	# for STACKED; both reach here as an index-aligned polyline.
	#
	# The LINE stretch span fades by band fraction and needs near-rectangular
	# columns to stay accurate, so both edges are densified first. Every other
	# span is affine-exact at the original resolution and skips densification.
	func _draw_fill(p_upper: PackedVector2Array, p_lower: PackedVector2Array, p_fill: TauLineFill, p_fill_color: Color, p_fill_uv_ctx: _FillUVContext) -> void:
		if p_upper.size() < 2:
			return

		var upper: PackedVector2Array = p_upper
		var lower: PackedVector2Array = p_lower
		if _fill_needs_subdivision(p_fill):
			var dense := _densify_fill_edges(p_upper, p_lower)
			upper = dense[0]
			lower = dense[1]

		_build_fill_strip(upper, lower, p_fill, p_fill_color, p_fill_uv_ctx)


	# True for a textured LINE stretch span, the only fill whose fade is
	# nonlinear across a column. The value spans map to one screen axis and
	# TILE maps affinely, so they render exactly without densification.
	func _fill_needs_subdivision(p_fill: TauLineFill) -> bool:
		return p_fill.texture != null \
			and p_fill.texture_mode == TauLineFill.FillTextureMode.STRETCH \
			and p_fill.stretch_span == TauLineFill.FillStretchSpan.LINE


	# Splits each column into collinear sub-columns so a wedge becomes a run of
	# near-rectangular ones. Both edges are cut with the same interpolation
	# factor so the paired vertices stay index-aligned. The line itself is drawn
	# from the original polyline, so this touches only the fill geometry.
	func _densify_fill_edges(p_upper: PackedVector2Array, p_lower: PackedVector2Array) -> Array[PackedVector2Array]:
		var n: int = p_upper.size()
		var dense_upper := PackedVector2Array()
		var dense_lower := PackedVector2Array()
		dense_upper.append(p_upper[0])
		dense_lower.append(p_lower[0])
		for i in range(1, n):
			var ua: Vector2 = p_upper[i - 1]
			var ub: Vector2 = p_upper[i]
			var la: Vector2 = p_lower[i - 1]
			var lb: Vector2 = p_lower[i]
			var slices: int = _fill_segment_slices(ua, ub, la, lb)
			for s in range(1, slices):
				var f: float = float(s) / slices
				dense_upper.append(ua.lerp(ub, f))
				dense_lower.append(la.lerp(lb, f))
			dense_upper.append(ub)
			dense_lower.append(lb)
		return [dense_upper, dense_lower]


	# Number of fill sub-columns for the column between the two paired edge
	# points. A column of constant band height fades exactly and stays whole. A
	# wedge is cut into strips about _FILL_LINE_SLICE_PX wide, capped by
	# _FILL_LINE_MAX_SLICES. Slice count is measured along the upper edge.
	func _fill_segment_slices(p_upper0: Vector2, p_upper1: Vector2, p_lower0: Vector2, p_lower1: Vector2) -> int:
		var h0: float = _band_height(p_upper0, p_lower0)
		var h1: float = _band_height(p_upper1, p_lower1)
		var hi: float = maxf(h0, h1)
		if hi == 0.0 or (hi - minf(h0, h1)) / hi < _FILL_LINE_WEDGE_EPS:
			return 1
		return clampi(ceili(p_upper0.distance_to(p_upper1) / _FILL_LINE_SLICE_PX), 1, _FILL_LINE_MAX_SLICES)


	# Band height at one column, the gap between the paired upper and lower edge
	# points along the y (value) axis. The strip is built in axis space, so the
	# value always lies on .y.
	func _band_height(p_upper: Vector2, p_lower: Vector2) -> float:
		return absf(p_upper.y - p_lower.y)


	# Builds the strip of columns between the upper and lower edges and emits it
	# in one canvas_item_add_triangle_array call. Both edges are in axis space
	# and index-aligned, sharing one .x per vertex; the strip is built there
	# (value on .y) and mapped to screen space just before the draw call. Each
	# pair of neighbouring vertices spans one column, a quad between the two
	# edges split into two triangles. A crossing point is inserted wherever the
	# band flips sign, that is where the edges meet, so the straddling column
	# collapses to a triangle on each side with no self crossing, and no
	# same-side split is needed.
	#
	# Crossing detection runs on the axis-space edges, so the synthetic vertices
	# from step interpolation and the sub-samples from SMOOTH_MONOTONE are
	# treated uniformly. The same crossing point lands on both edges, so the
	# column there closes cleanly. Both traversal directions are accepted
	# because the builder never assumes one.
	func _build_fill_strip(p_upper: PackedVector2Array, p_lower: PackedVector2Array, p_fill: TauLineFill, p_fill_color: Color, p_fill_uv_ctx: _FillUVContext) -> void:
		var n: int = p_upper.size()
		if n < 2:
			return

		# Insert a crossing point between every pair of neighbouring columns
		# whose band flips sign. The same point lands on both edges, so each
		# column stays single sided and the strip needs no same-side splitting.
		var top := PackedVector2Array()
		var bottom := PackedVector2Array()
		top.append(p_upper[0])
		bottom.append(p_lower[0])
		for i in range(1, n):
			var prev_side: int = _band_side(p_upper[i - 1], p_lower[i - 1])
			var v_side: int = _band_side(p_upper[i], p_lower[i])
			if prev_side != 0 and v_side != 0 and prev_side != v_side:
				var cross: Vector2 = _band_crossing(p_upper[i - 1], p_lower[i - 1], p_upper[i], p_lower[i])
				top.append(cross)
				bottom.append(cross)
			top.append(p_upper[i])
			bottom.append(p_lower[i])

		# Even vertex 2k rides the upper edge, odd vertex 2k+1 the lower edge.
		# The UV builder relies on this parity to tell the two strip edges apart.
		var m: int = top.size()
		var points := PackedVector2Array()
		points.resize(2 * m)
		for k in range(m):
			points[2 * k] = top[k]
			points[2 * k + 1] = bottom[k]

		var colors := PackedColorArray()
		colors.resize(2 * m)
		colors.fill(p_fill_color)

		var indices := PackedInt32Array()
		indices.resize(6 * (m - 1))
		for k in range(m - 1):
			var base: int = 6 * k
			# Split each column from its shorter side so the taller wedge keeps
			# its whole line edge on the texture's line end. A rising and a
			# falling wedge then read the same LINE fade, and a column that
			# closes collapses to a single triangle without dropping the line
			# edge.
			if _band_height(top[k], bottom[k]) <= _band_height(top[k + 1], bottom[k + 1]):
				indices[base] = 2 * k
				indices[base + 1] = 2 * k + 2
				indices[base + 2] = 2 * k + 3
				indices[base + 3] = 2 * k
				indices[base + 4] = 2 * k + 3
				indices[base + 5] = 2 * k + 1
			else:
				indices[base] = 2 * k
				indices[base + 1] = 2 * k + 2
				indices[base + 2] = 2 * k + 1
				indices[base + 3] = 2 * k + 2
				indices[base + 4] = 2 * k + 3
				indices[base + 5] = 2 * k + 1

		# The strip was built in axis space. Map it to screen space for the draw
		# call. STRETCH UVs read the axis-space vertices (value on .y), while
		# TILE UVs are a screen-pixel effect and read the mapped vertices.
		var screen_points := _layout.map_points_to_screen(points)

		# UVs and the texture RID are only supplied when a texture is set. A
		# flat fill draws with an empty UV array and a null RID.
		var uvs := PackedVector2Array()
		var tex_rid := RID()
		if p_fill_uv_ctx.texture != null:
			if p_fill.texture_mode == TauLineFill.FillTextureMode.TILE:
				uvs = _build_strip_uvs_tile(screen_points, p_fill_uv_ctx)
			else:
				uvs = _build_strip_uvs_stretch(points, p_fill, p_fill_uv_ctx)
			tex_rid = p_fill_uv_ctx.texture.get_rid()

		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, screen_points, colors, uvs, PackedInt32Array(), PackedFloat32Array(), tex_rid)


	# Sign of the band at one column, sign(upper.y - lower.y) along the y (value)
	# axis. Returns 0 where the two edges meet and opposite non-zero signs on the
	# two sides. Only the opposition matters to the caller, which uses it to spot
	# a band sign flip, so the sign's meaning is left to the mapping.
	func _band_side(p_upper: Vector2, p_lower: Vector2) -> int:
		if p_upper.y > p_lower.y:
			return 1
		if p_upper.y < p_lower.y:
			return -1
		return 0


	# Point where the band closes between two neighbouring columns, that is where
	# the upper and lower edges meet. With band d = upper.y - lower.y the meeting
	# sits at t = d0 / (d0 - d1). The point is taken on the lower edge so a flat
	# baseline reproduces exactly. Precondition: the two columns straddle the
	# meeting with a non-zero band on each side, guaranteed by the caller.
	func _band_crossing(p_upper0: Vector2, p_lower0: Vector2, p_upper1: Vector2, p_lower1: Vector2) -> Vector2:
		var d0: float = p_upper0.y - p_lower0.y
		var d1: float = p_upper1.y - p_lower1.y
		var t: float = d0 / (d0 - d1)
		return p_lower0.lerp(p_lower1, t)


	####################################################################################################
	# Smooth-monotone (Fritsch-Carlson) resampling
	####################################################################################################

	# Builds the Fritsch-Carlson piecewise cubic Hermite curve through p_points
	# and returns it sampled at _SMOOTH_SUBDIVISIONS sub-segments per input
	# segment, paired with a colors array sampled in lock-step. Operates in
	# axis space (points are pixels along the x and y axes), which keeps the
	# curve visually smooth regardless of axis scale and orientation.
	#
	# The algorithm requires a strictly monotonic parameter axis, read from the
	# x-axis pixel in .x. The expected case is an increasing x-axis pixel, but a
	# user-inverted x axis produces a decreasing one. Both directions are
	# accepted: the input is processed internally on a strictly increasing copy
	# and the output is reversed back when needed. Consecutive points sharing
	# the same x-axis pixel are dropped since the secant slope is undefined at
	# h = 0. The matching color entries are dropped at the same indices.
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
				push_warning("LineRenderer: SMOOTH_MONOTONE received samples whose parameter axis is not monotonic. Falling back to a straight polyline for the affected run. Use LINEAR interpolation if your data does not have a monotonic X parameter.")
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
			# All inputs collapsed to a single x-axis pixel. Nothing to draw.
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


	# Returns +1 if the x-axis pixel is strictly monotonically increasing across
	# the whole run, -1 if strictly decreasing, 0 if neither (some pair has
	# equal x-axis pixel) or the run has fewer than 2 points. An equal
	# consecutive pair is allowed only as a single-point run (n < 2 case).
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
