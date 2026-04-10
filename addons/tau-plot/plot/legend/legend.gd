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
		## If the returned Control sets custom_minimum_size, that size is used.
		## Otherwise the legend applies its default key_size_px.
		var create_key_control: Callable = Callable()

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
	## Call when renderer styles change (colors, alpha, outline, marker shape/size)
	## so that legend keys reflect the updated appearance.
	func rebuild() -> void:
		_rebuild()


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
	func set_flow_vertical(p_vertical: bool) -> void:
		_flow_container.vertical = p_vertical
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
			target.x = min(target.x, max_size.x)
		if max_size.y > 0:
			target.y = min(target.y, max_size.y)
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

		# Defer the minimum size update.  At this point child Labels have not
		# yet computed their minimum sizes (that happens during the layout
		# pass), so get_combined_minimum_size() would return stale values.
		_update_scroll_minimum_size.call_deferred()
		_is_rebuilding = false


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
			if _style.font != null:
				_label.add_theme_font_override(&"font", _style.font)
			_label.add_theme_font_size_override(&"font_size", _style.font_size)
			_label.add_theme_color_override(&"font_color", _style.font_color)
			add_child(_label)


	####################################################################################################
	# KeyStrip (inner class)
	####################################################################################################

	## Holds one or more legend key Controls side by side, one per overlay type
	## bound to the series. Each key is created by invoking the factory Callable
	## stored in KeyInfo.create_key_control. Child Controls are positioned
	## manually to replicate the exact centering of the original draw-based
	## approach.
	class _KeyStrip extends Control:
		var _series_info: SeriesInfo = null
		var _style: TauLegendStyle = null
		var _key_controls: Array[Control] = []
		var _key_sizes: PackedFloat32Array = PackedFloat32Array()


		func _init(p_info: SeriesInfo, p_style: TauLegendStyle) -> void:
			_series_info = p_info
			_style = p_style

			for key_info in _series_info.keys:
				if not key_info.create_key_control.is_valid():
					push_error("Legend._KeyStrip: create_key_control callable is not valid for series '%s'" % _series_info.series_name)
					continue
				var ctrl: Control = key_info.create_key_control.call(_series_info.series_index)
				if ctrl == null:
					push_error("Legend._KeyStrip: create_key_control returned null for series '%s'" % _series_info.series_name)
					continue

				# Determine the key size. If the factory set a minimum size,
				# use its width (keys are square). Otherwise use key_size_px.
				var key_sz: float = _style.key_size_px
				if ctrl.custom_minimum_size.x > 0.0:
					key_sz = ctrl.custom_minimum_size.x
				else:
					ctrl.custom_minimum_size = Vector2(_style.key_size_px, _style.key_size_px)

				_key_controls.append(ctrl)
				_key_sizes.append(key_sz)
				add_child(ctrl)

			# Compute minimum size based on key count (same logic as old code).
			var key_count := _key_controls.size()
			var total_width: float = 0.0
			for i in range(key_count):
				total_width += _key_sizes[i]
			if key_count > 1:
				total_width += float((key_count - 1) * _style.key_gap_px)
			var max_key_height: float = 0.0
			for sz in _key_sizes:
				max_key_height = max(max_key_height, sz)
			custom_minimum_size = Vector2(total_width, max_key_height)


		func _notification(what: int) -> void:
			if what == NOTIFICATION_RESIZED:
				_layout_children()


		func _layout_children() -> void:
			var x_offset: float = 0.0
			for i in range(_key_controls.size()):
				var ctrl: Control = _key_controls[i]
				var key_sz: float = _key_sizes[i]
				var y_offset: float = (size.y - key_sz) * 0.5
				ctrl.position = Vector2(x_offset, y_offset)
				ctrl.size = Vector2(key_sz, key_sz)
				x_offset += key_sz + _style.key_gap_px
