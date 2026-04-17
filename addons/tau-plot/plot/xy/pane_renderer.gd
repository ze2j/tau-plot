# Dependencies
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout
const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const Axis = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis
const TickSequence := preload("res://addons/tau-plot/plot/xy/tick_sequence.gd").TickSequence

# Draws the axes, ticks and tick labels of a single pane.
# It relies on XYLayout for pane_rect, mappings, ticks and formatting policy.
class PaneRenderer extends Control:
	var _pane_index: int = 0
	var _layout: XYLayout
	var _xy_style: TauXYStyle = null
	var _resolved_pane_style: TauPaneStyle = null
	var _grid_line_config: TauGridLineConfig = TauGridLineConfig.new()

	## Callable set by xy_plot to receive forwarded mouse input.
	## Signature: func(pane_index: int, event: InputEvent, local_pos: Vector2) -> void
	var _hover_input_callback: Callable = Callable()

	## When true, this pane captures mouse events for hover hit testing.
	var _hover_active: bool = false


	func _init(p_pane_index: int, p_layout: XYLayout, p_xy_style: TauXYStyle) -> void:
		theme_type_variation = &"TauPane"
		_pane_index = p_pane_index
		_layout = p_layout
		_xy_style = p_xy_style


	func _ready() -> void:
		queue_redraw()


	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_RESIZED:
				queue_redraw()


	## Enables or disables mouse capture for hover hit testing.
	## When enabled, mouse_filter is set to STOP so _gui_input receives events.
	## When disabled, mouse_filter is set to IGNORE to avoid overhead.
	func set_hover_active(p_active: bool, p_callback: Callable = Callable()) -> void:
		_hover_active = p_active
		_hover_input_callback = p_callback
		if p_active:
			mouse_filter = Control.MOUSE_FILTER_STOP
			focus_mode = Control.FOCUS_CLICK
		else:
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			focus_mode = Control.FOCUS_NONE


	## Receives the resolved TauXYStyle from xy_plot after cascade resolution.
	func set_resolved_xy_style(p_style: TauXYStyle) -> void:
		_xy_style = p_style


	func set_resolved_pane_style(p_pane_style: TauPaneStyle) -> void:
		_resolved_pane_style = p_pane_style


	func set_grid_line_config(p_grid_line_config: TauGridLineConfig) -> void:
		_grid_line_config = p_grid_line_config


	func _gui_input(p_event: InputEvent) -> void:
		if not _hover_active:
			return
		if not _hover_input_callback.is_valid():
			return

		if p_event is InputEventMouseMotion:
			_hover_input_callback.call(_pane_index, p_event, (p_event as InputEventMouseMotion).position)
		elif p_event is InputEventMouseButton:
			_hover_input_callback.call(_pane_index, p_event, (p_event as InputEventMouseButton).position)
		elif p_event is InputEventKey:
			_hover_input_callback.call(_pane_index, p_event, Vector2.ZERO)


	func on_mouse_exited() -> void:
		if not _hover_active:
			return
		if not _hover_input_callback.is_valid():
			return
		# Pass null event to signal mouse exit from this pane.
		_hover_input_callback.call(_pane_index, null, Vector2.ZERO)


	func _draw() -> void:
		if _xy_style == null or _xy_style.label_font == null:
			return

		var pane_rect := _layout.get_pane_rect(_pane_index)
		if pane_rect.size.x <= 0.0 or pane_rect.size.y <= 0.0:
			return

		var axis_color := _xy_style.axis_color
		var pane_layout := _get_pane_layout()
		if pane_layout == null:
			return

		var x_left := pane_rect.position.x
		var x_right := pane_rect.position.x + pane_rect.size.x
		var y_top := pane_rect.position.y
		var y_bottom := pane_rect.position.y + pane_rect.size.y

		var x_cfg := _get_x_config()
		var categories: PackedStringArray = _layout.domain.x_categories
		var x_axis_id := _layout.domain.config.x_axis_id

		# ---- Phase 1: Axis lines ----

		# Primary X axis line
		if x_cfg != null and pane_layout.draws_x:
			match x_axis_id:
				AxisId.BOTTOM:
					draw_line(Vector2(x_left, y_bottom), Vector2(x_right, y_bottom), axis_color)
				AxisId.TOP:
					draw_line(Vector2(x_left, y_top), Vector2(x_right, y_top), axis_color)
				AxisId.LEFT:
					draw_line(Vector2(x_left, y_top), Vector2(x_left, y_bottom), axis_color)
				AxisId.RIGHT:
					draw_line(Vector2(x_right, y_top), Vector2(x_right, y_bottom), axis_color)

		# Secondary X axis line
		if _layout.domain.config.secondary_x_axis != null and pane_layout.draws_secondary_x:
			var secondary_edge := Axis.get_opposite(x_axis_id)
			match secondary_edge:
				AxisId.BOTTOM:
					draw_line(Vector2(x_left, y_bottom), Vector2(x_right, y_bottom), axis_color)
				AxisId.TOP:
					draw_line(Vector2(x_left, y_top), Vector2(x_right, y_top), axis_color)
				AxisId.LEFT:
					draw_line(Vector2(x_left, y_top), Vector2(x_left, y_bottom), axis_color)
				AxisId.RIGHT:
					draw_line(Vector2(x_right, y_top), Vector2(x_right, y_bottom), axis_color)

		# Y axis lines
		var y_axes: Array[AxisId] = Axis.get_orthogonal_axes(x_axis_id)
		for axis_id in y_axes:
			var ticks = pane_layout.y_ticks.get(axis_id)
			if ticks == null:
				continue
			match axis_id:
				AxisId.LEFT:
					draw_line(Vector2(x_left, y_top), Vector2(x_left, y_bottom), axis_color)
				AxisId.RIGHT:
					draw_line(Vector2(x_right, y_top), Vector2(x_right, y_bottom), axis_color)
				AxisId.BOTTOM:
					draw_line(Vector2(x_left, y_bottom), Vector2(x_right, y_bottom), axis_color)
				AxisId.TOP:
					draw_line(Vector2(x_left, y_top), Vector2(x_right, y_top), axis_color)

		# ---- Phase 2: Grid lines ----

		_draw_grid_lines(pane_layout, pane_rect, x_axis_id)

		# ---- Phase 3: Ticks and labels ----

		# Primary X axis ticks and labels
		if x_cfg != null and pane_layout.draws_x:
			_draw_edge_ticks_and_labels(
				x_axis_id,
				_layout.x_ticks,
				pane_rect,
				axis_color,
				_decorate_x,
				categories,
				func(idx: int) -> bool: return _layout.should_show_x_categorical_label(_pane_index, idx),
				func(val: float) -> float: return _layout.map_x_to_px(_pane_index, val),
				x_cfg)

		# Secondary X axis ticks and labels
		var secondary_x_cfg := _layout.domain.config.secondary_x_axis
		if secondary_x_cfg != null and pane_layout.draws_secondary_x:
			var secondary_edge := Axis.get_opposite(x_axis_id)
			_draw_edge_ticks_and_labels(
				secondary_edge,
				_layout.secondary_x_ticks,
				pane_rect,
				axis_color,
				_decorate_secondary_x,
				categories,
				func(idx: int) -> bool: return _layout.should_show_secondary_x_categorical_label(_pane_index, idx),
				func(val: float) -> float: return _layout.map_secondary_x_to_px(_pane_index, val),
				secondary_x_cfg)

		# Y axis ticks and labels
		for axis_id in y_axes:
			var ticks = pane_layout.y_ticks.get(axis_id)
			if ticks == null:
				continue
			_draw_edge_ticks_and_labels(
				axis_id,
				ticks,
				pane_rect,
				axis_color,
				func(text: String) -> String: return _decorate_y(text, axis_id),
				PackedStringArray(),
				Callable(),
				func(val: float) -> float: return _layout.map_y_to_px(_pane_index, val, axis_id),
				null)


	####################################################################################################
	# Private -- Grid line drawing
	####################################################################################################

	## Draws all enabled grid lines for this pane.
	## Called between axis lines and tick/label drawing so that grid lines sit
	## behind ticks but in front of the axis lines.
	func _draw_grid_lines(
		p_pane_layout: XYLayout.PaneLayout,
		p_pane_rect: Rect2,
		p_x_axis_id: AxisId
	) -> void:
		if _grid_line_config == null:
			return

		var x_is_horizontal := _layout._x_is_horizontal

		# X grid lines: resolve which X axis supplies the tick positions.
		var x_ticks: TickSequence = _resolve_grid_line_x_ticks()
		if x_ticks != null:
			var x_map_callable: Callable
			var has_secondary := _layout.domain.config.secondary_x_axis != null
			var secondary_x_position := Axis.get_opposite(p_x_axis_id)
			if has_secondary and _grid_line_config.x_source_axis_id == secondary_x_position:
				x_map_callable = func(val: float) -> float: return _layout.map_secondary_x_to_px(_pane_index, val)
			else:
				x_map_callable = func(val: float) -> float: return _layout.map_x_to_px(_pane_index, val)
			if _grid_line_config.x_major_enabled:
				_draw_grid_lines_for_ticks(
					x_ticks.major_ticks,
					p_pane_rect,
					true,
					x_is_horizontal,
					_resolved_pane_style.x_major_grid_line_color,
					_resolved_pane_style.x_major_grid_line_thickness_px,
					_resolved_pane_style.x_major_grid_line_dash_px,
					x_map_callable)
			if _grid_line_config.x_minor_enabled:
				_draw_grid_lines_for_ticks(
					x_ticks.minor_ticks,
					p_pane_rect,
					true,
					x_is_horizontal,
					_resolved_pane_style.x_minor_grid_line_color,
					_resolved_pane_style.x_minor_grid_line_thickness_px,
					_resolved_pane_style.x_minor_grid_line_dash_px,
					x_map_callable)

		# Y grid lines: resolve which Y axis supplies the tick positions.
		var y_axis_id := _resolve_grid_line_y_axis(p_pane_layout, p_x_axis_id)
		if y_axis_id == -1:
			return
		var y_ticks: TickSequence = p_pane_layout.y_ticks.get(y_axis_id)
		if y_ticks == null:
			return

		if _grid_line_config.y_major_enabled:
			_draw_grid_lines_for_ticks(
				y_ticks.major_ticks,
				p_pane_rect,
				false,
				x_is_horizontal,
				_resolved_pane_style.y_major_grid_line_color,
				_resolved_pane_style.y_major_grid_line_thickness_px,
				_resolved_pane_style.y_major_grid_line_dash_px,
				func(val: float) -> float: return _layout.map_y_to_px(_pane_index, val, y_axis_id))
		if _grid_line_config.y_minor_enabled:
			_draw_grid_lines_for_ticks(
				y_ticks.minor_ticks,
				p_pane_rect,
				false,
				x_is_horizontal,
				_resolved_pane_style.y_minor_grid_line_color,
				_resolved_pane_style.y_minor_grid_line_thickness_px,
				_resolved_pane_style.y_minor_grid_line_dash_px,
				func(val: float) -> float: return _layout.map_y_to_px(_pane_index, val, y_axis_id))


	## Resolves which X axis should supply tick positions for X grid lines.
	##
	## When no secondary x axis is configured, always returns primary ticks.
	## Otherwise compares [member TauGridLineConfig.x_source_axis_id] against the
	## primary and secondary x edge positions to decide which tick sequence
	## to return. Returns null if X grid lines are disabled or the selected
	## axis has no ticks.
	func _resolve_grid_line_x_ticks() -> TickSequence:
		if not _grid_line_config.x_major_enabled and not _grid_line_config.x_minor_enabled:
			return null

		# When no secondary x axis exists, x_source_axis_id is irrelevant.
		if _layout.domain.config.secondary_x_axis == null:
			return _layout.x_ticks

		var x_axis_id := _layout.domain.config.x_axis_id
		var secondary_x_position := Axis.get_opposite(x_axis_id)
		var source := _grid_line_config.x_source_axis_id

		if source == secondary_x_position:
			if _layout.secondary_x_ticks != null:
				return _layout.secondary_x_ticks
			push_error("TauGridLineConfig.x_source_axis_id points to the secondary x axis edge (%d) but that axis has no ticks" % source)
			return null

		if source != x_axis_id:
			push_error("TauGridLineConfig.x_source_axis_id (%d) does not match the primary (%d) or secondary (%d) x axis edge" % [source, x_axis_id, secondary_x_position])
			return null

		return _layout.x_ticks


	## Resolves which Y axis should supply tick positions for Y grid lines.
	##
	## Returns the AxisId to use, or -1 if no Y grid lines should be drawn
	## (because neither Y major nor Y minor is enabled, or because no Y axis
	## is populated in this pane).
	func _resolve_grid_line_y_axis(
		p_pane_layout: XYLayout.PaneLayout,
		p_x_axis_id: AxisId
	) -> int:
		if not _grid_line_config.y_major_enabled and not _grid_line_config.y_minor_enabled:
			return -1

		var y_axes: Array[AxisId] = Axis.get_orthogonal_axes(p_x_axis_id)
		var populated: Array[AxisId] = []
		for y_id in y_axes:
			if p_pane_layout.y_ticks.has(y_id):
				populated.append(y_id)

		if populated.size() == 0:
			return -1
		if populated.size() == 1:
			return populated[0]
		if _grid_line_config.y_source_axis_id in populated:
			return _grid_line_config.y_source_axis_id	# Two populated Y axes: use the config preference.

		# Fallback: use the first populated axis if the configured one is not available.
		push_error("The specified y-axis %d for grid lines is not a valid y-axis" % _grid_line_config.y_source_axis_id)
		return populated[0]


	## Draws grid lines for an array of tick values.
	##
	## [param p_tick_values] Array of domain values where lines are drawn.
	## [param p_pane_rect] The pane data-area rectangle.
	## [param p_is_x_grid_line] True for X grid lines (perpendicular to x axis),
	##   false for Y grid lines (perpendicular to y axis).
	## [param p_x_is_horizontal] True when the x axis runs along screen-X.
	## [param p_color] Line color.
	## [param p_thickness_px] Line thickness in pixels.
	## [param p_dash_px] Dash segment length. 0 means solid.
	## [param p_map_fn] Maps a domain value to a pixel coordinate along the
	##   axis direction. For X grid lines this returns screen-X (when x is
	##   horizontal) or screen-Y (when x is vertical). For Y grid lines it
	##   returns screen-Y (when x is horizontal) or screen-X (when x is vertical).
	func _draw_grid_lines_for_ticks(
		p_tick_values: Array[float],
		p_pane_rect: Rect2,
		p_is_x_grid_line: bool,
		p_x_is_horizontal: bool,
		p_color: Color,
		p_thickness_px: int,
		p_dash_px: int,
		p_map_fn: Callable
	) -> void:
		if p_color.a <= 0.0 or p_thickness_px <= 0:
			return

		var thickness := float(p_thickness_px)

		# Determine the direction the grid line extends across the pane.
		#
		# X grid lines cross the pane perpendicular to the x axis:
		#   x horizontal -> lines are vertical (fixed screen-X, span screen-Y)
		#   x vertical   -> lines are horizontal (fixed screen-Y, span screen-X)
		#
		# Y grid lines cross the pane perpendicular to the y axis:
		#   x horizontal -> y is vertical, so lines are horizontal (fixed screen-Y, span screen-X)
		#   x vertical   -> y is horizontal, so lines are vertical (fixed screen-X, span screen-Y)
		var line_is_vertical: bool
		if p_is_x_grid_line:
			line_is_vertical = p_x_is_horizontal
		else:
			line_is_vertical = not p_x_is_horizontal

		var rect_x_min := p_pane_rect.position.x
		var rect_x_max := p_pane_rect.position.x + p_pane_rect.size.x
		var rect_y_min := p_pane_rect.position.y
		var rect_y_max := p_pane_rect.position.y + p_pane_rect.size.y

		for tick_val in p_tick_values:
			var px: float = p_map_fn.call(tick_val)
			var from: Vector2
			var to: Vector2
			if line_is_vertical:
				from = Vector2(px, rect_y_min)
				to = Vector2(px, rect_y_max)
			else:
				from = Vector2(rect_x_min, px)
				to = Vector2(rect_x_max, px)
			if p_dash_px > 0:
				draw_dashed_line(from, to, p_color, thickness, float(p_dash_px))
			else:
				draw_line(from, to, p_color, thickness)


	####################################################################################################
	# Private -- Pane and config accessors
	####################################################################################################

	func _get_pane_layout() -> XYLayout.PaneLayout:
		if _pane_index < 0 or _pane_index >= _layout.pane_layouts.size():
			return null
		return _layout.pane_layouts[_pane_index]


	func _get_x_config() -> TauAxisConfig:
		return _layout.domain.config.x_axis


	####################################################################################################
	# Private -- Label measurement and decoration
	####################################################################################################

	func _measure_label(p_label: String) -> Vector2:
		return _xy_style.label_font.get_string_size(p_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _xy_style.label_font_size)


	func _decorate_x(p_text: String) -> String:
		var cfg := _get_x_config()
		if cfg == null or cfg.format_tick_label.is_null():
			return p_text
		return cfg.format_tick_label.call(p_text)


	func _decorate_secondary_x(p_text: String) -> String:
		var cfg := _layout.domain.config.secondary_x_axis
		if cfg == null or cfg.format_tick_label.is_null():
			return p_text
		return cfg.format_tick_label.call(p_text)


	func _decorate_y(p_text: String, p_axis_id: AxisId) -> String:
		var pane_domain := _layout.domain.get_pane_domain(_pane_index)
		if pane_domain == null:
			return p_text
		var y_axis_domain := pane_domain.get_y_axis_domain(p_axis_id)
		if y_axis_domain == null or y_axis_domain.config == null or y_axis_domain.config.format_tick_label.is_null():
			return p_text
		return y_axis_domain.config.format_tick_label.call(p_text)


	func _draw_label(p_text: String, p_pos: Vector2) -> void:
		# draw_string() uses p_pos as baseline, not top-left.
		var ascent := _xy_style.label_font.get_ascent(_xy_style.label_font_size)
		draw_string(_xy_style.label_font, p_pos + Vector2(0.0, ascent), p_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _xy_style.label_font_size, _xy_style.label_color)


	####################################################################################################
	# Private -- Generic edge-based tick and label drawing
	####################################################################################################

	## Draws ticks and labels for a single edge of the pane rectangle.
	## Works for all four edges: BOTTOM, TOP, LEFT, RIGHT.
	##
	## [param p_axis_id] Which physical edge to draw on.
	## [param p_ticks] Tick sequence (null for categorical-only axes).
	## [param p_pane_rect] The pane rectangle in screen coordinates.
	## [param p_axis_color] Color for tick marks.
	## [param p_decorate_fn] Label decoration callback (e.g. _decorate_x).
	## [param p_categories] Category names (empty for continuous axes).
	## [param p_should_show_cat_label_fn] Callable(int) -> bool for categorical visibility, or null.
	## [param p_map_fn] Callable(float) -> float mapping a domain value to a pixel coordinate.
	## [param p_cfg] TauAxisConfig for this edge (null for y edges that only have continuous ticks).
	func _draw_edge_ticks_and_labels(
		p_axis_id: AxisId,
		p_ticks: TickSequence,
		p_pane_rect: Rect2,
		p_axis_color: Color,
		p_decorate_fn: Callable,
		p_categories: PackedStringArray,
		p_should_show_cat_label_fn: Callable,
		p_map_fn: Callable,
		p_cfg: TauAxisConfig
	) -> void:
		var is_horizontal := (p_axis_id == AxisId.BOTTOM or p_axis_id == AxisId.TOP)

		if is_horizontal:
			_draw_edge_horizontal(p_axis_id, p_ticks, p_pane_rect, p_axis_color, p_decorate_fn, p_categories, p_should_show_cat_label_fn, p_map_fn, p_cfg)
		else:
			_draw_edge_vertical(p_axis_id, p_ticks, p_pane_rect, p_axis_color, p_decorate_fn, p_categories, p_should_show_cat_label_fn, p_map_fn, p_cfg)


	## Draws ticks and labels along a horizontal edge (BOTTOM or TOP).
	func _draw_edge_horizontal(
		p_axis_id: AxisId,
		p_ticks: TickSequence,
		p_pane_rect: Rect2,
		p_axis_color: Color,
		p_decorate_fn: Callable,
		p_categories: PackedStringArray,
		p_should_show_cat_label_fn: Callable,
		p_map_fn: Callable,
		p_cfg: TauAxisConfig
	) -> void:
		var is_bottom := (p_axis_id == AxisId.BOTTOM)
		# Tick direction: bottom ticks extend downward (+1), top ticks extend upward (-1).
		var tick_dir := 1.0 if is_bottom else -1.0
		# p_cfg is non-null for x axes, null for y axes. Pick the matching tick metrics
		# so that the drawn tick size matches the space reserved by _measure_x/y_axis_labels.
		var is_x_axis := (p_cfg != null)
		var tick_length := float(_xy_style.x_major_tick_length_px) if is_x_axis else float(_xy_style.y_major_tick_length_px)
		var tick_thickness := float(_xy_style.x_major_tick_thickness_px) if is_x_axis else float(_xy_style.y_major_tick_thickness_px)
		var label_gap := float(_xy_style.x_tick_x_label_gap_px) if is_x_axis else float(_xy_style.y_tick_y_label_gap_px)
		var axis_y: float = p_pane_rect.position.y + p_pane_rect.size.y if is_bottom else p_pane_rect.position.y

		if is_x_axis and p_cfg.type == TauAxisConfig.Type.CATEGORICAL:
			var n := p_categories.size()
			if n <= 0:
				return
			var step_px := p_pane_rect.size.x / float(n)

			# N+1 boundary tick marks
			for i in range(n + 1):
				var x := p_pane_rect.position.x + float(i) * step_px
				draw_line(Vector2(x, axis_y), Vector2(x, axis_y + tick_dir * tick_length), p_axis_color, tick_thickness)

			# Category labels
			for i in range(n):
				if not p_should_show_cat_label_fn.is_null() and not p_should_show_cat_label_fn.call(i):
					continue
				var label: String = p_decorate_fn.call(p_categories[i])
				var label_size := _measure_label(label)
				# By default a horizontal axis displays the first category on the left,
				# when inverted the first category is on the right.
				var slot := (n - 1 - i) if p_cfg.inverted else i
				var label_center_x := p_pane_rect.position.x + (float(slot) + 0.5) * step_px
				var label_y: float
				if is_bottom:
					label_y = axis_y + tick_length + label_gap
				else:
					label_y = axis_y - tick_length - label_gap - label_size.y
				_draw_label(label, Vector2(label_center_x - label_size.x * 0.5, label_y))
			return

		# Continuous path.
		if p_ticks == null:
			return
		# Major ticks
		for i in range(p_ticks.major_ticks.size()):
			var t := p_ticks.major_ticks[i]
			var x: float = p_map_fn.call(t)
			draw_line(Vector2(x, axis_y), Vector2(x, axis_y + tick_dir * tick_length), p_axis_color, tick_thickness)

			if p_ticks.should_show_label(i):
				var label: String = p_decorate_fn.call(p_ticks.format_value(t))
				var label_size := _measure_label(label)
				var label_y: float
				if is_bottom:
					label_y = axis_y + tick_length + label_gap
				else:
					label_y = axis_y - tick_length - label_gap - label_size.y
				_draw_label(label, Vector2(x - label_size.x * 0.5, label_y))

		# Minor ticks
		var minor_tick_length := tick_length * clampf(_xy_style.minor_tick_length_ratio, 0.0, 1.0)
		var minor_tick_thickness := float(_xy_style.x_minor_tick_thickness_px) if is_x_axis else float(_xy_style.y_minor_tick_thickness_px)
		for t in p_ticks.minor_ticks:
			var x: float = p_map_fn.call(t)
			draw_line(Vector2(x, axis_y), Vector2(x, axis_y + tick_dir * minor_tick_length), p_axis_color, minor_tick_thickness)


	## Draws ticks and labels along a vertical edge (LEFT or RIGHT).
	## Supports both continuous (tick-based) and categorical axes.
	func _draw_edge_vertical(
		p_axis_id: AxisId,
		p_ticks: TickSequence,
		p_pane_rect: Rect2,
		p_axis_color: Color,
		p_decorate_fn: Callable,
		p_categories: PackedStringArray,
		p_should_show_cat_label_fn: Callable,
		p_map_fn: Callable,
		p_cfg: TauAxisConfig
	) -> void:
		var is_left := (p_axis_id == AxisId.LEFT)
		# Tick direction: left ticks extend leftward (-1), right ticks extend rightward (+1).
		var tick_dir := -1.0 if is_left else 1.0
		# p_cfg is non-null for x axes, null for y axes. Pick the matching tick metrics
		# so that the drawn tick size matches the space reserved by _measure_x/y_axis_labels.
		var is_x_axis := (p_cfg != null)
		var tick_length := float(_xy_style.x_major_tick_length_px) if is_x_axis else float(_xy_style.y_major_tick_length_px)
		var tick_thickness := float(_xy_style.x_major_tick_thickness_px) if is_x_axis else float(_xy_style.y_major_tick_thickness_px)
		var label_gap := float(_xy_style.x_tick_x_label_gap_px) if is_x_axis else float(_xy_style.y_tick_y_label_gap_px)
		var axis_x: float = p_pane_rect.position.x if is_left else p_pane_rect.position.x + p_pane_rect.size.x

		if is_x_axis and p_cfg.type == TauAxisConfig.Type.CATEGORICAL:
			var n := p_categories.size()
			if n <= 0:
				return
			var step_px := p_pane_rect.size.y / float(n)

			# N+1 boundary tick marks extending horizontally from the axis line.
			for i in range(n + 1):
				var y := p_pane_rect.position.y + float(i) * step_px
				draw_line(Vector2(axis_x, y), Vector2(axis_x + tick_dir * tick_length, y), p_axis_color, tick_thickness)

			# Category labels centered vertically in each slot.
			for i in range(n):
				if not p_should_show_cat_label_fn.is_null() and not p_should_show_cat_label_fn.call(i):
					continue
				var label: String = p_decorate_fn.call(p_categories[i])
				var label_size := _measure_label(label)
				# By default a vertical axis displays the first category at the bottom,
				# when inverted the first category is at the top.
				var slot := i if p_cfg.inverted else (n - 1 - i)
				var label_center_y := p_pane_rect.position.y + (float(slot) + 0.5) * step_px
				var label_x: float
				if is_left:
					label_x = axis_x - tick_length - label_gap - label_size.x
				else:
					label_x = axis_x + tick_length + label_gap
				_draw_label(label, Vector2(label_x, label_center_y - label_size.y * 0.5))
			return

		# Continuous path.
		if p_ticks == null:
			return

		# Major ticks
		for i in range(p_ticks.major_ticks.size()):
			var t := p_ticks.major_ticks[i]
			var y: float = p_map_fn.call(t)
			draw_line(Vector2(axis_x, y), Vector2(axis_x + tick_dir * tick_length, y), p_axis_color, tick_thickness)

			if p_ticks.should_show_label(i):
				var label: String = p_decorate_fn.call(p_ticks.format_value(t))
				var label_size := _measure_label(label)
				var label_x: float
				if is_left:
					label_x = axis_x - tick_length - label_gap - label_size.x
				else:
					label_x = axis_x + tick_length + label_gap
				_draw_label(label, Vector2(label_x, y - label_size.y * 0.5))

		# Minor ticks
		var minor_tick_length := tick_length * clampf(_xy_style.minor_tick_length_ratio, 0.0, 1.0)
		var minor_tick_thickness := float(_xy_style.x_minor_tick_thickness_px) if is_x_axis else float(_xy_style.y_minor_tick_thickness_px)
		for t in p_ticks.minor_ticks:
			var y: float = p_map_fn.call(t)
			draw_line(Vector2(axis_x, y), Vector2(axis_x + tick_dir * minor_tick_length, y), p_axis_color, minor_tick_thickness)
