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
# buffer/series access). Each contiguous run of valid samples is drawn with
# one Godot draw call.
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
# - Path 1, fast path: resolved per-series dash length is 0. The run is
#   drawn with a single draw_polyline_colors() call.
# - Path 2, dashed batched path: resolved per-series dash length is positive.
#   Dash phase is precomputed across the full run, the "on" intervals are
#   collected into a flat segment array, and the run is drawn with a single
#   draw_multiline_colors() call. The dash phase is continuous across all
#   segments of the polyline.
#
# Per-sample color and alpha resolution:
# - Color resolution order: LineVisualAttributes.color_buffer, then
#   LineVisualCallbacks.color_callback, then the per-series color from
#   TauXYStyle.series_colors.
# - Alpha resolution order: LineVisualAttributes.alpha_buffer, then
#   LineVisualCallbacks.alpha_callback, then TauXYStyle.series_alpha.
# - The resolved alpha overwrites the alpha channel of the resolved color.
# - Each vertex of the polyline carries its own resolved color. Colors are
#   linearly interpolated by Godot between consecutive vertices.
# - Synthetic step-mode intermediate vertices and SMOOTH_MONOTONE sub-samples
#   are colored consistently with the underlying segment endpoints so the
#   resulting interpolation matches the chosen interpolation mode.
#
# LineValidator is expected to enforce binding-level typing constraints.
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

	# Pane index this renderer belongs to. Used for per-pane domain/layout queries.
	var _pane_index: int = 0

	# Line-specific series list: only series mapped as LINE are iterated.
	# Must be provided at construction. Empty means this renderer has no
	# series to draw.
	var _line_series_ids: PackedInt64Array = PackedInt64Array()

	# Resolved style instances pushed by xy_plot. Treat as read-only.
	var _line_style: TauLineStyle = null
	var _xy_style: TauXYStyle = null

	# One-shot guard for the non-monotonic SMOOTH_MONOTONE fallback warning.
	# Reset is intentionally absent: a single warning per renderer instance
	# is enough to surface the misconfiguration without flooding the output
	# on every redraw.
	var _smooth_non_monotonic_warned: bool = false


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

		for draw_rank in range(draw_order.size()):
			var series_index: int = draw_order[draw_rank]
			_draw_series_independent(series_index)


	# Draws a single series as one or more polyline runs, respecting the
	# active gap policy. Run emission follows these rules:
	#   - A valid sample is appended to the current run.
	#   - An invalid sample (NaN/Inf X or Y, or a value forbidden by the
	#     active axis scale) is handled according to gap_policy:
	#     - SKIP   flushes the current run and starts a new one.
	#     - BRIDGE drops the sample and keeps appending into the same run.
	#   - A run of fewer than two points is discarded (no polyline).
	func _draw_series_independent(p_series_index: int) -> void:
		var x_cfg := _get_x_axis_config()
		if x_cfg != null and x_cfg.type == TauAxisConfig.Type.CATEGORICAL:
			_draw_series_categorical(p_series_index)
		else:
			_draw_series_continuous(p_series_index)


	func _draw_series_continuous(p_series_index: int) -> void:
		var series_id := _get_line_series_id(p_series_index)
		var global_series_index := _get_global_series_index(p_series_index)
		var width_px: float = _line_style.get_series_width_px(global_series_index)
		if width_px <= 0.0:
			return
		var dash_px: int = _line_style.get_series_dash_px(global_series_index)
		var y_axis_id := _get_y_axis_id_for_series(series_id)
		var bridge: bool = _line_config.gap_policy == TauLineConfig.GapPolicy.BRIDGE
		var interpolation: TauLineConfig.InterpolationMode = _line_config.interpolation_mode

		var run := PackedVector2Array()
		var run_colors := PackedColorArray()

		var is_shared_x := _dataset.get_mode() == Dataset.Mode.SHARED_X
		var sample_count := _dataset.get_series_sample_count(series_id)

		for i in range(sample_count):
			var x_value: float = float(_dataset.get_shared_x(i)) if is_shared_x else float(_dataset.get_series_x(series_id, i))
			if is_nan(x_value) or is_inf(x_value) or not _is_x_value_valid_for_scale(x_value):
				if not bridge:
					_finalize_run(run, run_colors, width_px, interpolation, dash_px)
					run = PackedVector2Array()
					run_colors = PackedColorArray()
				continue

			var y_value := _dataset.get_series_y(series_id, i)
			if is_nan(y_value) or is_inf(y_value) or not _is_y_value_valid_for_scale(series_id, y_value):
				if not bridge:
					_finalize_run(run, run_colors, width_px, interpolation, dash_px)
					run = PackedVector2Array()
					run_colors = PackedColorArray()
				continue

			var x_px := _layout.map_x_to_px(_pane_index, x_value)
			var y_px := _layout.map_y_to_px(_pane_index, y_value, y_axis_id)
			var sample_color := _resolve_sample_color(p_series_index, i, x_value, y_value)
			_append_with_interpolation(run, run_colors, _layout.map_point_to_screen(x_px, y_px), sample_color, interpolation)

		_finalize_run(run, run_colors, width_px, interpolation, dash_px)


	func _draw_series_categorical(p_series_index: int) -> void:
		var series_id := _get_line_series_id(p_series_index)
		var global_series_index := _get_global_series_index(p_series_index)
		var width_px: float = _line_style.get_series_width_px(global_series_index)
		if width_px <= 0.0:
			return
		var dash_px: int = _line_style.get_series_dash_px(global_series_index)
		var y_axis_id := _get_y_axis_id_for_series(series_id)
		var bridge: bool = _line_config.gap_policy == TauLineConfig.GapPolicy.BRIDGE
		var interpolation: TauLineConfig.InterpolationMode = _line_config.interpolation_mode

		var categories := _layout.domain.x_categories
		var run := PackedVector2Array()
		var run_colors := PackedColorArray()
		var sample_count := _dataset.get_series_sample_count(series_id)

		for cat_idx in range(sample_count):
			var y_value := _dataset.get_series_y(series_id, cat_idx)
			if is_nan(y_value) or is_inf(y_value) or not _is_y_value_valid_for_scale(series_id, y_value):
				if not bridge:
					_finalize_run(run, run_colors, width_px, interpolation, dash_px)
					run = PackedVector2Array()
					run_colors = PackedColorArray()
				continue

			var x_px := _layout.map_x_category_center_to_px(_pane_index, cat_idx)
			var y_px := _layout.map_y_to_px(_pane_index, y_value, y_axis_id)
			var x_value: Variant = categories[cat_idx]
			var sample_color := _resolve_sample_color(p_series_index, cat_idx, x_value, y_value)
			_append_with_interpolation(run, run_colors, _layout.map_point_to_screen(x_px, y_px), sample_color, interpolation)

		_finalize_run(run, run_colors, width_px, interpolation, dash_px)


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
	# When p_dash_px is 0, the polyline is emitted via path 1 (draw_polyline_colors).
	# Otherwise it is emitted via path 2: dash phase is precomputed across the
	# whole polyline and the resulting "on" intervals are flushed in a single
	# draw_multiline_colors() call. p_dash_px is the resolved per-series dash
	# length obtained from TauLineStyle.get_series_dash_px().
	func _finalize_run(p_run: PackedVector2Array, p_run_colors: PackedColorArray, p_width_px: float, p_mode: TauLineConfig.InterpolationMode, p_dash_px: int) -> void:
		var polyline: PackedVector2Array = p_run
		var polyline_colors: PackedColorArray = p_run_colors
		if p_mode == TauLineConfig.InterpolationMode.SMOOTH_MONOTONE and p_run.size() > 2:
			var resampled := _resample_smooth_monotone(p_run, p_run_colors)
			polyline = resampled[0]
			polyline_colors = resampled[1]
		if polyline.size() < 2:
			return

		var dash_px: int = max(p_dash_px, 0)
		if dash_px <= 0:
			draw_polyline_colors(polyline, polyline_colors, p_width_px)
		else:
			_draw_dashed_polyline(polyline, polyline_colors, p_width_px, float(dash_px))


	# Builds the flat segment array of "on" dash intervals along p_polyline and
	# emits it with a single draw_multiline_colors() call. The dash period is
	# 2 * p_dash_px (one "on" length followed by one "off" length of equal
	# size). Dash phase is tracked as a single scalar that advances along the
	# polyline arc length, so the pattern is continuous across consecutive
	# segments and does not reset at sample positions.
	#
	# draw_multiline_colors takes one solid color per emitted segment (a pair
	# of points). Each "on" interval gets the color of its midpoint along the
	# enclosing polyline segment, computed by linear interpolation between the
	# two flanking polyline-vertex colors. For typical dash sizes this is a
	# good approximation of the per-vertex color gradient produced by the
	# undashed path.
	#
	# Degenerate segments (zero length) are skipped: they cannot carry any
	# dash and do not advance the phase.
	func _draw_dashed_polyline(p_polyline: PackedVector2Array, p_polyline_colors: PackedColorArray, p_width_px: float, p_dash_px: float) -> void:
		var period: float = p_dash_px * 2.0
		var n := p_polyline.size()
		var phase: float = 0.0
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
	# polyline for that run and emit a one-shot warning.
	#
	# Sub-sample colors are linearly interpolated between the two flanking
	# kept-sample colors so that the visual color gradient matches what
	# draw_polyline_colors would produce on a LINEAR polyline through the
	# same kept samples.
	#
	# Returns [points: PackedVector2Array, colors: PackedColorArray].
	func _resample_smooth_monotone(p_points: PackedVector2Array, p_colors: PackedColorArray) -> Array:
		var direction := _detect_monotonic_x_direction(p_points)
		if direction == 0:
			if not _smooth_non_monotonic_warned:
				push_warning("LineRenderer: SMOOTH_MONOTONE received samples whose screen X is not monotonic. Falling back to a straight polyline for the affected run. Use LINEAR interpolation if your data does not have a monotonic X parameter.")
				_smooth_non_monotonic_warned = true
			return [p_points, p_colors]

		var ascending: bool = direction > 0

		# Build strictly increasing X arrays, dropping flat-X duplicates.
		# Colors are kept in lock-step with the kept points.
		var xs := PackedFloat32Array()
		var ys := PackedFloat32Array()
		var cs := PackedColorArray()
		var input_count := p_points.size()
		if ascending:
			xs.append(p_points[0].x)
			ys.append(p_points[0].y)
			cs.append(p_colors[0])
			for i in range(1, input_count):
				if p_points[i].x > xs[xs.size() - 1]:
					xs.append(p_points[i].x)
					ys.append(p_points[i].y)
					cs.append(p_colors[i])
		else:
			xs.append(p_points[input_count - 1].x)
			ys.append(p_points[input_count - 1].y)
			cs.append(p_colors[input_count - 1])
			for i in range(input_count - 2, -1, -1):
				if p_points[i].x > xs[xs.size() - 1]:
					xs.append(p_points[i].x)
					ys.append(p_points[i].y)
					cs.append(p_colors[i])

		var n := xs.size()
		if n < 2:
			# All inputs collapsed to a single screen X. Nothing to draw.
			return [PackedVector2Array(), PackedColorArray()]
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
			return [trivial, trivial_colors]

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
		return [out, out_colors]


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

	# Combined per-sample color resolution. The alpha resolved by
	# _resolve_sample_alpha overwrites the alpha channel of the color resolved
	# by _resolve_sample_color_only.
	func _resolve_sample_color(p_series_index: int, p_sample_index: int, p_x_value: Variant, p_y_value: float) -> Color:
		var base := _resolve_sample_color_only(p_series_index, p_sample_index, p_x_value, p_y_value)
		var alpha := _resolve_sample_alpha(p_series_index, p_sample_index, p_x_value, p_y_value)
		base.a = clampf(alpha, 0.0, 1.0)
		return base


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
