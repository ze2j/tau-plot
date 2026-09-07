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
## the claimed side both come from the container, through plan_box_size().
## Inside the data area the legend covers that area and both sides come from
## it. Names too long are cut with an ellipsis, extra entries scroll.
##
## The entries sit in a box. The legend places that box in the space it was
## given. Outside the data area the box is centered on the span. Inside, the
## box alignment picks the corner or the edge it goes against.
##
## The legend places every entry itself, at an exact rect. A name is therefore
## cut against the width the measurement gave it, and not against a width some
## other node settled afterwards.
##
## A measurement writes nothing, so a container can measure the legend during
## its own sort. The result is applied later, in the sort of the legend. The
## legend sets no minimum size, at any position.
class Legend extends Container:

	## Which side the parent gives the legend, and therefore which side the
	## legend claims and [member TauLegendStyle.max_size_px] caps.
	enum PositionFamily
	{
		TOP_BOTTOM,		# The parent gives the width, the legend claims a height.
		LEFT_RIGHT,		# The parent gives the height, the legend claims a width.
		INSIDE,			# The data area gives both sides, the legend claims nothing.
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

	# Share of the plot an uncapped legend may take.
	const _MAX_SIZE_FRACTION := 2./3.

	var _style: TauLegendStyle = null
	var _series_infos: Array[SeriesInfo] = []

	var _box: PanelContainer = null
	var _scroll: ScrollContainer = null
	var _entry_area: Control = null
	var _legend_items: Array[_LegendItem] = []

	# True when the entries run top to bottom and wrap into new columns.
	var _flow_vertical: bool = false

	var _family: PositionFamily = PositionFamily.TOP_BOTTOM

	# Position of the box in the data area, as a share of the space left free
	# on each axis. PositionFamily.INSIDE only.
	var _box_alignment: Vector2 = Vector2(0.5, 0.5)

	# Layout of the last measurement, waiting to be applied.
	var _plan: _LayoutPlan = _LayoutPlan.new()


	func _init() -> void:
		theme_type_variation = &"TauLegend"

		# A box that ends up larger than its slot is cut here rather than
		# painted over the plot.
		clip_contents = true

		# The node is larger than the box. Only the box takes the mouse, so the
		# space around it stays free for the plot.
		mouse_filter = Control.MOUSE_FILTER_IGNORE

		# The sort gives the box its rect, so no anchor is set here.
		_box = PanelContainer.new()
		_box.name = "Box"
		add_child(_box)

		# Measurement decides the scroll modes, so both start off.
		_scroll = ScrollContainer.new()
		_scroll.name = "Scroll"
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_box.add_child(_scroll)

		# A plain Control, not a container: the legend already walked the
		# entries to measure itself, so a container here would lay them out a
		# second time and could land on another result.
		_entry_area = Control.new()
		_entry_area.name = "EntryArea"
		_scroll.add_child(_entry_area)


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
			item.refresh_keys()
		_apply_key_column_width()
		_remeasure()


	## Measures the box against the space the container offers, and returns the
	## size it takes. Outside positions only.
	##
	## Both sides come out of the entries and the style, and neither goes above
	## the limits. A name too long for the claimed side is cut with an ellipsis.
	## The entries left over are reached by scrolling. So the answer never makes
	## the plot bigger, whatever the legend holds.
	##
	## No size is written here, so a container can call this during its own
	## sort. The layout is applied later, in the sort of the legend.
	##
	## [param p_given_px] Size of the given side.
	## [param p_cap_px] Maximum size of the claimed side.
	func plan_box_size(p_given_px: float, p_cap_px: float) -> Vector2:
		var limits := Vector2(p_cap_px, p_given_px)
		if _family == PositionFamily.TOP_BOTTOM:
			limits = Vector2(p_given_px, p_cap_px)

		_plan = _plan_layout(limits)
		queue_sort()
		return _plan.box_size


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
	## The entry area fills the scroll viewport along the flow, so a box wider
	## than the entries keeps them centered, and takes its own depth across it,
	## so the scroll container has something to scroll.
	##
	## Only a vertical flow stacks the series names into a column, so it is the
	## only one that aligns the key strips.
	func set_flow_vertical(p_vertical: bool) -> void:
		_flow_vertical = p_vertical
		if p_vertical:
			_entry_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_entry_area.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		else:
			_entry_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_entry_area.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

		_apply_key_column_width()
		_remeasure()


	## Tells the legend which side its parent gives it.
	func set_position_family(p_family: PositionFamily) -> void:
		if _family == p_family:
			return
		_family = p_family
		_remeasure()


	## Sets the position of the box in the data area, as a share of the space
	## left free on each axis. [code]0[/code] is the left or the top edge,
	## [code]0.5[/code] the middle, [code]1[/code] the right or the bottom edge.
	## Only read for [constant PositionFamily.INSIDE].
	func set_box_alignment(p_alignment: Vector2) -> void:
		if _box_alignment == p_alignment:
			return
		_box_alignment = p_alignment
		queue_sort()


	## Returns the current resolved TauLegendStyle.
	func get_resolved_legend_style() -> TauLegendStyle:
		return _style


	## Sets the resolved TauLegendStyle and rebuilds the internal layout if it changed.
	func set_resolved_legend_style(p_style: TauLegendStyle) -> void:
		if _style != null and _style.is_equal_to(p_style):
			return
		_style = p_style
		_rebuild()


	func _notification(p_what: int) -> void:
		if p_what == NOTIFICATION_SORT_CHILDREN:
			_sort_legend()


	####################################################################################################
	# Private
	####################################################################################################

	## Full rebuild of all legend items.
	func _rebuild() -> void:
		if _style == null:
			return

		for item in _legend_items:
			_entry_area.remove_child(item)
			item.queue_free()
		_legend_items.clear()

		# A PanelContainer insets its child by the content margins of its
		# panel, so the padding around the entries comes with the background.
		_box.add_theme_stylebox_override(&"panel", _style.background)

		for info in _series_infos:
			var item := _LegendItem.new(info, _style)
			_entry_area.add_child(item)
			_legend_items.append(item)

		_apply_key_column_width()
		_remeasure()


	# Asks for a new measurement.
	#
	# Inside the data area the legend knows its limits, so its own sort is
	# enough. Outside, only the container knows them, so it is asked to sort
	# too. The cast is null while the legend moves from one position to
	# another.
	func _remeasure() -> void:
		queue_sort()
		if _family == PositionFamily.INSIDE:
			return

		var container := get_parent() as Container
		if container != null:
			container.queue_sort()


	# Applies the last measurement and places the box.
	#
	# Inside the data area the limits come from the size of the legend, so the
	# measurement runs here. Outside, the container has measured the legend
	# before placing it.
	#
	# Every write waits for this sort. Godot drops a sort asked for by a
	# container that is sorting, and a minimum size change only travels on a
	# deferred call.
	func _sort_legend() -> void:
		if _style == null:
			return

		if _family == PositionFamily.INSIDE:
			_plan = _plan_layout(_get_inside_limits())

		_apply_layout(_plan)
		fit_child_in_rect(_box, _get_box_rect(_plan.box_size))


	# Measures the box, the entries and the scrollbar. Nothing is written
	# outside the plan.
	func _plan_layout(p_limits: Vector2) -> _LayoutPlan:
		var plan := _LayoutPlan.new()

		var padding := _get_padding()
		var content_limits := Vector2(
			maxf(p_limits.x - padding.x, 0.0),
			maxf(p_limits.y - padding.y, 0.0))

		var vertical := _flow_vertical
		var limit_along := content_limits.y if vertical else content_limits.x
		var limit_across := content_limits.x if vertical else content_limits.y

		var extent := _run_entries(limit_along, limit_across, plan)

		# A scrollbar across the flow takes room along it, so the entries are
		# cut and wrapped once more against what is left. Two passes are
		# enough and the result does not depend on the order they run in.
		var scrollbar_px := 0.0
		if extent.y > limit_across:
			scrollbar_px = _get_scrollbar_thickness_px()
			extent = _run_entries(maxf(limit_along - scrollbar_px, 0.0), limit_across, plan)
		plan.scrolls = scrollbar_px > 0.0

		var scrollbar_size := Vector2(0.0, scrollbar_px) if vertical else Vector2(scrollbar_px, 0.0)
		plan.content_size = Vector2(extent.y, extent.x) if vertical else extent
		plan.box_size = (plan.content_size + scrollbar_size + padding).min(p_limits)
		return plan


	# Writes the layout of a plan. Called from the sort of the legend only.
	#
	# A rebuild changes the entries and asks the container for a new
	# measurement. The sort can run before that measurement, so the plan can
	# hold more rects than there are entries. The extra rects are dropped and
	# the next sort writes the right ones.
	func _apply_layout(p_plan: _LayoutPlan) -> void:
		# The only minimum size written from a sort. It gives the scrollbar
		# its range and cannot leave the legend, whose own minimum size is
		# zero.
		_entry_area.custom_minimum_size = p_plan.content_size
		_apply_scroll_modes(p_plan.scrolls)

		for i in range(mini(p_plan.entry_rects.size(), _legend_items.size())):
			_legend_items[i].set_entry_rect(p_plan.entry_rects[i])


	# Cuts the entries into lines, then places them. Returns what they take as
	# (along the flow, across the flow). Every entry rect is written into
	# p_plan.
	#
	# Every entry is cut to the width limit on the way, so the run along the
	# flow never passes p_limit_along. The depth across the flow can pass
	# p_limit_across, which is what asks for a scrollbar.
	func _run_entries(p_limit_along: float, p_limit_across: float, p_plan: _LayoutPlan) -> Vector2:
		var vertical := _flow_vertical
		var width_limit := p_limit_across if vertical else p_limit_along
		var gap := float(_style.item_gap_px)

		var entry_runs := PackedFloat32Array()
		entry_runs.resize(_legend_items.size())
		var lines: Array[_EntryLine] = []
		var line: _EntryLine = null

		for i in range(_legend_items.size()):
			var entry := _legend_items[i]
			var natural := entry.get_natural_size()
			# The floor wins over the limit. An entry laid out under it grows
			# back to it and the surplus is clipped, so counting the floor
			# here is what keeps the measurement and the drawing in step.
			var width := maxf(minf(natural.x, width_limit), entry.get_minimum_width())
			var run := natural.y if vertical else width
			var thickness := width if vertical else natural.y
			entry_runs[i] = run

			# The first entry of a line always fits, whatever its run, so a
			# name wider than the limit still gets its own line.
			var line_run := run if line == null else line.run + gap + run
			if line == null or line_run > p_limit_along:
				line = _EntryLine.new()
				line.first_entry = i
				lines.append(line)
				line_run = run

			line.run = line_run
			line.thickness = maxf(line.thickness, thickness)
			line.entry_count += 1

		return _place_entries(lines, entry_runs, p_plan)


	# Turns lines into one rect per entry, in the coordinates of the entry
	# area, and returns the extent they take.
	#
	# A line shorter than the longest one is centered along the flow rather
	# than left hanging on one edge. Every entry of a line takes the whole
	# thickness of that line, so the series names of a column share one width
	# and the entries of a row share one height.
	func _place_entries(p_lines: Array[_EntryLine], p_entry_runs: PackedFloat32Array, p_plan: _LayoutPlan) -> Vector2:
		var vertical := _flow_vertical
		var gap := float(_style.item_gap_px)

		var extent_along := 0.0
		var extent_across := 0.0
		for line in p_lines:
			extent_along = maxf(extent_along, line.run)
			extent_across += line.thickness
		extent_across += maxf(float(p_lines.size() - 1), 0.0) * gap

		# Every rect is written below, so a second walk replaces the first one.
		p_plan.entry_rects.resize(p_entry_runs.size())

		var offset_across := 0.0
		for line in p_lines:
			var offset_along := 0.5 * (extent_along - line.run)
			for i in range(line.first_entry, line.first_entry + line.entry_count):
				var run: float = p_entry_runs[i]
				if vertical:
					p_plan.entry_rects[i] = Rect2(offset_across, offset_along, line.thickness, run)
				else:
					p_plan.entry_rects[i] = Rect2(offset_along, offset_across, run, line.thickness)
				offset_along += run + gap
			offset_across += line.thickness + gap

		return Vector2(extent_along, extent_across)


	# Rect of the box in the legend. Outside the data area the box is centered
	# on the span. Inside, it goes against the corner or the edge of the box
	# alignment, one margin away from it.
	func _get_box_rect(p_box_size: Vector2) -> Rect2:
		if _family != PositionFamily.INSIDE:
			return Rect2(0.5 * (size - p_box_size), p_box_size)

		var margin := Vector2(float(_style.margin_px), float(_style.margin_px))
		return Rect2(margin + _box_alignment * (size - p_box_size - 2.0 * margin), p_box_size)


	# The legend covers the data area, so its size gives the limits. The margin
	# is taken out and the cap applies across the flow. All of it is free
	# space, since the legend floats over the data area.
	func _get_inside_limits() -> Vector2:
		var margin := 2.0 * float(_style.margin_px)
		var limits := Vector2(
			maxf(size.x - margin, 0.0),
			maxf(size.y - margin, 0.0))
		if _flow_vertical:
			limits.x = get_cap_px(limits.x, limits.x, _style.max_size_px)
		else:
			limits.y = get_cap_px(limits.y, limits.y, _style.max_size_px)
		return limits


	# Space the background takes around the entries, as (left plus right, top
	# plus bottom).
	func _get_padding() -> Vector2:
		return Vector2(
			_style.background.get_margin(SIDE_LEFT) + _style.background.get_margin(SIDE_RIGHT),
			_style.background.get_margin(SIDE_TOP) + _style.background.get_margin(SIDE_BOTTOM))


	func _get_scrollbar_thickness_px() -> float:
		if _flow_vertical:
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
		if _flow_vertical:
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
		if _flow_vertical:
			for item in _legend_items:
				column_width = maxf(column_width, item.get_natural_key_width())
		for item in _legend_items:
			item.set_key_column_width(column_width)


	####################################################################################################
	# LayoutPlan (inner class)
	####################################################################################################

	## Describes the layout settled by one measurement.
	class _LayoutPlan extends RefCounted:
		## Size of the box, never above the limits of the measurement.
		var box_size: Vector2 = Vector2.ZERO

		## What the entries take. It can pass the box across the flow, which
		## is the part the scrollbar reaches.
		var content_size: Vector2 = Vector2.ZERO

		## Rect of every entry in the entry area, in the order of the entries.
		var entry_rects: Array[Rect2] = []

		## True when the entries need a scrollbar across the flow.
		var scrolls: bool = false


	####################################################################################################
	# EntryLine (inner class)
	####################################################################################################

	## One row or column of entries, as the entry walk cut it.
	class _EntryLine extends RefCounted:
		## Index of the first entry of the line.
		var first_entry: int = 0

		## Number of entries on the line.
		var entry_count: int = 0

		## What the entries and the gaps between them take along the flow.
		var run: float = 0.0

		## How deep the line is across the flow.
		var thickness: float = 0.0


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
			# entry can be laid out narrower than its name and let the rect
			# given to the entry decide instead.
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


		## Smallest width the entry can be drawn at: the key strip, the gap and
		## one pixel of series name. At that width the name is gone and the
		## entry shows its keys alone.
		func get_minimum_width() -> float:
			return get_combined_minimum_size().x


		## Places the entry at p_rect. Below the natural width the series name
		## is cut with an ellipsis, and the whole name moves to the tooltip.
		func set_entry_rect(p_rect: Rect2) -> void:
			position = p_rect.position
			size = p_rect.size
			tooltip_text = _series_info.series_name if p_rect.size.x < _natural_size.x else ""


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
