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
# - TauLineConfig.interpolation_mode controls the curve drawn between two
#   consecutive valid samples. LINEAR draws straight segments. The step
#   modes (STEP_BEFORE, STEP_AFTER, STEP_MIDDLE) insert synthetic
#   intermediate points in screen space into the polyline. SMOOTH_MONOTONE
#   replaces each segment with a fixed number of sub-samples from a
#   Fritsch-Carlson piecewise cubic Hermite curve evaluated in screen space.
#   Whichever interpolation is active, a contiguous run is still drawn with a
#   single draw_polyline() call.
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
		var interpolation: TauLineConfig.InterpolationMode = _line_config.interpolation_mode

		var run := PackedVector2Array()

		var is_shared_x := _dataset.get_mode() == Dataset.Mode.SHARED_X
		var sample_count := _dataset.get_series_sample_count(series_id)

		for i in range(sample_count):
			var x_value: float = float(_dataset.get_shared_x(i)) if is_shared_x else float(_dataset.get_series_x(series_id, i))
			if is_nan(x_value) or is_inf(x_value) or not _is_x_value_valid_for_scale(x_value):
				if not bridge:
					_finalize_run(run, color, p_width_px, interpolation)
					run = PackedVector2Array()
				continue

			var y_value := _dataset.get_series_y(series_id, i)
			if is_nan(y_value) or is_inf(y_value) or not _is_y_value_valid_for_scale(series_id, y_value):
				if not bridge:
					_finalize_run(run, color, p_width_px, interpolation)
					run = PackedVector2Array()
				continue

			var x_px := _layout.map_x_to_px(_pane_index, x_value)
			var y_px := _layout.map_y_to_px(_pane_index, y_value, y_axis_id)
			_append_with_interpolation(run, _layout.map_point_to_screen(x_px, y_px), interpolation)

		_finalize_run(run, color, p_width_px, interpolation)


	func _draw_series_categorical(p_series_index: int, p_width_px: float) -> void:
		var series_id := _get_line_series_id(p_series_index)
		var global_series_index := _get_global_series_index(p_series_index)
		var color := _resolve_series_color(global_series_index)
		var y_axis_id := _get_y_axis_id_for_series(series_id)
		var bridge: bool = _line_config.gap_policy == TauLineConfig.GapPolicy.BRIDGE
		var interpolation: TauLineConfig.InterpolationMode = _line_config.interpolation_mode

		var run := PackedVector2Array()
		var sample_count := _dataset.get_series_sample_count(series_id)

		for cat_idx in range(sample_count):
			var y_value := _dataset.get_series_y(series_id, cat_idx)
			if is_nan(y_value) or is_inf(y_value) or not _is_y_value_valid_for_scale(series_id, y_value):
				if not bridge:
					_finalize_run(run, color, p_width_px, interpolation)
					run = PackedVector2Array()
				continue

			var x_px := _layout.map_x_category_center_to_px(_pane_index, cat_idx)
			var y_px := _layout.map_y_to_px(_pane_index, y_value, y_axis_id)
			_append_with_interpolation(run, _layout.map_point_to_screen(x_px, y_px), interpolation)

		_finalize_run(run, color, p_width_px, interpolation)


	func _append_with_interpolation(p_run: PackedVector2Array, p_point: Vector2, p_mode: TauLineConfig.InterpolationMode) -> void:
		# SMOOTH_MONOTONE buffers raw sample points untouched: cubic resampling
		# requires the full neighborhood of every sample to compute tangents and
		# is therefore deferred to _finalize_run().
		if p_run.size() == 0 or p_mode == TauLineConfig.InterpolationMode.LINEAR or p_mode == TauLineConfig.InterpolationMode.SMOOTH_MONOTONE:
			p_run.append(p_point)
			return

		var last_pt: Vector2 = p_run[p_run.size() - 1]
		match p_mode:
			TauLineConfig.InterpolationMode.STEP_BEFORE:
				p_run.append(Vector2(last_pt.x, p_point.y))
			TauLineConfig.InterpolationMode.STEP_AFTER:
				p_run.append(Vector2(p_point.x, last_pt.y))
			TauLineConfig.InterpolationMode.STEP_MIDDLE:
				var mid_x: float = (last_pt.x + p_point.x) * 0.5
				p_run.append(Vector2(mid_x, last_pt.y))
				p_run.append(Vector2(mid_x, p_point.y))
		p_run.append(p_point)


	####################################################################################################
	# Smooth-monotone (Fritsch-Carlson) resampling
	####################################################################################################

	# Number of sub-segments inserted between two consecutive samples by
	# SMOOTH_MONOTONE. The value balances visual smoothness on a typical
	# screen against the per-segment cost paid by draw_polyline().
	const _SMOOTH_SUBDIVISIONS: int = 16


	# Draw the polyline for one buffered run.
	# For LINEAR and the step modes the buffered run is already the final polyline.
	# For SMOOTH_MONOTONE the run is first replaced by its Fritsch-Carlson piecewise cubic resampling.
	# Runs of fewer than two points are silently dropped.
	func _finalize_run(p_run: PackedVector2Array, p_color: Color, p_width_px: float, p_mode: TauLineConfig.InterpolationMode) -> void:
		var polyline: PackedVector2Array = p_run
		if p_mode == TauLineConfig.InterpolationMode.SMOOTH_MONOTONE and p_run.size() > 2:
			polyline = _resample_smooth_monotone(p_run)
		if polyline.size() >= 2:
			draw_polyline(polyline, p_color, p_width_px)


	# Builds the Fritsch-Carlson piecewise cubic Hermite curve through p_points
	# and returns it sampled at _SMOOTH_SUBDIVISIONS sub-segments per input
	# segment. Operates in screen space (the input is already in pixels), which
	# keeps the curve visually smooth regardless of axis scale.
	#
	# The algorithm requires strictly monotonic X. The expected case is
	# monotonically increasing screen X, but a user-inverted X axis produces
	# monotonically decreasing screen X. Both directions are accepted: the
	# input is processed internally on a strictly increasing X copy and the
	# output is reversed back when needed. Consecutive points sharing the same
	# screen X are dropped since the secant slope is undefined at h = 0.
	# Inputs that are not monotonic in either direction fall back to the raw
	# polyline for that run and emit a one-shot warning.
	func _resample_smooth_monotone(p_points: PackedVector2Array) -> PackedVector2Array:
		var direction := _detect_monotonic_x_direction(p_points)
		if direction == 0:
			if not _smooth_non_monotonic_warned:
				push_warning("LineRenderer: SMOOTH_MONOTONE received samples whose screen X is not monotonic. Falling back to a straight polyline for the affected run. Use LINEAR interpolation if your data does not have a monotonic X parameter.")
				_smooth_non_monotonic_warned = true
			return p_points

		var ascending: bool = direction > 0

		# Build strictly increasing X arrays, dropping flat-X duplicates.
		var xs := PackedFloat32Array()
		var ys := PackedFloat32Array()
		var input_count := p_points.size()
		if ascending:
			xs.append(p_points[0].x)
			ys.append(p_points[0].y)
			for i in range(1, input_count):
				if p_points[i].x > xs[xs.size() - 1]:
					xs.append(p_points[i].x)
					ys.append(p_points[i].y)
		else:
			xs.append(p_points[input_count - 1].x)
			ys.append(p_points[input_count - 1].y)
			for i in range(input_count - 2, -1, -1):
				if p_points[i].x > xs[xs.size() - 1]:
					xs.append(p_points[i].x)
					ys.append(p_points[i].y)

		var n := xs.size()
		if n < 2:
			# All inputs collapsed to a single screen X. Nothing to draw.
			return PackedVector2Array()
		if n == 2:
			# Two distinct X values produce a straight line through Hermite
			# with both tangents equal to the secant slope. Short-circuit.
			var trivial := PackedVector2Array()
			trivial.append(Vector2(xs[0], ys[0]))
			trivial.append(Vector2(xs[1], ys[1]))
			if not ascending:
				trivial.reverse()
			return trivial

		var tangents := _fritsch_carlson_tangents(xs, ys)

		var out := PackedVector2Array()
		# Pre-size the output for speed: n-1 segments times subdivisions plus
		# the very first sample.
		out.resize(1 + (n - 1) * _SMOOTH_SUBDIVISIONS)
		out[0] = Vector2(xs[0], ys[0])

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
				write_index += 1

		if not ascending:
			out.reverse()
		return out


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
