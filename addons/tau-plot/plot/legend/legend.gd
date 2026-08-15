## Legend
## Displays dataset series names alongside visual keys representing their overlay types.
##
## Key drawing is delegated to plot-type-specific factory callables provided via KeyInfo.
## The Legend itself has no knowledge of any particular plot type.
class Legend extends PanelContainer:

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

	var _style: TauLegendStyle = null
	var _series_infos: Array[SeriesInfo] = []

	var _scroll_container: ScrollContainer = null
	var _flow_container: FlowContainer = null
	var _legend_items: Array[Control] = []
	var _is_rebuilding: bool = false
	var _align_key_columns: bool = false

	## Maximum size in pixels. 0 on either axis means unconstrained.
	## Set by LegendController based on theme constraints and plot dimensions.
	var max_size: Vector2 = Vector2.ZERO:
		set(value):
			max_size = value
			_update_scroll_minimum_size()


	func _init() -> void:
		theme_type_variation = &"TauLegend"

		_scroll_container = ScrollContainer.new()
		_scroll_container.name = "ScrollContainer"
		_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(_scroll_container)

		_flow_container = FlowContainer.new()
		_flow_container.name = "FlowContainer"
		_flow_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_flow_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_flow_container.resized.connect(_update_scroll_minimum_size)
		_scroll_container.add_child(_flow_container)


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


	## Sets whether the flow container uses horizontal or vertical arrangement.
	## Also adjusts size flags and scroll modes so the FlowContainer gets
	## enough space along its primary stacking axis.
	##
	## Vertical flow (p_vertical=true): items stack top-to-bottom, wrapping
	## into new columns.  The FlowContainer must expand vertically so items
	## have room to stack.  Scrolling, if needed, happens horizontally.
	##
	## Horizontal flow (p_vertical=false): items flow left-to-right, wrapping
	## into new rows.  The FlowContainer must expand horizontally so items
	## have room to flow.  Scrolling, if needed, happens vertically.
	##
	## Only a vertical flow stacks the series names into a column, so it is the
	## only one that aligns the key strips.
	func set_flow_vertical(p_vertical: bool) -> void:
		_flow_container.vertical = p_vertical
		_align_key_columns = p_vertical
		if p_vertical:
			_flow_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_flow_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		else:
			_flow_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			_flow_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

		_apply_key_column_width()
		# The FlowContainer minimum size depends on the flow direction.
		# Defer so the layout pass runs first and children report correct sizes.
		_update_scroll_minimum_size.call_deferred()


	## Returns the current resolved TauLegendStyle.
	func get_resolved_legend_style() -> TauLegendStyle:
		return _style


	## Sets the resolved TauLegendStyle and rebuilds the internal layout if it changed.
	func set_resolved_legend_style(p_style: TauLegendStyle) -> void:
		if _style != null and _style.is_equal_to(p_style):
			return
		_style = p_style
		_rebuild()


	## Updates the ScrollContainer's custom_minimum_size so the PanelContainer
	## requests enough space in box layouts. Along the flow axis (the direction
	## items are laid out before wrapping) the minimum is the sum of all
	## children so that items form a single unwrapped row or column. Along
	## the cross axis the FlowContainer's own minimum is used so the value
	## matches exactly what Godot's layout engine expects internally.
	## Both axes are then clamped by max_size.
	func _update_scroll_minimum_size() -> void:
		var flow_min := _flow_container.get_combined_minimum_size()

		# Compute the unwrapped content size along the flow axis.
		var h_sep := _flow_container.get_theme_constant(&"h_separation")
		var v_sep := _flow_container.get_theme_constant(&"v_separation")
		var child_count := 0
		var flow_total := 0.0

		for child_idx in range(_flow_container.get_child_count()):
			var child := _flow_container.get_child(child_idx)
			if child is Control and child.visible:
				var child_min := (child as Control).get_combined_minimum_size()
				if _flow_container.vertical:
					flow_total += child_min.y
				else:
					flow_total += child_min.x
				child_count += 1

		# Add gaps between children.
		if child_count > 1:
			var gap := float(v_sep if _flow_container.vertical else h_sep)
			flow_total += gap * float(child_count - 1)

		# Use our unwrapped sum for the flow axis and the FlowContainer's
		# own minimum for the cross axis so there is no mismatch.
		var target: Vector2
		if _flow_container.vertical:
			target = Vector2(flow_min.x, flow_total)
		else:
			target = Vector2(flow_total, flow_min.y)

		if max_size.x > 0:
			target.x = minf(target.x, max_size.x)
		if max_size.y > 0:
			target.y = minf(target.y, max_size.y)
		_scroll_container.custom_minimum_size = target


	## Full rebuild of all legend items.
	func _rebuild() -> void:
		if _is_rebuilding:
			return
		if _style == null:
			return
		_is_rebuilding = true

		# Clear existing items
		for item in _legend_items:
			if item != null and is_instance_valid(item):
				_flow_container.remove_child(item)
				item.queue_free()
		_legend_items.clear()

		# Apply the background stylebox from theme.
		add_theme_stylebox_override(&"panel", _style.background)

		# FlowContainer spacing
		_flow_container.add_theme_constant_override(&"h_separation", _style.item_gap_px)
		_flow_container.add_theme_constant_override(&"v_separation", _style.item_gap_px)

		# Build one LegendItem per series
		for info in _series_infos:
			var item := _LegendItem.new(info, _style)
			_flow_container.add_child(item)
			_legend_items.append(item)

		_apply_key_column_width()

		# Defer the minimum size update.  At this point child Labels have not
		# yet computed their minimum sizes (that happens during the layout
		# pass), so get_combined_minimum_size() would return stale values.
		_update_scroll_minimum_size.call_deferred()
		_is_rebuilding = false


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


		func _init(p_info: SeriesInfo, p_style: TauLegendStyle) -> void:
			_series_info = p_info
			_style = p_style

			add_theme_constant_override(&"separation", _style.key_label_gap_px)

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
			add_child(_label)


		func refresh_keys() -> void:
			_key_strip.refresh_keys()


		## Width the key strip takes on its own, before any column alignment.
		func get_natural_key_width() -> float:
			return _key_strip.get_natural_width()


		## Widens the key strip to p_width. 0 releases it to its own width.
		func set_key_column_width(p_width: float) -> void:
			_key_strip.set_column_width(p_width)


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
