# Dependencies
const Legend := preload("res://addons/tau-plot/plot/legend/legend.gd").Legend
const Position = TauLegendConfig.Position
const FlowDirection = TauLegendConfig.FlowDirection


## Manages the Legend node lifecycle: placement in the scene tree, flow direction,
## and inside-overlay positioning.
##
## The legend sizes itself. What the controller gives it is where it sits: the
## family of its position, and the data area for the INSIDE_* family.
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
	##
	## top_level also detaches the node from the canvas item of its parent, so
	## the overlay escapes the clipping of every node above it. It clips itself
	## instead, which is what keeps an inside legend off its neighbours.
	var _inside_overlay: Control = null

	var _plot: PanelContainer = null

	## Plot-type callback for outside positions. It must add the legend to the
	## container that sizes it.
	## Signature: func(p_legend: Legend, p_position: Position) -> void
	var _attach_outside: Callable = Callable()

	## Plot-type callback that removes the legend from that container, which
	## keeps a reference to it.
	## Signature: func() -> void
	var _detach_outside: Callable = Callable()


	func _init(p_plot: PanelContainer, p_attach_outside: Callable, p_detach_outside: Callable) -> void:
		_plot = p_plot
		_attach_outside = p_attach_outside
		_detach_outside = p_detach_outside


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

		# The flow direction tells the legend which way the entries run and
		# which side the cap applies to inside the data area, so it is settled
		# before place() hands over the position family.
		apply_flow_direction(p_position, p_flow)
		place(p_position)
		return resolved_style


	## Removes the legend from the scene tree and frees it.
	func destroy() -> void:
		if legend != null:
			_detach()
			legend.queue_free()
		legend = null
		_destroy_inside_overlay()


	## Moves the legend to the correct position in the scene tree.
	func place(p_position: Position) -> void:
		if legend == null:
			return

		_detach()

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

		legend.set_position_family(position_family(p_position))

		match p_position:
			# Outside positions: the container computes the whole rect.
			Position.OUTSIDE_TOP, Position.OUTSIDE_BOTTOM, \
			Position.OUTSIDE_LEFT, Position.OUTSIDE_RIGHT:
				_attach_outside.call(legend, p_position)

			# Inside positions: the legend floats over the data area via an overlay.
			_:
				_inside_overlay = Control.new()
				_inside_overlay.name = "LegendOverlay"
				_inside_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_inside_overlay.top_level = true
				_inside_overlay.clip_contents = true
				_plot.add_child(_inside_overlay)

				_inside_overlay.add_child(legend)
				_configure_inside_anchors(p_position, legend.get_resolved_legend_style())


	## Resolves and applies the legend flow direction.
	func apply_flow_direction(p_position: Position, p_flow: FlowDirection) -> void:
		if legend == null:
			return
		var resolved := resolve_flow_direction(p_position, p_flow)
		legend.set_flow_vertical(resolved == FlowDirection.VERTICAL)


	## Returns which side the container gives a legend at p_position, which is
	## what decides the side the legend claims and the side max_size_px caps.
	static func position_family(p_position: Position) -> Legend.PositionFamily:
		match p_position:
			Position.OUTSIDE_TOP, Position.OUTSIDE_BOTTOM:
				return Legend.PositionFamily.TOP_BOTTOM
			Position.OUTSIDE_LEFT, Position.OUTSIDE_RIGHT:
				return Legend.PositionFamily.LEFT_RIGHT
			_:
				return Legend.PositionFamily.INSIDE


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


	## Updates the inside overlay rect and hands the new data area to the
	## legend, which is what an inside legend sizes itself against.
	## Does nothing unless the legend is at an inside position.
	## [param p_data_area_global] The data area union rect, in global
	## coordinates, which is the space the overlay is positioned in since it
	## uses top_level = true.
	func update_inside_rect(p_data_area_global: Rect2) -> void:
		if legend == null or _inside_overlay == null:
			return

		var area := p_data_area_global.size
		if area.x <= 0.0 or area.y <= 0.0:
			return

		_inside_overlay.global_position = p_data_area_global.position
		_inside_overlay.size = area
		legend.set_data_area(area)


	####################################################################################################
	# Private
	####################################################################################################


	## Removes the legend from the plot area or from the inside overlay.
	func _detach() -> void:
		_detach_outside.call()
		if legend.get_parent() != null:
			legend.get_parent().remove_child(legend)


	## Frees the inside overlay if it exists.
	func _destroy_inside_overlay() -> void:
		if _inside_overlay != null:
			if _inside_overlay.get_parent() != null:
				_inside_overlay.get_parent().remove_child(_inside_overlay)
			_inside_overlay.queue_free()
		_inside_overlay = null


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
