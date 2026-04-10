# Dependencies
const Legend := preload("res://addons/tau-plot/plot/legend/legend.gd").Legend
const Position = TauLegendConfig.Position
const FlowDirection = TauLegendConfig.FlowDirection


## Manages the Legend node lifecycle: placement in the scene tree, flow direction,
## inside-overlay positioning, and size constraints.
##
## Plot-type agnostic. Does not know how to build legend content from data.
## Each plot type (XY, pie, radar) composes a LegendController and provides:
##   - A callable for attaching the legend at outside positions.
##   - Series infos for populating the legend.
class LegendController extends RefCounted:

	## The Legend node, or null if not built.
	var legend: Legend = null

	## Transparent overlay used for INSIDE legend positions so that the legend
	## can be anchored within the data area bounds.
	##
	## Created with top_level = true so that PanelContainer's layout sorting
	## cannot override the position and size set by update_inside_rect().
	## Without top_level, any child addition on the TauPlot PanelContainer
	## (e.g. the hover tooltip) triggers queue_sort(), which stretches every
	## non-internal, non-top-level child to fill the panel's content rect,
	## snapping the overlay (and the legend inside it) to the panel origin
	## and breaking INSIDE legend placement.
	var _inside_overlay: Control = null

	## Cached values for repositioning on resize.
	var _inside_position: Position = Position.OUTSIDE_BOTTOM
	var _inside_style: TauLegendStyle = null

	var _plot: PanelContainer = null

	## Plot-type callback for outside positions.
	## Signature: func(p_legend: Control, p_position: Position) -> void
	## The callback must add the legend as a child of the appropriate container.
	## The controller has already configured size_flags and max_size before
	## calling this.
	var _attach_outside: Callable = Callable()


	func _init(p_plot: PanelContainer, p_attach_outside: Callable) -> void:
		_plot = p_plot
		_attach_outside = p_attach_outside


	## Creates a fresh Legend node and populates it with the given series infos.
	## After this call, the legend is ready to be placed and shown.
	##
	## The style is resolved after the legend is temporarily added to the tree
	## so that theme lookups use the TauLegend type variation correctly.
	## Returns the resolved TauLegendStyle so the caller can cache it.
	func build(p_series_infos: Array[Legend.SeriesInfo],
			p_user_legend_style: TauLegendStyle,
			p_position: Position, p_flow: FlowDirection,
			p_visible: bool) -> TauLegendStyle:
		destroy()

		legend = Legend.new()
		legend.name = "Legend"
		legend.visible = p_visible

		# FIXME: Temporarily add the legend to the plot so it is in the tree and theme lookups against TauLegend work correctly.
		_plot.add_child(legend)

		# Resolve style against the now-in-tree legend node.
		var resolved_style := TauLegendStyle.resolve(legend, p_user_legend_style)
		legend.set_resolved_legend_style(resolved_style)
		legend.populate(p_series_infos)

		# Remove from the temporary parent before place() re-parents it
		# to the correct position in the scene tree.
		_plot.remove_child(legend)

		place(p_position)
		apply_flow_direction(p_position, p_flow)
		return resolved_style


	## Removes the legend from the scene tree and frees it.
	func destroy() -> void:
		if legend != null and is_instance_valid(legend):
			if legend.get_parent() != null:
				legend.get_parent().remove_child(legend)
			legend.queue_free()
		legend = null
		_destroy_inside_overlay()


	## Moves the legend to the correct position in the scene tree.
	func place(p_position: Position) -> void:
		if legend == null:
			return

		# Remove legend from its current parent.
		if legend.get_parent() != null:
			legend.get_parent().remove_child(legend)

		# Discard any previous inside overlay.
		_destroy_inside_overlay()

		# Reset anchors and offsets to a clean state.
		legend.set_anchors_preset(Control.PRESET_TOP_LEFT)
		legend.offset_left = 0
		legend.offset_right = 0
		legend.offset_top = 0
		legend.offset_bottom = 0
		legend.grow_horizontal = Control.GROW_DIRECTION_END
		legend.grow_vertical = Control.GROW_DIRECTION_END

		var style := legend.get_resolved_legend_style()
		if style == null:
			push_error("LegendController.place(): resolved legend style is null")
			return

		match p_position:
			Position.OUTSIDE_BOTTOM:
				legend.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				legend.size_flags_vertical = Control.SIZE_SHRINK_END
				if style.max_size_px > 0:
					legend.max_size = Vector2(0, style.max_size_px)
				else:
					legend.max_size = Vector2.ZERO
				_attach_outside.call(legend, p_position)

			Position.OUTSIDE_TOP:
				legend.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				legend.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				if style.max_size_px > 0:
					legend.max_size = Vector2(0, style.max_size_px)
				else:
					legend.max_size = Vector2.ZERO
				_attach_outside.call(legend, p_position)

			Position.OUTSIDE_LEFT:
				legend.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				legend.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				if style.max_size_px > 0:
					legend.max_size = Vector2(style.max_size_px, 0)
				else:
					legend.max_size = Vector2.ZERO
				_attach_outside.call(legend, p_position)

			Position.OUTSIDE_RIGHT:
				legend.size_flags_horizontal = Control.SIZE_SHRINK_END
				legend.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				if style.max_size_px > 0:
					legend.max_size = Vector2(style.max_size_px, 0)
				else:
					legend.max_size = Vector2.ZERO
				_attach_outside.call(legend, p_position)

			# Inside positions: the legend floats over the data area via an overlay.
			_:
				_inside_overlay = Control.new()
				_inside_overlay.name = "LegendOverlay"
				_inside_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_inside_overlay.top_level = true
				_plot.add_child(_inside_overlay)

				_inside_position = p_position
				_inside_style = style

				_inside_overlay.add_child(legend)
				_configure_inside_anchors(p_position, style)


	## Resolves and applies the legend flow direction.
	func apply_flow_direction(p_position: Position, p_flow: FlowDirection) -> void:
		if legend == null:
			return
		var resolved := resolve_flow_direction(p_position, p_flow)
		legend.set_flow_vertical(resolved == FlowDirection.VERTICAL)


	## Resolves AUTO flow direction based on position.
	static func resolve_flow_direction(p_position: Position, p_flow: FlowDirection) -> FlowDirection:
		if p_flow != FlowDirection.AUTO:
			return p_flow

		match p_position:
			Position.OUTSIDE_TOP, Position.OUTSIDE_BOTTOM, \
			Position.INSIDE_TOP, Position.INSIDE_BOTTOM:
				return FlowDirection.HORIZONTAL
			_:
				return FlowDirection.VERTICAL


	## Updates the inside overlay rect and legend max_size constraint.
	## Called from the plot type's refresh after layout computation.
	## p_data_area_rect is the data area union rect in Plot-local coordinates.
	## Converted to global coordinates here because the overlay uses
	## top_level = true and is therefore positioned in global space.
	func update_inside_rect(p_data_area_rect: Rect2) -> void:
		if legend == null or _inside_overlay == null:
			return

		var area := p_data_area_rect.size
		if area.x <= 0.0 or area.y <= 0.0:
			return

		var style := legend.get_resolved_legend_style()
		if style == null:
			return

		# The overlay is top_level, so position it in global coordinates.
		var global_origin := _plot.global_position + p_data_area_rect.position
		_inside_overlay.global_position = global_origin
		_inside_overlay.size = area

		# Compute max_size so the legend does not exceed the data area.
		var margin := float(style.margin_px)
		var max_w := area.x - 2.0 * margin
		var max_h := area.y - 2.0 * margin

		# Further cap the cross-axis if max_size_px is set.
		var is_horizontal_flow := (
			_inside_position == Position.INSIDE_TOP or
			_inside_position == Position.INSIDE_BOTTOM
		)
		if style.max_size_px > 0:
			if is_horizontal_flow:
				max_h = min(max_h, float(style.max_size_px))
			else:
				max_w = min(max_w, float(style.max_size_px))

		legend.max_size = Vector2(max_w, max_h)


	####################################################################################################
	# Private
	####################################################################################################


	## Frees the inside overlay if it exists.
	func _destroy_inside_overlay() -> void:
		if _inside_overlay != null and is_instance_valid(_inside_overlay):
			if _inside_overlay.get_parent() != null:
				_inside_overlay.get_parent().remove_child(_inside_overlay)
			_inside_overlay.queue_free()
		_inside_overlay = null
		_inside_style = null


	## Configures the legend's anchors, offsets, and grow directions for INSIDE
	## positions. Called once from place(). The overlay is not sized here.
	func _configure_inside_anchors(p_position: Position, p_style: TauLegendStyle) -> void:
		if legend == null:
			return

		var m := float(p_style.margin_px)

		match p_position:
			# Corner positions: all four anchors pinned to the same corner.
			Position.INSIDE_TOP_LEFT:
				legend.anchor_left = 0
				legend.anchor_right = 0
				legend.anchor_top = 0
				legend.anchor_bottom = 0
				legend.offset_left = m
				legend.offset_top = m
				legend.offset_right = m
				legend.offset_bottom = m
				legend.grow_horizontal = Control.GROW_DIRECTION_END
				legend.grow_vertical = Control.GROW_DIRECTION_END

			Position.INSIDE_TOP_RIGHT:
				legend.anchor_left = 1
				legend.anchor_right = 1
				legend.anchor_top = 0
				legend.anchor_bottom = 0
				legend.offset_left = -m
				legend.offset_top = m
				legend.offset_right = -m
				legend.offset_bottom = m
				legend.grow_horizontal = Control.GROW_DIRECTION_BEGIN
				legend.grow_vertical = Control.GROW_DIRECTION_END

			Position.INSIDE_BOTTOM_LEFT:
				legend.anchor_left = 0
				legend.anchor_right = 0
				legend.anchor_top = 1
				legend.anchor_bottom = 1
				legend.offset_left = m
				legend.offset_top = -m
				legend.offset_right = m
				legend.offset_bottom = -m
				legend.grow_horizontal = Control.GROW_DIRECTION_END
				legend.grow_vertical = Control.GROW_DIRECTION_BEGIN

			Position.INSIDE_BOTTOM_RIGHT:
				legend.anchor_left = 1
				legend.anchor_right = 1
				legend.anchor_top = 1
				legend.anchor_bottom = 1
				legend.offset_left = -m
				legend.offset_top = -m
				legend.offset_right = -m
				legend.offset_bottom = -m
				legend.grow_horizontal = Control.GROW_DIRECTION_BEGIN
				legend.grow_vertical = Control.GROW_DIRECTION_BEGIN

			# Edge-centered positions: anchors pinned to edge midpoint.
			Position.INSIDE_TOP:
				legend.anchor_left = 0.5
				legend.anchor_right = 0.5
				legend.anchor_top = 0
				legend.anchor_bottom = 0
				legend.offset_left = 0
				legend.offset_top = m
				legend.offset_right = 0
				legend.offset_bottom = m
				legend.grow_horizontal = Control.GROW_DIRECTION_BOTH
				legend.grow_vertical = Control.GROW_DIRECTION_END

			Position.INSIDE_BOTTOM:
				legend.anchor_left = 0.5
				legend.anchor_right = 0.5
				legend.anchor_top = 1
				legend.anchor_bottom = 1
				legend.offset_left = 0
				legend.offset_top = -m
				legend.offset_right = 0
				legend.offset_bottom = -m
				legend.grow_horizontal = Control.GROW_DIRECTION_BOTH
				legend.grow_vertical = Control.GROW_DIRECTION_BEGIN

			Position.INSIDE_LEFT:
				legend.anchor_left = 0
				legend.anchor_right = 0
				legend.anchor_top = 0.5
				legend.anchor_bottom = 0.5
				legend.offset_left = m
				legend.offset_top = 0
				legend.offset_right = m
				legend.offset_bottom = 0
				legend.grow_horizontal = Control.GROW_DIRECTION_END
				legend.grow_vertical = Control.GROW_DIRECTION_BOTH

			Position.INSIDE_RIGHT:
				legend.anchor_left = 1
				legend.anchor_right = 1
				legend.anchor_top = 0.5
				legend.anchor_bottom = 0.5
				legend.offset_left = -m
				legend.offset_top = 0
				legend.offset_right = -m
				legend.offset_bottom = 0
				legend.grow_horizontal = Control.GROW_DIRECTION_BEGIN
				legend.grow_vertical = Control.GROW_DIRECTION_BOTH
