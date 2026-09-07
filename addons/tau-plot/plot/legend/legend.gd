## Legend
## Displays dataset series names alongside visual keys representing their overlay types.
##
## Key drawing is delegated to plot-type-specific factory callables provided via KeyInfo.
## The Legend itself has no knowledge of any particular plot type.
##
## The legend spans one side of the plot and claims the other one. The given
## side is the one it spans: the width of a legend above or below the plot, the
## height of a legend on its left or right. The claimed side is the other one,
## and it is the only size the legend asks for.
##
## The legend never decides that size alone. The given side and the maximum of
## the claimed side both come from the container, through update_desired_size().
## Inside the data area both come from that area. Names too long are cut with
## an ellipsis, extra entries scroll.
class Legend extends Control:

	## Which side the parent gives the legend, and therefore which side the
	## legend claims and [member TauLegendStyle.max_size_px] caps.
	enum PositionFamily
	{
		TOP_BOTTOM,		# The parent gives the width, the legend claims a height.
		LEFT_RIGHT,		# The parent gives the height, the legend claims a width.
		INSIDE,			# The data area gives both sides, the legend claims its box.
	}

	## Describes one key visual in a LegendItem.
	class KeyInfo extends RefCounted:
		## Factory callable that creates a self-rendering Control for the legend key.
		## Must match the signature:
		##   func(p_series_index: int) -> Control
		## The returned Control must handle its own rendering internally.
		## Each axis of custom_minimum_size set to a positive value by the factory
		## is honored. A height left at zero falls back to key_size_px, a width
		## left at zero to the resolved height times key_aspect_ratio.
		##
		## The resolved box is the size of the picture, not the space the legend
		## reserves for it. A vertically flowing legend pads every box out to the
		## widest one so the series names share a single offset.
		var create_key_control: Callable = Callable()

		## Callable that pushes a new appearance into a Control the factory built.
		## Must match the signature:
		##   func(p_series_index: int, p_control: Control) -> void
		## It repaints the Control itself, and may request a different box size the
		## same way the factory does, under the same per-axis fallback rule.
		var refresh_key_control: Callable = Callable()

		## Width of the key box as a multiple of its height, for a factory that
		## leaves the width at zero. The default keeps the box square.
		##
		## A ratio rather than a pixel width so a key that needs a wide box stays
		## proportional when key_size_px changes.
		var key_aspect_ratio: float = 1.0

	## Describes one series entry in the legend.
	class SeriesInfo extends RefCounted:
		var series_id: int = -1
		var series_index: int = -1
		var series_name: String = ""
		var keys: Array[KeyInfo] = []

	# Minimum size of the claimed side. At 0 a legend with no room left
	# disappears instead of pushing the plot.
	const _LEGEND_FLOOR_PX := 0.0

	# Share of the plot an uncapped legend may take.
	const _MAX_SIZE_FRACTION := 2./3.

	var _style: TauLegendStyle = null
	var _series_infos: Array[SeriesInfo] = []

	var _box: PanelContainer = null
	var _scroll: ScrollContainer = null
	var _flow: FlowContainer = null
	var _legend_items: Array[Control] = []
	var _align_key_columns: bool = false

	var _family: PositionFamily = PositionFamily.TOP_BOTTOM
	var _data_area: Vector2 = Vector2.ZERO

	# Size the last measurement settled on the box, and what the legend claims
	# from its parent.
	var _box_size: Vector2 = Vector2.ZERO


	func _init() -> void:
		theme_type_variation = &"TauLegend"

		# A box that ends up larger than its slot is cut here rather than
		# painted over the plot.
		clip_contents = true

		# The legend spans the side its parent gives it, so the box is placed
		# by hand at the middle of that span. All four anchors sit at the
		# center and the offsets carry half the box size, which centers the box
		# on both axes whatever the position.
		_box = PanelContainer.new()
		_box.name = "Box"
		_box.anchor_left = 0.5
		_box.anchor_right = 0.5
		_box.anchor_top = 0.5
		_box.anchor_bottom = 0.5
		add_child(_box)

		# Measurement decides the scroll modes, so both start off.
		_scroll = ScrollContainer.new()
		_scroll.name = "Scroll"
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_box.add_child(_scroll)

		# The box hugs the entries, so a line shorter than the longest one is
		# centered rather than left hanging on one edge.
		_flow = FlowContainer.new()
		_flow.name = "Flow"
		_flow.alignment = FlowContainer.ALIGNMENT_CENTER
		_scroll.add_child(_flow)


	# Zero on the given side, so the legend never raises the minimum size of the
	# plot. Inside the data area no container sizes the legend, so it reports
	# the box size of the last measurement.
	func _get_minimum_size() -> Vector2:
		match _family:
			PositionFamily.TOP_BOTTOM:
				return Vector2(0.0, _LEGEND_FLOOR_PX)
			PositionFamily.LEFT_RIGHT:
				return Vector2(_LEGEND_FLOOR_PX, 0.0)
		return _box_size


	## Populates the legend from the given series information.
	func populate(p_series_infos: Array[SeriesInfo]) -> void:
		_series_infos = p_series_infos
		_rebuild()


	## Forces a full rebuild of all legend items.
	## Call this after a change to the series list itself. A change to what a key
	## draws is cheaper through refresh_keys().
	func rebuild() -> void:
		_rebuild()


	## Re-resolves every key in place through KeyInfo.refresh_key_control, then
	## re-measures and re-places the key strips.
	## Rows, labels and Controls are kept, so an animated style costs no
	## allocation per frame.
	func refresh_keys() -> void:
		for item in _legend_items:
			(item as _LegendItem).refresh_keys()
		_apply_key_column_width()
		_remeasure()


	## Answers how big the legend wants to be, for a container about to place
	## it. Outside positions only.
	##
	## Both sides are measured from the entries and the style, and neither goes
	## above the limits. Names too long for the claimed side are cut, and the
	## entries left over are reached by scrolling. So the answer never makes the
	## plot bigger, whatever the legend holds.
	##
	## [param p_given_px] Size of the given side.
	## [param p_cap_px] Maximum size of the claimed side.
	func update_desired_size(p_given_px: float, p_cap_px: float) -> Vector2:
		if _family == PositionFamily.TOP_BOTTOM:
			_measure(Vector2(p_given_px, p_cap_px))
		else:
			_measure(Vector2(p_cap_px, p_given_px))
		# We got the answer, return it.
		return _box_size


	func get_max_size_px() -> int:
		return _style.max_size_px


	## Returns the maximum size of the claimed side.
	##
	## [param p_room_px] Free space on that side.
	## [param p_available_px] Size of that side in the plot. The share is a
	## fraction of this value.
	## [param p_max_size_px] Maximum in pixels, [code]0[/code] for uncapped.
	static func get_cap_px(p_room_px: float, p_available_px: float, p_max_size_px: int) -> float:
		if p_max_size_px > 0:
			return minf(p_room_px, float(p_max_size_px))
		return minf(p_room_px, _MAX_SIZE_FRACTION * p_available_px)


	## Sets whether the entries run left to right and wrap into new rows, or top
	## to bottom and wrap into new columns.
	##
	## The flow container fills the scroll viewport along the flow, so the
	## entries wrap where the measurement expects them to, and takes its own
	## depth across it, so the scroll container has something to scroll.
	##
	## Only a vertical flow stacks the series names into a column, so it is the
	## only one that aligns the key strips.
	func set_flow_vertical(p_vertical: bool) -> void:
		_flow.vertical = p_vertical
		_align_key_columns = p_vertical
		if p_vertical:
			_flow.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_flow.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		else:
			_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_flow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

		_apply_key_column_width()
		_remeasure()


	## Tells the legend which side its parent gives it.
	func set_position_family(p_family: PositionFamily) -> void:
		if _family == p_family:
			return
		_family = p_family
		_remeasure()


	## Gives the legend the size of the data area it floats over. Only read for
	## [constant PositionFamily.INSIDE], where that area gives both limits.
	func set_data_area(p_size: Vector2) -> void:
		if _data_area == p_size:
			return
		_data_area = p_size
		_remeasure()


	## Returns the current resolved TauLegendStyle.
	func get_resolved_legend_style() -> TauLegendStyle:
		return _style


	## Sets the resolved TauLegendStyle and rebuilds the internal layout if it changed.
	func set_resolved_legend_style(p_style: TauLegendStyle) -> void:
		if _style != null and _style.is_equal_to(p_style):
			return
		_style = p_style
		_rebuild()


	####################################################################################################
	# Private
	####################################################################################################

	## Full rebuild of all legend items.
	func _rebuild() -> void:
		if _style == null:
			return

		for item in _legend_items:
			_flow.remove_child(item)
			item.queue_free()
		_legend_items.clear()

		# A PanelContainer insets its child by the content margins of its
		# panel, so the padding around the entries comes with the background.
		_box.add_theme_stylebox_override(&"panel", _style.background)

		_flow.add_theme_constant_override(&"h_separation", _style.item_gap_px)
		_flow.add_theme_constant_override(&"v_separation", _style.item_gap_px)

		for info in _series_infos:
			var item := _LegendItem.new(info, _style)
			_flow.add_child(item)
			_legend_items.append(item)

		_apply_key_column_width()
		_remeasure()


	# Inside the data area the legend knows both limits and measures now.
	# Outside, only the container knows them, so ask it to sort. The cast is
	# null while the legend moves from one position to another.
	func _remeasure() -> void:
		if _family == PositionFamily.INSIDE:
			_measure(_get_inside_limits())
			return

		var container := get_parent() as Container
		if container != null:
			container.queue_sort()


	# Sizes the box, the entries and the scrollbars in one pass over the entries.
	func _measure(p_limits: Vector2) -> void:
		if _style == null:
			return

		var padding := _padding()
		var content_limits := Vector2(
			maxf(p_limits.x - padding.x, 0.0),
			maxf(p_limits.y - padding.y, 0.0))

		var vertical := _flow.vertical
		var limit_along := content_limits.y if vertical else content_limits.x
		var limit_across := content_limits.x if vertical else content_limits.y

		var content := _run_entries(limit_along, limit_across)

		# A scrollbar across the flow takes room along it, so the entries are
		# cut and wrapped once more against what is left. Two passes are
		# enough and the result does not depend on the order they run in.
		var scrollbar_px := 0.0
		if content.y > limit_across:
			scrollbar_px = _scrollbar_thickness_px()
			content = _run_entries(maxf(limit_along - scrollbar_px, 0.0), limit_across)
		_apply_scroll_modes(scrollbar_px > 0.0)

		var along := content.x + scrollbar_px
		var across := content.y
		var box_content := Vector2(across, along) if vertical else Vector2(along, across)
		var box_size := (box_content + padding).min(p_limits)

		_box.offset_left = -0.5 * box_size.x
		_box.offset_right = 0.5 * box_size.x
		_box.offset_top = -0.5 * box_size.y
		_box.offset_bottom = 0.5 * box_size.y

		if box_size != _box_size:
			_box_size = box_size
			update_minimum_size()


	# Walks the entries the way FlowContainer will, and returns what they take
	# as (along the flow, across the flow).
	#
	# Every entry is cut to the width limit on the way, so the run along the
	# flow never passes p_limit_along. The depth across the flow can pass
	# p_limit_across, which is what asks for a scrollbar.
	func _run_entries(p_limit_along: float, p_limit_across: float) -> Vector2:
		var vertical := _flow.vertical
		var width_limit := p_limit_across if vertical else p_limit_along
		var gap := float(_style.item_gap_px)

		var line_run := 0.0		# what the current line takes along the flow
		var line_thick := 0.0	# how deep the current line is across the flow
		var total_thick := 0.0	# the finished lines and the gaps between them
		var count := 0			# entries on the current line
		var longest_run := 0.0

		for item in _legend_items:
			var entry := item as _LegendItem
			var natural := entry.get_natural_size()
			var entry_size := Vector2(minf(natural.x, width_limit), natural.y)
			entry.set_entry_width(entry_size.x)

			var entry_along := entry_size.y if vertical else entry_size.x
			var entry_across := entry_size.x if vertical else entry_size.y

			if count > 0:
				line_run += gap
			if line_run + entry_along > p_limit_along:
				total_thick += line_thick + gap
				line_run = 0.0
				line_thick = 0.0
				count = 0

			line_run += entry_along
			line_thick = maxf(line_thick, entry_across)
			count += 1
			longest_run = maxf(longest_run, line_run)

		return Vector2(longest_run, total_thick + line_thick)


	# The data area less the margin, capped across the flow. All of it is free
	# space, since the legend floats over it.
	func _get_inside_limits() -> Vector2:
		var margin := 2.0 * float(_style.margin_px)
		var limits := Vector2(
			maxf(_data_area.x - margin, 0.0),
			maxf(_data_area.y - margin, 0.0))
		if _flow.vertical:
			limits.x = get_cap_px(limits.x, limits.x, _style.max_size_px)
		else:
			limits.y = get_cap_px(limits.y, limits.y, _style.max_size_px)
		return limits


	# Space the background takes around the entries, as (left plus right, top
	# plus bottom).
	func _padding() -> Vector2:
		return Vector2(
			_style.background.get_margin(SIDE_LEFT) + _style.background.get_margin(SIDE_RIGHT),
			_style.background.get_margin(SIDE_TOP) + _style.background.get_margin(SIDE_BOTTOM))


	func _scrollbar_thickness_px() -> float:
		if _flow.vertical:
			return _scroll.get_h_scroll_bar().get_combined_minimum_size().y
		return _scroll.get_v_scroll_bar().get_combined_minimum_size().x


	# The scrollbar runs across the flow, so it is the vertical one for a
	# horizontal legend.
	#
	# The measurement decides whether it shows, not the container. An automatic
	# mode would show the bar, take room along the flow, change where the
	# entries wrap, and possibly hide the bar again.
	func _apply_scroll_modes(p_scrolls: bool) -> void:
		var mode := ScrollContainer.SCROLL_MODE_SHOW_ALWAYS if p_scrolls else ScrollContainer.SCROLL_MODE_DISABLED
		if _flow.vertical:
			_scroll.horizontal_scroll_mode = mode
			_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		else:
			_scroll.vertical_scroll_mode = mode
			_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED


	## Widens every key strip to the widest one so the series names stacked
	## under each other share a single offset. Key boxes keep the size their
	## factory asked for, only the strip around them grows.
	##
	## A width of 0 releases the strips back to their own width, what a
	## horizontal flow wants since it puts no name under another.
	##
	## Strip widths come from the key boxes alone, which are resolved at
	## construction, so this runs without waiting for a layout pass.
	func _apply_key_column_width() -> void:
		var column_width: float = 0.0
		if _align_key_columns:
			for item in _legend_items:
				column_width = maxf(column_width, (item as _LegendItem).get_natural_key_width())
		for item in _legend_items:
			(item as _LegendItem).set_key_column_width(column_width)


	####################################################################################################
	# LegendItem (inner class)
	####################################################################################################

	## One row in the legend: a key strip followed by a label.
	class _LegendItem extends HBoxContainer:
		var _series_info: SeriesInfo = null
		var _style: TauLegendStyle = null
		var _key_strip: _KeyStrip = null
		var _label: Label = null
		var _natural_size: Vector2 = Vector2.ZERO


		func _init(p_info: SeriesInfo, p_style: TauLegendStyle) -> void:
			_series_info = p_info
			_style = p_style

			add_theme_constant_override(&"separation", _style.key_label_gap_px)
			# A cut name is shown in full in a tooltip, which needs the entry
			# to be seen by the mouse. PASS lets the event carry on upwards.
			mouse_filter = Control.MOUSE_FILTER_PASS

			# Key strip: creates factory Controls for each overlay key
			_key_strip = _KeyStrip.new(p_info, p_style)
			add_child(_key_strip)

			# Label
			_label = Label.new()
			_label.text = _series_info.series_name
			_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_label.add_theme_font_override(&"font", _style.get_font())
			_label.add_theme_font_size_override(&"font_size", _style.font_size)
			_label.add_theme_color_override(&"font_color", _style.font_color)
			# A Label that trims asks for one pixel of width, which is how the
			# entry can be laid out narrower than its name and let the width
			# set on the entry decide instead.
			_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_label.mouse_filter = Control.MOUSE_FILTER_PASS
			add_child(_label)

			_update_natural_size()


		func refresh_keys() -> void:
			_key_strip.refresh_keys()
			_update_natural_size()


		## Size the entry takes with the whole series name shown.
		func get_natural_size() -> Vector2:
			return _natural_size


		## Width the key strip takes on its own, before any column alignment.
		func get_natural_key_width() -> float:
			return _key_strip.get_natural_width()


		## Widens the key strip to p_width. 0 releases it to its own width.
		func set_key_column_width(p_width: float) -> void:
			_key_strip.set_column_width(p_width)
			_update_natural_size()


		## Sets the width the entry is laid out at. Below the natural width the
		## series name is cut with an ellipsis, and the whole name moves to the
		## tooltip.
		func set_entry_width(p_width: float) -> void:
			# Only the width is pinned. The height stays free, so reading the
			# natural height back later cannot drift upwards.
			custom_minimum_size = Vector2(p_width, 0.0)
			tooltip_text = _series_info.series_name if p_width < _natural_size.x else ""


		# The width comes from the font rather than from the Label, which
		# reports one pixel because it trims. The height is one line, the
		# taller of the key boxes and the name.
		func _update_natural_size() -> void:
			var font := _style.get_font()
			var key_size := _key_strip.custom_minimum_size
			var text_width := font.get_string_size(_series_info.series_name, HORIZONTAL_ALIGNMENT_LEFT, -1, _style.font_size).x
			_natural_size = Vector2(
				key_size.x + float(_style.key_label_gap_px) + text_width,
				maxf(key_size.y, font.get_height(_style.font_size)))


	####################################################################################################
	# KeyStrip (inner class)
	####################################################################################################

	## Holds one or more legend key Controls side by side, one per overlay type
	## bound to the series. Each key is created by invoking the factory Callable
	## stored in KeyInfo.create_key_control. Keys are placed manually so that
	## boxes of differing sizes stay centered on both axes, on the cross axis
	## within the strip and on the main axis within the shared column the strip
	## may be widened to.
	class _KeyStrip extends Control:
		var _series_info: SeriesInfo = null
		var _style: TauLegendStyle = null
		var _key_controls: Array[Control] = []
		var _key_sizes: PackedVector2Array = PackedVector2Array()
		var _natural_width: float = 0.0
		var _column_width: float = 0.0


		func _init(p_info: SeriesInfo, p_style: TauLegendStyle) -> void:
			_series_info = p_info
			_style = p_style

			_key_sizes.resize(_series_info.keys.size())
			for i in range(_series_info.keys.size()):
				var key_info: KeyInfo = _series_info.keys[i]
				var ctrl: Control = key_info.create_key_control.call(_series_info.series_index)
				_key_controls.append(ctrl)
				_resolve_key_size(i, ctrl)
				add_child(ctrl)

			_update_minimum_size()


		## Re-resolves every key through its refresh callable. A key is free to
		## request a different box on refresh, so the strip re-measures itself and
		## places the keys again.
		func refresh_keys() -> void:
			for i in range(_key_controls.size()):
				var ctrl: Control = _key_controls[i]
				_series_info.keys[i].refresh_key_control.call(_series_info.series_index, ctrl)
				_resolve_key_size(i, ctrl)

			_update_minimum_size()
			_layout_children()


		## Width of the key run itself, ignoring any column width pushed in.
		func get_natural_width() -> float:
			return _natural_width


		## Sets the width the strip is padded out to. Anything below the key run
		## is ignored, so 0 leaves the strip at its own width.
		func set_column_width(p_width: float) -> void:
			_column_width = p_width
			_update_minimum_size()
			_layout_children()


		func _notification(what: int) -> void:
			if what == NOTIFICATION_RESIZED:
				_layout_children()


		# A factory sizes only the axes its picture constrains. The height falls
		# back to the themed key size, the width to that height scaled by the
		# ratio the key asked for, so a wide key follows key_size_px.
		func _resolve_key_size(p_index: int, p_control: Control) -> void:
			var key_size: Vector2 = p_control.custom_minimum_size
			if key_size.y <= 0.0:
				key_size.y = _style.key_size_px
			if key_size.x <= 0.0:
				key_size.x = key_size.y * _series_info.keys[p_index].key_aspect_ratio
			p_control.custom_minimum_size = key_size
			_key_sizes[p_index] = key_size


		# Keys sit side by side, so widths add up and the tallest sets the height.
		func _update_minimum_size() -> void:
			var max_key_height: float = 0.0
			_natural_width = 0.0
			for key_sz in _key_sizes:
				_natural_width += key_sz.x
				max_key_height = maxf(max_key_height, key_sz.y)
			var key_count := _key_controls.size()
			if key_count > 1:
				_natural_width += float((key_count - 1) * _style.key_gap_px)
			custom_minimum_size = Vector2(maxf(_natural_width, _column_width), max_key_height)


		# The key run is centered, so a strip padded out to the shared column
		# keeps even space on both sides rather than hugging one edge.
		func _layout_children() -> void:
			var x_offset: float = (size.x - _natural_width) * 0.5
			for i in range(_key_controls.size()):
				var ctrl: Control = _key_controls[i]
				var key_size: Vector2 = _key_sizes[i]
				var y_offset: float = (size.y - key_size.y) * 0.5
				ctrl.position = Vector2(x_offset, y_offset)
				ctrl.size = key_size
				x_offset += key_size.x + _style.key_gap_px
