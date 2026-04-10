# Dependencies
const AxisDomain := preload("res://addons/tau-plot/plot/xy/xy_domain.gd").AxisDomain
const XYDomain := preload("res://addons/tau-plot/plot/xy/xy_domain.gd").XYDomain
const TickSequence := preload("res://addons/tau-plot/plot/xy/tick_sequence.gd").TickSequence
const TickResolver := preload("res://addons/tau-plot/plot/xy/tick_resolver.gd").TickResolver
const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const Axis = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis


## Resolves XY plot screen-space layout from a domain and a style.
## Computes per-pane plot rectangles, value-to-pixel mappings, and ticks.
## Orientation-independent: works for x axis on any of the four edges.
class XYLayout extends RefCounted:
	## The computed domain that supplies axis ranges, categories, and series
	## assignment. Set at construction. Input.
	var domain: XYDomain = null

	## Visual style (font, tick sizes, padding, colors).
	## Must be set by the caller before calling [method update].
	var style: TauXYStyle = null

	## Per-pane layout outputs computed by [method update].
	class PaneLayout extends RefCounted:
		## The final data-area rectangle for this pane, in pane-container-local
		## pixel coordinates.
		var pane_rect: Rect2 = Rect2()

		## Tick sequences for y axes on this pane, keyed by [enum AxisId].
		## Only populated for y axes that have both a config and series data.
		var y_ticks: Dictionary[AxisId, TickSequence] = {}

		## Zero-based index of this pane within the pane list. Input.
		var pane_index: int = 0

		## True when this pane draws the primary x axis (ticks and labels).
		var draws_x: bool = false

		## True when this pane draws the secondary x axis.
		var draws_secondary_x: bool = false

	## Array of per-pane layout results, one per pane.
	## Rebuilt by [method update].
	var pane_layouts: Array[PaneLayout] = []

	## Tick sequence for the primary x axis, or null when the axis is
	## categorical or absent. Shared across all panes (the x domain is global).
	## Rebuilt by [method update].
	var x_ticks: TickSequence = null

	## Tick sequence for the secondary x axis, or null.
	## Rebuilt by [method update].
	var secondary_x_ticks: TickSequence = null

	## Indices of visible category labels for the primary x axis.
	## Empty means all are visible. Rebuilt by [method update].
	var x_categorical_visible: PackedInt32Array = PackedInt32Array()

	## Indices of visible category labels for the secondary x axis.
	## Empty means all are visible. Rebuilt by [method update].
	var secondary_x_categorical_visible: PackedInt32Array = PackedInt32Array()

	## Resolved domain bounds for the secondary x axis, derived from the
	## primary x domain via [member TauXYConfig.secondary_x_axis_transform].
	## When [member TauAxisConfig.range_override_enabled] is set on the secondary
	## config, these hold the overridden range instead.
	## Only meaningful when [member TauXYConfig.secondary_x_axis] is not null.
	var _secondary_x_domain_min: float = 0.0
	var _secondary_x_domain_max: float = 1.0

	## Per-pane view rectangles (the full container area before insets).
	## Set via [method set_pane_view_rects] before calling [method update].
	## Each rect has origin (0,0) and the size of the pane container.
	var _pane_view_rects: Array[Rect2] = []

	## Per-pane positions in PaneStack-local coordinates.
	## Set via [method set_pane_positions_in_stack] before calling [method update].
	## Used to compute [member data_area_union].
	var _pane_positions_in_stack: Array[Vector2] = []

	## The union of all per-pane data area rects, in PaneStack-local coordinates.
	## Rebuilt by [method update].
	var data_area_union: Rect2 = Rect2()

	## True when the x axis is on a horizontal edge (BOTTOM or TOP).
	## False when the x axis is on a vertical edge (LEFT or RIGHT).
	## Set at the beginning of [method update] and used by mapping and
	## measurement functions to pick the correct screen dimension.
	## Rebuilt by [method update].
	var _x_is_horizontal: bool = true


	## Creates a new layout bound to the given domain.
	## [param p_domain] The domain that supplies axis ranges and series info.
	func _init(p_domain: XYDomain) -> void:
		domain = p_domain


	## Sets the per-pane view rectangles. Must be called before [method update].
	## [param p_rects] One Rect2 per pane, each with origin (0,0) and the pane
	##   container's pixel size.
	func set_pane_view_rects(p_rects: Array[Rect2]) -> void:
		_pane_view_rects = p_rects


	## Sets the per-pane positions in PaneStack-local coordinates.
	## Must be called before [method update].
	## [param p_positions] One Vector2 per pane, the position of each pane
	##   container within the PaneStack BoxContainer.
	func set_pane_positions_in_stack(p_positions: Array[Vector2]) -> void:
		_pane_positions_in_stack = p_positions


	## Recomputes all pane layouts: axis-to-edge resolution, tick sequences,
	## and pane rectangles. Call after setting [member style] and
	## [method set_pane_view_rects].
	func update() -> void:
		pane_layouts.clear()
		x_ticks = null
		secondary_x_ticks = null
		x_categorical_visible = PackedInt32Array()
		secondary_x_categorical_visible = PackedInt32Array()
		_secondary_x_domain_min = 0.0
		_secondary_x_domain_max = 1.0

		_x_is_horizontal = Axis.is_horizontal(domain.config.x_axis_id)

		if style == null or style.label_font == null:
			for i in range(_pane_view_rects.size()):
				var pl := PaneLayout.new()
				pl.pane_index = i
				pl.pane_rect = _pane_view_rects[i] if i < _pane_view_rects.size() else Rect2()
				pane_layouts.append(pl)
			return

		var pane_count := domain.get_pane_count()
		if pane_count == 0:
			return
		while _pane_view_rects.size() < pane_count:
			_pane_view_rects.append(Rect2())

		# ---- Axis-to-edge resolution ----
		# Determine which edges draw which axis for every pane.

		var draws_bottom: Array[bool] = []
		var draws_top: Array[bool] = []
		var draws_left: Array[bool] = []
		var draws_right: Array[bool] = []

		var x_axis_id := domain.config.x_axis_id
		var secondary_x_position := Axis.get_opposite(x_axis_id)
		var has_x := false
		for i in range(pane_count):
			if domain.series_assignment.get_x_axis_series_count(i) > 0:
				has_x = (domain.config.x_axis != null)
				break
		var has_secondary_x := (domain.config.secondary_x_axis != null)
		var y_axes: Array[AxisId] = Axis.get_orthogonal_axes(x_axis_id)

		for i in range(pane_count):
			var pl := PaneLayout.new()
			pl.pane_index = i
			pane_layouts.append(pl)

			# X axis: drawn on the pane nearest to its edge.
			var pane_draws_x := _is_pane_nearest_to_edge(i, pane_count, x_axis_id) and has_x
			var pane_draws_secondary_x := _is_pane_nearest_to_edge(i, pane_count, secondary_x_position) and has_secondary_x

			# Build per-edge draw flags from x, secondary_x, and y contributions.
			# Each edge starts false and is set true if any axis occupies it.
			var edge_flags := {
				AxisId.BOTTOM: false,
				AxisId.TOP: false,
				AxisId.LEFT: false,
				AxisId.RIGHT: false,
			}

			# X axis occupies x_axis_id edge.
			if pane_draws_x:
				edge_flags[x_axis_id] = true
			# Secondary x axis occupies the opposite edge.
			if pane_draws_secondary_x:
				edge_flags[secondary_x_position] = true

			# Y axes occupy the two positions orthogonal to x.
			for y_axis_id in y_axes:
				var y_axis_domain := domain.get_pane_domain(i).get_y_axis_domain(y_axis_id)
				var has_cfg := (y_axis_domain != null and y_axis_domain.config != null)
				var has_series := domain.series_assignment.get_y_axis_series_count(i, y_axis_id) > 0
				if has_cfg and has_series:
					edge_flags[y_axis_id] = true

			draws_bottom.append(edge_flags[AxisId.BOTTOM])
			draws_top.append(edge_flags[AxisId.TOP])
			draws_left.append(edge_flags[AxisId.LEFT])
			draws_right.append(edge_flags[AxisId.RIGHT])

			pl.draws_x = pane_draws_x
			pl.draws_secondary_x = pane_draws_secondary_x

		# ---- Secondary x domain ----
		# Derive the secondary x axis domain from the primary via the transform,
		# or from the secondary config range override if enabled.
		if has_secondary_x:
			_compute_secondary_x_domain()

		# ---- Tick computation ----

		_compute_x_ticks(has_x, has_secondary_x)

		var per_pane_y_axis_extent_px: Array[float] = []
		for i in range(pane_count):
			per_pane_y_axis_extent_px.append(
				_estimate_available_y_extent(i, draws_bottom, draws_top, draws_left, draws_right))
		_compute_y_ticks(draws_bottom, draws_top, draws_left, draws_right, per_pane_y_axis_extent_px, y_axes)

		_compute_all_pane_rects(draws_bottom, draws_top, draws_left, draws_right, y_axes)


	## Returns true if [param p_pane_index] is the pane closest to [param p_edge].
	## In a vertical stack (x horizontal), TOP is nearest pane 0, BOTTOM is nearest pane N-1.
	## In a horizontal stack (x vertical), LEFT is nearest pane 0, RIGHT is nearest pane N-1.
	static func _is_pane_nearest_to_edge(p_pane_index: int, p_pane_count: int, p_edge: AxisId) -> bool:
		match p_edge:
			AxisId.BOTTOM, AxisId.RIGHT:
				return p_pane_index == p_pane_count - 1
			AxisId.TOP, AxisId.LEFT:
				return p_pane_index == 0
		return false


	## Looks up whether an axis is drawn on the given edge position.
	static func _draws_on_edge(p_edge: AxisId,
			p_draws_bottom: Array[bool], p_draws_top: Array[bool],
			p_draws_left: Array[bool], p_draws_right: Array[bool],
			p_pane_index: int) -> bool:
		match p_edge:
			AxisId.BOTTOM: return p_draws_bottom[p_pane_index]
			AxisId.TOP:    return p_draws_top[p_pane_index]
			AxisId.LEFT:   return p_draws_left[p_pane_index]
			AxisId.RIGHT:  return p_draws_right[p_pane_index]
		return false


	## Returns the PaneLayout for the given pane index.
	## [param p_pane_index] Zero-based pane index.
	func get_pane_layout(p_pane_index: int) -> PaneLayout:
		return pane_layouts[p_pane_index]


	## Returns the pane data-area rectangle in pane-container-local pixels.
	## [param p_pane_index] Zero-based pane index. Returns empty Rect2 if out of range.
	func get_pane_rect(p_pane_index: int = 0) -> Rect2:
		if p_pane_index < 0 or p_pane_index >= pane_layouts.size():
			return Rect2()
		return pane_layouts[p_pane_index].pane_rect

	################################################################################################
	# Axis mapping
	################################################################################################

	## Maps an x-axis data value to a pixel coordinate along the x axis direction.
	## Returns a screen-X pixel when x is horizontal, or screen-Y when x is vertical.
	## [param p_pane_index] Zero-based pane index.
	## [param p_x] Data value on the x axis.
	func map_x_to_px(p_pane_index: int, p_x: float) -> float:
		if p_pane_index < 0 or p_pane_index >= pane_layouts.size():
			return 0.0
		var pane_layout := pane_layouts[p_pane_index]
		var x_axis_cfg := domain.config.x_axis
		if x_axis_cfg == null:
			return pane_layout.pane_rect.position.x

		# x horizontal: origin and extent are along screen-X.
		# x vertical: origin and extent are along screen-Y.
		var origin: float = pane_layout.pane_rect.position.x if _x_is_horizontal else pane_layout.pane_rect.position.y
		var extent: float = pane_layout.pane_rect.size.x if _x_is_horizontal else pane_layout.pane_rect.size.y

		var domain_x_min := domain.x_axis_domain.min_val
		var domain_x_max := domain.x_axis_domain.max_val
		if domain_x_min >= domain_x_max or extent <= 0.0:
			return origin

		# Notes:
		# - screen-X increases rightward
		# - screen-Y increases downward
		# As a consequence, when the x axis is vertical an inversion is required to get x min at
		# the bottom and x max at the top.
		# The user-facing "inverted" flag flips the direction on top of the
		# orientation-based default (XOR logic).
		var flip: bool = (not _x_is_horizontal) != x_axis_cfg.inverted
		match x_axis_cfg.scale:
			TauAxisConfig.Scale.LOGARITHMIC:
				return _map_log_value_to_px(p_x, domain_x_min, domain_x_max, origin, extent, flip)
			TauAxisConfig.Scale.LINEAR:
				var t := (p_x - domain_x_min) / (domain_x_max - domain_x_min)
				if flip:
					t = 1.0 - t
				return origin + t * extent
			_:
				push_error("Unexpected scale %d" % x_axis_cfg.scale)
				return origin


	## Maps a secondary x-axis data value to a pixel coordinate along the x
	## axis direction. The secondary axis shares the same pane rectangle and
	## screen orientation as the primary but uses its own domain bounds and
	## scale (from [member TauXYConfig.secondary_x_axis]).
	## [param p_pane_index] Zero-based pane index.
	## [param p_x] Data value in the secondary x axis domain.
	func map_secondary_x_to_px(p_pane_index: int, p_x: float) -> float:
		if p_pane_index < 0 or p_pane_index >= pane_layouts.size():
			return 0.0
		var pane_layout := pane_layouts[p_pane_index]
		var secondary_cfg := domain.config.secondary_x_axis
		if secondary_cfg == null:
			return pane_layout.pane_rect.position.x

		var origin: float = pane_layout.pane_rect.position.x if _x_is_horizontal else pane_layout.pane_rect.position.y
		var extent: float = pane_layout.pane_rect.size.x if _x_is_horizontal else pane_layout.pane_rect.size.y

		if _secondary_x_domain_min >= _secondary_x_domain_max or extent <= 0.0:
			return origin

		match secondary_cfg.scale:
			TauAxisConfig.Scale.LOGARITHMIC:
				return _map_log_value_to_px(p_x, _secondary_x_domain_min, _secondary_x_domain_max, origin, extent, not _x_is_horizontal)
			TauAxisConfig.Scale.LINEAR:
				var t := (p_x - _secondary_x_domain_min) / (_secondary_x_domain_max - _secondary_x_domain_min)
				if not _x_is_horizontal:
					t = 1.0 - t
				return origin + t * extent
			_:
				push_error("Unexpected scale %d" % secondary_cfg.scale)
				return origin


	## Maps a categorical x-axis index to the pixel coordinate at the center of
	## its slot along the x axis direction.
	## [param p_pane_index] Zero-based pane index.
	## [param p_category_index] Zero-based category index.
	func map_x_category_center_to_px(p_pane_index: int, p_category_index: int) -> float:
		if p_pane_index < 0 or p_pane_index >= pane_layouts.size():
			return 0.0
		var pane_layout := pane_layouts[p_pane_index]
		# x horizontal: categories span screen-X. x vertical: categories span screen-Y.
		var origin: float = pane_layout.pane_rect.position.x if _x_is_horizontal else pane_layout.pane_rect.position.y
		var extent: float = pane_layout.pane_rect.size.x if _x_is_horizontal else pane_layout.pane_rect.size.y
		var nb_categories := domain.x_categories.size()
		if nb_categories <= 0 or extent <= 0.0:
			return origin
		var step_px := extent / float(nb_categories)
		var center := origin + (float(p_category_index) + 0.5) * step_px
		var x_axis_cfg := domain.config.x_axis
		var flip: bool = (not _x_is_horizontal) != (x_axis_cfg != null and x_axis_cfg.inverted)
		if flip:
			center = origin + extent - (center - origin)
		return center


	## Maps a y-axis data value to a pixel coordinate along the y axis direction.
	## Returns a screen-Y pixel when x is horizontal, or screen-X when x is vertical.
	## [param p_pane_index] Zero-based pane index.
	## [param p_value] Data value on the y axis.
	## [param p_y_axis_id] Which y axis (one of the two orthogonal positions).
	func map_y_to_px(p_pane_index: int, p_value: float, p_y_axis_id: AxisId) -> float:
		if p_pane_index < 0 or p_pane_index >= pane_layouts.size():
			return 0.0
		var pane_layout := pane_layouts[p_pane_index]

		var y_axis_domain := _get_y_axis_domain(p_pane_index, p_y_axis_id)
		if y_axis_domain == null:
			push_error("map_y_to_px(): no y axis domain for axis_id %d" % p_y_axis_id)
			return 0.0

		# x horizontal: y axis runs along screen-Y. x vertical: y axis runs along screen-X.
		var origin: float = pane_layout.pane_rect.position.y if _x_is_horizontal else pane_layout.pane_rect.position.x
		var extent: float = pane_layout.pane_rect.size.y if _x_is_horizontal else pane_layout.pane_rect.size.x
		# x horizontal: y is vertical, so invert (higher values = lower screen-Y = up).
		# x vertical: y is horizontal, values increase with screen-X, no inversion.
		# The user-facing "inverted" flag flips the direction on top of the
		# orientation-based default (XOR logic).
		var y_cfg := y_axis_domain.config
		var flip: bool = _x_is_horizontal != (y_cfg != null and y_cfg.inverted)
		return _map_y_value(p_value, y_axis_domain.min_val, y_axis_domain.max_val, y_axis_domain.scale, origin, extent, flip)


	## Returns the pixel coordinate of y=0 on the given y axis.
	## [param p_pane_index] Zero-based pane index.
	## [param p_y_axis_id] Which y axis.
	func get_y_zero_px(p_pane_index: int, p_y_axis_id: AxisId) -> float:
		return map_y_to_px(p_pane_index, 0.0, p_y_axis_id)


	################################################################################################
	# Categorical label visibility
	################################################################################################

	## Returns true if the category label at [param p_category_index] should be
	## shown for the primary x axis on pane [param p_pane_index].
	func should_show_x_categorical_label(_p_pane_index: int, p_category_index: int) -> bool:
		if x_categorical_visible.is_empty():
			return true
		for idx in x_categorical_visible:
			if idx == p_category_index:
				return true
		return false


	## Returns true if the category label at [param p_category_index] should be
	## shown for the secondary x axis on pane [param p_pane_index].
	func should_show_secondary_x_categorical_label(_p_pane_index: int, p_category_index: int) -> bool:
		if secondary_x_categorical_visible.is_empty():
			return true
		for idx in secondary_x_categorical_visible:
			if idx == p_category_index:
				return true
		return false


	################################################################################################
	# Private
	################################################################################################

	## Returns the AxisDomain for a y axis on a given pane, or null.
	func _get_y_axis_domain(p_pane_index: int, p_y_axis_id: AxisId) -> AxisDomain:
		if p_pane_index < 0 or p_pane_index >= domain.get_pane_count():
			return null
		var pane_y_domains := domain.get_pane_domain(p_pane_index)
		return pane_y_domains.get_y_axis_domain(p_y_axis_id)


	## Returns the TauAxisConfig for a y axis on a given pane, or null.
	func _get_y_axis_config(p_pane_index: int, p_y_axis_id: AxisId) -> TauAxisConfig:
		var y_axis_domain := _get_y_axis_domain(p_pane_index, p_y_axis_id)
		if y_axis_domain == null:
			return null
		return y_axis_domain.config


	## Maps a y data value to a pixel coordinate using linear or log scale.
	## [param p_value] Data value.
	## [param p_min] Domain minimum.
	## [param p_max] Domain maximum.
	## [param p_scale] LINEAR or LOGARITHMIC.
	## [param p_origin] Pixel coordinate of the axis start (top or left of pane rect).
	## [param p_extent] Pixel length of the axis in screen space.
	## [param p_invert] If true, higher data values map to lower pixel coordinates
	##   (used when y is vertical, because screen-Y increases downward).
	##   If false, higher data values map to higher pixel coordinates
	##   (used when y is horizontal, because screen-X increases rightward).
	func _map_y_value(p_value: float, p_min: float, p_max: float, p_scale: TauAxisConfig.Scale, p_origin: float, p_extent: float, p_invert: bool) -> float:
		if p_min >= p_max or p_extent <= 0.0:
			return p_origin + p_extent if p_invert else p_origin
		match p_scale:
			TauAxisConfig.Scale.LOGARITHMIC:
				return _map_log_value_to_px(p_value, p_min, p_max, p_origin, p_extent, p_invert)
			TauAxisConfig.Scale.LINEAR:
				var t := (p_value - p_min) / (p_max - p_min)
				if p_invert:
					return p_origin + (1.0 - t) * p_extent
				else:
					return p_origin + t * p_extent
			_:
				push_error("Unexpected scale %d" % p_scale)
				return p_origin + p_extent if p_invert else p_origin


	## Maps a data value to a pixel coordinate using a base-10 logarithmic scale.
	## [param p_invert] If true, higher values map to lower pixel coordinates.
	func _map_log_value_to_px(p_value: float, p_min: float, p_max: float, p_pane_start: float, p_pane_size: float, p_invert: bool) -> float:
		if p_value <= 0.0 or p_min <= 0.0 or p_max <= 0.0:
			push_error("Logarithmic mapping requires strictly positive values (value=%f, min=%f, max=%f)" % [p_value, p_min, p_max])
			return (p_pane_start + p_pane_size) if p_invert else p_pane_start

		if p_min >= p_max or p_pane_size <= 0.0:
			return (p_pane_start + p_pane_size) if p_invert else p_pane_start

		const LOG_10 := log(10.0)
		var log_value := log(p_value) / LOG_10
		var log_min := log(p_min) / LOG_10
		var log_max := log(p_max) / LOG_10
		var t := (log_value - log_min) / (log_max - log_min)
		if p_invert:
			return p_pane_start + (1.0 - t) * p_pane_size
		else:
			return p_pane_start + t * p_pane_size


	## Returns the pixel size (width, height) of a label string using the current style font.
	func _measure_label(p_label: String) -> Vector2:
		return style.label_font.get_string_size(p_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, style.label_font_size)


	## Applies the primary x axis format_tick_label callback to a label string.
	func _decorate_x_label(p_text: String) -> String:
		var x_axis_cfg := domain.config.x_axis
		if x_axis_cfg == null or x_axis_cfg.format_tick_label.is_null():
			return p_text
		return x_axis_cfg.format_tick_label.call(p_text)


	## Applies the secondary x axis format_tick_label callback to a label string.
	func _decorate_secondary_x_label(p_text: String) -> String:
		var secondary_x_axis_cfg := domain.config.secondary_x_axis
		if secondary_x_axis_cfg == null or secondary_x_axis_cfg.format_tick_label.is_null():
			return p_text
		return secondary_x_axis_cfg.format_tick_label.call(p_text)


	## Applies the y axis format_tick_label callback to a label string.
	func _decorate_y_label(p_text: String, p_pane_index: int, p_y_axis_id: AxisId) -> String:
		var y_axis_config := _get_y_axis_config(p_pane_index, p_y_axis_id)
		if y_axis_config == null or y_axis_config.format_tick_label.is_null():
			return p_text
		return y_axis_config.format_tick_label.call(p_text)


	## Derives the secondary x domain from the primary domain.
	## If the secondary config has [member TauAxisConfig.range_override_enabled],
	## those bounds are used directly. Otherwise the primary domain endpoints
	## are transformed via [member TauXYConfig.secondary_x_axis_transform].
	func _compute_secondary_x_domain() -> void:
		var secondary_cfg := domain.config.secondary_x_axis
		if secondary_cfg == null:
			return

		if secondary_cfg.range_override_enabled:
			_secondary_x_domain_min = secondary_cfg.min_override
			_secondary_x_domain_max = secondary_cfg.max_override
			return

		var transform_fn := domain.config.secondary_x_axis_transform
		if transform_fn.is_null():
			# Validator should have caught this. Fall back to primary domain.
			_secondary_x_domain_min = domain.x_axis_domain.min_val
			_secondary_x_domain_max = domain.x_axis_domain.max_val
			return

		var primary_min := domain.x_axis_domain.min_val
		var primary_max := domain.x_axis_domain.max_val
		var sec_a: float = transform_fn.call(primary_min)
		var sec_b: float = transform_fn.call(primary_max)
		# The transform may flip the direction (e.g. 1/x), so use min/max.
		_secondary_x_domain_min = minf(sec_a, sec_b)
		_secondary_x_domain_max = maxf(sec_a, sec_b)


	## Computes x axis tick sequences once.
	## The x domain is shared across all panes and the pixel extent along x
	## is identical for every pane, so one computation is sufficient.
	## Stores results in [member x_ticks], [member secondary_x_ticks],
	## [member x_categorical_visible], and [member secondary_x_categorical_visible].
	func _compute_x_ticks(p_has_x: bool, p_has_secondary_x: bool) -> void:
		if _pane_view_rects.is_empty():
			return
		# All panes share the same extent along x, so any view rect works.
		var view_rect := _pane_view_rects[0]
		if p_has_x:
			_compute_x_ticks_once(true, view_rect)
		if p_has_secondary_x:
			_compute_x_ticks_once(false, view_rect)


	## Computes y axis tick sequences for all panes and y axis positions.
	## [param p_available_y] Per-pane available screen pixels along the y axis direction.
	## [param p_y_axes] The two AxisId positions orthogonal to x.
	func _compute_y_ticks(p_draws_bottom: Array[bool], p_draws_top: Array[bool],
			p_draws_left: Array[bool], p_draws_right: Array[bool],
			p_available_y: Array[float], p_y_axes: Array[AxisId]) -> void:
		var pane_count := pane_layouts.size()

		for pane_index in range(pane_count):
			var pane_layout := pane_layouts[pane_index]
			var available_y := p_available_y[pane_index]
			if available_y <= 0.0:
				continue
			for y_axis_id in p_y_axes:
				var draws := _draws_on_edge(y_axis_id,
					p_draws_bottom, p_draws_top, p_draws_left, p_draws_right, pane_index)
				if not draws:
					continue

				var y_axis_domain := _get_y_axis_domain(pane_index, y_axis_id)
				if y_axis_domain == null:
					continue
				var y_axis_config := y_axis_domain.config
				if y_axis_config == null:
					continue

				# The TickResolver runs overlap detection along the y axis screen
				# direction. It needs the label extent along that direction as the
				# .x component of the returned Vector2.
				#
				# x horizontal: y axis is vertical (screen-Y). The label extent
				#   along screen-Y is the text height (s.y), so swap to (s.y, s.x).
				# x vertical: y axis is horizontal (screen-X). The label extent
				#   along screen-X is the text width (s.x), so no swap needed.
				var y_measure_func: Callable
				if _x_is_horizontal:
					y_measure_func = func(label: String) -> Vector2:
						var s := _measure_label(_decorate_y_label(label, pane_index, y_axis_id))
						return Vector2(s.y, s.x)
				else:
					y_measure_func = func(label: String) -> Vector2:
						return _measure_label(_decorate_y_label(label, pane_index, y_axis_id))
				var ticks := TickResolver.compute_ticks_for_continuous_axis(
					y_axis_domain.min_val, y_axis_domain.max_val,
					y_axis_config.scale, y_axis_config.tick_count_preferred, y_axis_config.overlap_strategy,
					available_y, float(y_axis_config.min_label_spacing_px), y_measure_func)
				pane_layout.y_ticks[y_axis_id] = ticks


	## Returns the number of screen pixels available for the y axis extent.
	## This is the pane view rect dimension along the y axis direction, minus
	## the space consumed by x-axis ticks and labels on the perpendicular edges.
	func _estimate_available_y_extent(p_pane_index: int,
			p_draws_bottom: Array[bool], p_draws_top: Array[bool],
			p_draws_left: Array[bool], p_draws_right: Array[bool]) -> float:
		var view_rect := _pane_view_rects[p_pane_index]
		var x_axis_id := domain.config.x_axis_id
		var secondary_x_position := Axis.get_opposite(x_axis_id)

		# The x axis and its secondary sit on edges that are perpendicular to
		# the y axis direction. We need to subtract the space those edges
		# reserve for labels from the total y axis extent.
		var draws_x_edge := _draws_on_edge(x_axis_id,
			p_draws_bottom, p_draws_top, p_draws_left, p_draws_right, p_pane_index)
		var draws_secondary_x_edge := _draws_on_edge(secondary_x_position,
			p_draws_bottom, p_draws_top, p_draws_left, p_draws_right, p_pane_index)

		var x_edge_reserved := 0.0
		var secondary_x_edge_reserved := 0.0
		if draws_x_edge:
			x_edge_reserved = _measure_x_axis_labels(true).x
		if draws_secondary_x_edge:
			secondary_x_edge_reserved = _measure_x_axis_labels(false).x

		# Estimate the half-height of a y-axis label to account for endpoint
		# overshoot into the x-axis reserved space.
		var label_size := _measure_label("0")
		# x horizontal: y axis is vertical, overshoot is half the label height.
		# x vertical: y axis is horizontal, overshoot is half the label width.
		var y_edge_half_extent := (label_size.y if _x_is_horizontal else label_size.x) * 0.5

		# x horizontal: y axis runs along screen-Y, so available extent is the view height.
		# x vertical: y axis runs along screen-X, so available extent is the view width.
		var extent := view_rect.size.y if _x_is_horizontal else view_rect.size.x

		# The x axis edge and secondary x axis edge consume space on two
		# opposing sides along the y axis direction. Determine which padding
		# sides correspond to which x-axis edges.
		#
		# x horizontal: x axis is on BOTTOM or TOP.
		#   x_edge is on the same side as x_axis_id (e.g. BOTTOM),
		#   secondary is on the opposite side (e.g. TOP).
		#   padding_start = padding along x_axis_id direction.
		#   padding_end = padding along secondary direction.
		#
		# x vertical: x axis is on LEFT or RIGHT.
		#   Same logic, but using left/right padding instead of top/bottom.
		var padding_toward_x: float
		var padding_toward_secondary_x: float
		match x_axis_id:
			AxisId.BOTTOM:
				padding_toward_x = float(style.padding_bottom_px)
				padding_toward_secondary_x = float(style.padding_top_px)
			AxisId.TOP:
				padding_toward_x = float(style.padding_top_px)
				padding_toward_secondary_x = float(style.padding_bottom_px)
			AxisId.LEFT:
				padding_toward_x = float(style.padding_left_px)
				padding_toward_secondary_x = float(style.padding_right_px)
			AxisId.RIGHT:
				padding_toward_x = float(style.padding_right_px)
				padding_toward_secondary_x = float(style.padding_left_px)
			_:
				padding_toward_x = 0.0
				padding_toward_secondary_x = 0.0

		extent -= x_edge_reserved + secondary_x_edge_reserved + padding_toward_x + padding_toward_secondary_x
		var extra_toward_x := maxf(y_edge_half_extent - x_edge_reserved - padding_toward_x, 0.0)
		var extra_toward_secondary_x := maxf(y_edge_half_extent - secondary_x_edge_reserved - padding_toward_secondary_x, 0.0)
		extent -= extra_toward_x + extra_toward_secondary_x
		return maxf(extent, 0.0)


	## Computes the tick sequence or categorical visibility for a primary or
	## secondary x axis. Results are stored on this XYLayout instance.
	## [param p_is_primary_x] True for the primary x axis, false for secondary.
	## [param p_view_rect] A pane view rect (used to determine the available pixel extent).
	func _compute_x_ticks_once(p_is_primary_x: bool, p_view_rect: Rect2) -> void:
		var x_axis_cfg: TauAxisConfig
		var categories: PackedStringArray
		var x_min: float
		var x_max: float
		if p_is_primary_x:
			x_axis_cfg = domain.config.x_axis
			categories = domain.x_categories
			x_min = domain.x_axis_domain.min_val
			x_max = domain.x_axis_domain.max_val
		else:
			x_axis_cfg = domain.config.secondary_x_axis
			categories = PackedStringArray()  # Secondary is always continuous.
			x_min = _secondary_x_domain_min
			x_max = _secondary_x_domain_max
		var decorate_fn: Callable
		if p_is_primary_x:
			decorate_fn = func(text: String) -> String: return _decorate_x_label(text)
		else:
			decorate_fn = func(text: String) -> String: return _decorate_secondary_x_label(text)
		# x horizontal: available extent is view rect width. x vertical: height.
		var x_axis_extent_px := p_view_rect.size.x if _x_is_horizontal else p_view_rect.size.y

		match x_axis_cfg.type:
			TauAxisConfig.Type.CATEGORICAL:
				var vis := TickResolver.compute_categorical_label_visibility(
					categories, x_axis_cfg.overlap_strategy, x_axis_extent_px,
					float(x_axis_cfg.min_label_spacing_px),
					func(label: String) -> Vector2: return _measure_label(decorate_fn.call(label))
				)
				if p_is_primary_x:
					x_categorical_visible = vis
				else:
					secondary_x_categorical_visible = vis
			TauAxisConfig.Type.CONTINUOUS:
				var ticks := TickResolver.compute_ticks_for_continuous_axis(
					x_min, x_max, x_axis_cfg.scale, x_axis_cfg.tick_count_preferred,
					x_axis_cfg.overlap_strategy, x_axis_extent_px,
					float(x_axis_cfg.min_label_spacing_px),
					func(label: String) -> Vector2: return _measure_label(decorate_fn.call(label))
				)
				if p_is_primary_x:
					x_ticks = ticks
				else:
					secondary_x_ticks = ticks


	## Computes the pane_rect for every pane by measuring label/tick space on
	## each of the four physical edges and shrinking the view rect inward.
	##
	## For each edge, the function determines what axis occupies it (x,
	## secondary x, y, or nothing) and measures the reserved perpendicular
	## depth. Endpoint overshoot (half_extent) from one axis pair can push
	## into the reserved space of the perpendicular pair.
	##
	## Edges parallel to the stacking direction are aligned across panes
	## (maximum reserved depth). Edges perpendicular to stacking are per-pane.
	## x horizontal (vertical stacking): LEFT and RIGHT are aligned.
	## x vertical (horizontal stacking): TOP and BOTTOM are aligned.
	func _compute_all_pane_rects(p_draws_bottom: Array[bool], p_draws_top: Array[bool],
			p_draws_left: Array[bool], p_draws_right: Array[bool],
			p_y_axes: Array[AxisId]) -> void:
		var pane_count := pane_layouts.size()
		var x_axis_id := domain.config.x_axis_id
		var secondary_x_position := Axis.get_opposite(x_axis_id)

		# Per-pane reserved depth for each physical edge and half_extent per axis pair.
		var per_pane_left_reserved: Array[float] = []
		var per_pane_right_reserved: Array[float] = []
		var per_pane_bottom_reserved: Array[float] = []
		var per_pane_top_reserved: Array[float] = []
		# x axis half_extent overshoots into the two y-axis edges.
		var per_pane_x_half_extent: Array[float] = []
		# y axis half_extent overshoots into the two x-axis edges.
		var per_pane_y_half_extent: Array[float] = []

		for i in range(pane_count):
			var pane_layout := pane_layouts[i]

			# Measure each edge based on what axis occupies it.
			# Use a dictionary to accumulate reserved depth per edge.
			var reserved := {
				AxisId.LEFT: 0.0,
				AxisId.RIGHT: 0.0,
				AxisId.BOTTOM: 0.0,
				AxisId.TOP: 0.0,
			}
			var x_half_extent := 0.0
			var y_half_extent := 0.0

			# Process x axis edge.
			var x_edge_draws := _draws_on_edge(x_axis_id,
				p_draws_bottom, p_draws_top, p_draws_left, p_draws_right, i)
			if x_edge_draws:
				var result := _measure_x_axis_labels(true)
				reserved[x_axis_id] = result.x
				x_half_extent = max(x_half_extent, result.y)

			# Process secondary x axis edge.
			var secondary_x_edge_draws := _draws_on_edge(secondary_x_position,
				p_draws_bottom, p_draws_top, p_draws_left, p_draws_right, i)
			if secondary_x_edge_draws:
				var result := _measure_x_axis_labels(false)
				reserved[secondary_x_position] = result.x
				x_half_extent = max(x_half_extent, result.y)

			# Process y axis edges.
			for y_axis_id in p_y_axes:
				var y_draws := _draws_on_edge(y_axis_id,
					p_draws_bottom, p_draws_top, p_draws_left, p_draws_right, i)
				if not y_draws or y_axis_id not in pane_layout.y_ticks:
					continue
				var y_ticks: TickSequence = pane_layout.y_ticks[y_axis_id]
				var y_axis_domain := domain.get_pane_domain(i).get_y_axis_domain(y_axis_id)
				if y_axis_domain == null:
					continue
				var result := _measure_y_axis_labels(y_ticks, y_axis_domain.min_val, y_axis_domain.max_val, i, y_axis_id)
				reserved[y_axis_id] = result.x
				y_half_extent = max(y_half_extent, result.y)

			per_pane_left_reserved.append(reserved[AxisId.LEFT])
			per_pane_right_reserved.append(reserved[AxisId.RIGHT])
			per_pane_bottom_reserved.append(reserved[AxisId.BOTTOM])
			per_pane_top_reserved.append(reserved[AxisId.TOP])
			per_pane_x_half_extent.append(x_half_extent)
			per_pane_y_half_extent.append(y_half_extent)

		# Aligned edges: take max across all panes for edges parallel to stacking.
		# x horizontal (vertical stacking): LEFT and RIGHT are aligned.
		# x vertical (horizontal stacking): TOP and BOTTOM are aligned.
		var aligned_a_reserved := 0.0  # First aligned edge (LEFT or TOP).
		var aligned_b_reserved := 0.0  # Second aligned edge (RIGHT or BOTTOM).
		# x_half_extent overshoots into y-axis edges. When y is on LEFT/RIGHT
		# (x horizontal), x_half_extent is aligned. When y is on BOTTOM/TOP
		# (x vertical), x_half_extent is aligned.
		var max_x_half_extent := 0.0
		for i in range(pane_count):
			max_x_half_extent = max(max_x_half_extent, per_pane_x_half_extent[i])
			if _x_is_horizontal:
				aligned_a_reserved = max(aligned_a_reserved, per_pane_left_reserved[i])
				aligned_b_reserved = max(aligned_b_reserved, per_pane_right_reserved[i])
			else:
				aligned_a_reserved = max(aligned_a_reserved, per_pane_top_reserved[i])
				aligned_b_reserved = max(aligned_b_reserved, per_pane_bottom_reserved[i])

		for i in range(pane_count):
			var full := _pane_view_rects[i]

			# Resolve final reserved depth per edge. Aligned edges use the max.
			var left_r: float
			var right_r: float
			var top_r: float
			var bottom_r: float
			if _x_is_horizontal:
				left_r = aligned_a_reserved
				right_r = aligned_b_reserved
				top_r = per_pane_top_reserved[i]
				bottom_r = per_pane_bottom_reserved[i]
			else:
				left_r = per_pane_left_reserved[i]
				right_r = per_pane_right_reserved[i]
				top_r = aligned_a_reserved
				bottom_r = aligned_b_reserved

			# Start with the pane shrunk inward from all four sides.
			var pane_pos := full.position + Vector2(
				left_r + float(style.padding_left_px),
				top_r + float(style.padding_top_px))
			var pane_size := full.size - Vector2(
				left_r + right_r + float(style.padding_left_px + style.padding_right_px),
				top_r + bottom_r + float(style.padding_top_px + style.padding_bottom_px))

			# Overshoot corrections.
			#
			# x_half_extent overshoots into the two y-axis edges (perpendicular to x).
			# x horizontal: x_half_extent is horizontal, overshoots into LEFT and RIGHT.
			# x vertical: x_half_extent is vertical, overshoots into TOP and BOTTOM.
			#
			# y_half_extent overshoots into the two x-axis edges (perpendicular to y).
			# x horizontal: y_half_extent is vertical, overshoots into TOP and BOTTOM.
			# x vertical: y_half_extent is horizontal, overshoots into LEFT and RIGHT.
			var y_half := per_pane_y_half_extent[i]

			if _x_is_horizontal:
				# x_half_extent overshoots horizontally into LEFT and RIGHT.
				var extra_left := maxf(max_x_half_extent - left_r - float(style.padding_left_px), 0.0)
				var extra_right := maxf(max_x_half_extent - right_r - float(style.padding_right_px), 0.0)
				pane_pos.x += extra_left
				pane_size.x -= extra_left + extra_right
				# y_half_extent overshoots vertically into TOP and BOTTOM.
				var extra_top := maxf(y_half - top_r - float(style.padding_top_px), 0.0)
				var extra_bottom := maxf(y_half - bottom_r - float(style.padding_bottom_px), 0.0)
				pane_pos.y += extra_top
				pane_size.y -= extra_top + extra_bottom
			else:
				# x_half_extent overshoots vertically into TOP and BOTTOM.
				var extra_top := maxf(max_x_half_extent - top_r - float(style.padding_top_px), 0.0)
				var extra_bottom := maxf(max_x_half_extent - bottom_r - float(style.padding_bottom_px), 0.0)
				pane_pos.y += extra_top
				pane_size.y -= extra_top + extra_bottom
				# y_half_extent overshoots horizontally into LEFT and RIGHT.
				var extra_left := maxf(y_half - left_r - float(style.padding_left_px), 0.0)
				var extra_right := maxf(y_half - right_r - float(style.padding_right_px), 0.0)
				pane_pos.x += extra_left
				pane_size.x -= extra_left + extra_right

			pane_size.x = max(pane_size.x, 0.0)
			pane_size.y = max(pane_size.y, 0.0)
			pane_layouts[i].pane_rect = Rect2(pane_pos, pane_size)

		# Compute union of all pane data areas in PaneStack-local coordinates.
		if pane_count > 0 and _pane_positions_in_stack.size() >= pane_count:
			var first_rect := pane_layouts[0].pane_rect
			var first_offset := _pane_positions_in_stack[0]
			data_area_union = Rect2(first_offset + first_rect.position, first_rect.size)
			for i in range(1, pane_count):
				var pr := pane_layouts[i].pane_rect
				var offset := _pane_positions_in_stack[i]
				data_area_union = data_area_union.merge(
					Rect2(offset + pr.position, pr.size))
		else:
			data_area_union = Rect2()


	## Measures y-axis labels and returns Vector2(reserved_depth, half_extent).
	## reserved_depth: space consumed perpendicular to the y axis direction
	##   (label extent across the edge + tick gap + tick perpendicular size).
	## half_extent: half of the label extent along the y axis direction at
	##   endpoints, used for overshoot correction.
	func _measure_y_axis_labels(p_ticks: TickSequence, p_min: float, p_max: float, p_pane_index: int, p_y_axis_id: AxisId) -> Vector2:
		var max_w := 0.0
		var max_h := 0.0
		if p_ticks.major_ticks.is_empty():
			var label_min := _decorate_y_label(String.num(p_min), p_pane_index, p_y_axis_id)
			var label_max := _decorate_y_label(String.num(p_max), p_pane_index, p_y_axis_id)
			var size_min := _measure_label(label_min)
			var size_max := _measure_label(label_max)
			max_w = max(size_min.x, size_max.x)
			max_h = max(size_min.y, size_max.y)
		else:
			for t in p_ticks.major_ticks:
				var label := _decorate_y_label(p_ticks.format_value(t), p_pane_index, p_y_axis_id)
				var lsize := _measure_label(label)
				max_w = max(max_w, lsize.x)
				max_h = max(max_h, lsize.y)

		# x horizontal: y axis is vertical. Labels sit to the left/right of the axis.
		#   reserved_depth = label width + gap + tick width (horizontal space).
		#   half_extent = half of tallest label (vertical overshoot at endpoints).
		# x vertical: y axis is horizontal. Labels sit above/below the axis.
		#   reserved_depth = label height + gap + tick height (vertical space).
		#   half_extent = half of widest label (horizontal overshoot at endpoints).
		var label_depth: float
		var tick_depth: float
		var half_extent: float
		if _x_is_horizontal:
			label_depth = max_w
			tick_depth = float(style.y_major_tick_length_px)
			half_extent = max_h * 0.5
		else:
			label_depth = max_h
			tick_depth = float(style.y_major_tick_length_px)
			half_extent = max_w * 0.5

		var reserved := label_depth + float(style.y_tick_y_label_gap_px) + tick_depth if label_depth > 0.0 else 0.0
		return Vector2(reserved, half_extent)


	## Measures x-axis labels and returns Vector2(reserved_depth, half_extent).
	## reserved_depth: space consumed perpendicular to the x axis direction
	##   (label extent across the edge + tick gap + tick perpendicular size).
	## half_extent: overshoot at axis endpoints along the x axis direction
	##   (half of the widest/tallest endpoint label, depending on orientation).
	func _measure_x_axis_labels(p_is_primary_x: bool) -> Vector2:
		var categories: PackedStringArray = domain.x_categories
		var x_axis_cfg: TauAxisConfig
		var x_min: float
		var x_max: float
		if p_is_primary_x:
			x_axis_cfg = domain.config.x_axis
			x_min = domain.x_axis_domain.min_val
			x_max = domain.x_axis_domain.max_val
		else:
			x_axis_cfg = domain.config.secondary_x_axis
			x_min = _secondary_x_domain_min
			x_max = _secondary_x_domain_max
		if x_axis_cfg == null:
			return Vector2.ZERO
		var ticks: TickSequence = x_ticks if p_is_primary_x else secondary_x_ticks
		var decorate_fn := _decorate_x_label if p_is_primary_x else _decorate_secondary_x_label

		# Collect the maximum label size across both dimensions.
		var max_label_w := 0.0
		var max_label_h := 0.0
		# For continuous axes, track endpoint label sizes for half_extent.
		var first_size := Vector2.ZERO
		var last_size := Vector2.ZERO

		match x_axis_cfg.type:
			TauAxisConfig.Type.CATEGORICAL:
				for raw_label in categories:
					var label: String = decorate_fn.call(raw_label)
					var sz := _measure_label(label)
					max_label_w = max(max_label_w, sz.x)
					max_label_h = max(max_label_h, sz.y)
			TauAxisConfig.Type.CONTINUOUS:
				if x_min >= x_max:
					return Vector2.ZERO
				if ticks == null or ticks.major_ticks.is_empty():
					var label_min: String = decorate_fn.call(String.num(x_min))
					var label_max: String = decorate_fn.call(String.num(x_max))
					var size_min := _measure_label(label_min)
					var size_max := _measure_label(label_max)
					max_label_w = max(size_min.x, size_max.x)
					max_label_h = max(size_min.y, size_max.y)
					first_size = size_min
					last_size = size_max
				else:
					for j in range(ticks.major_ticks.size()):
						var t := ticks.major_ticks[j]
						var label: String = decorate_fn.call(ticks.format_value(t))
						var sz := _measure_label(label)
						max_label_w = max(max_label_w, sz.x)
						max_label_h = max(max_label_h, sz.y)
						if j == 0:
							first_size = sz
						if j == ticks.major_ticks.size() - 1:
							last_size = sz

		# x horizontal: labels sit below/above the axis line.
		#   reserved_depth = label height + gap + tick height (vertical space).
		#   half_extent = half of widest endpoint label (horizontal overshoot).
		# x vertical: labels sit left/right of the axis line.
		#   reserved_depth = label width + gap + tick width (horizontal space).
		#   half_extent = half of tallest endpoint label (vertical overshoot).
		var label_depth: float
		var tick_depth: float
		var endpoint_extent: float
		if _x_is_horizontal:
			label_depth = max_label_h
			tick_depth = float(style.x_major_tick_length_px)
			endpoint_extent = max(first_size.x, last_size.x) * 0.5
		else:
			label_depth = max_label_w
			tick_depth = float(style.x_major_tick_length_px)
			endpoint_extent = max(first_size.y, last_size.y) * 0.5

		var reserved := label_depth + float(style.x_tick_x_label_gap_px) + tick_depth if label_depth > 0.0 else 0.0
		# For categorical axes, endpoint overshoot is zero (labels are centered in slots).
		var half_extent := endpoint_extent if x_axis_cfg.type == TauAxisConfig.Type.CONTINUOUS else 0.0
		return Vector2(reserved, half_extent)
