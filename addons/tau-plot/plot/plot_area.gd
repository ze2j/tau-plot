# Dependencies
const Legend := preload("res://addons/tau-plot/plot/legend/legend.gd").Legend
const Position = TauLegendConfig.Position


## Container for the plot title, the legend and the plot content.
##
## Sizing runs top down, unlike a Godot container. The title takes the height
## it needs, the legend takes a capped share of what is left, and the content
## takes the rest.
##
## Only the title raises the minimum size of the plot. The legend never does:
## it is measured against the space left for it, and cuts or scrolls the rest.
class PlotArea extends Container:

	var _title: Control = null
	var _content: Control = null
	var _legend: Legend = null
	var _legend_position: Position = Position.OUTSIDE_TOP


	## Sets the plot title, which sits above everything else.
	func set_title(p_title: Control) -> void:
		_title = p_title
		add_child(_title)


	## Sets the subtree that draws the plot. Its minimum size is reserved before
	## the legend gets anything.
	func set_content(p_content: Control) -> void:
		_content = p_content
		add_child(_content)


	## Removes the plot content.
	func clear_content() -> void:
		remove_child(_content)
		_content = null


	## Adds the legend at an outside position. The position decides which side
	## the legend spans and which side it claims.
	func set_legend(p_legend: Legend, p_position: Position) -> void:
		_legend = p_legend
		_legend_position = p_position
		# The sort computes the whole rect. Any other flag would shrink the
		# legend back to its minimum size, which is zero.
		_legend.size_flags_horizontal = Control.SIZE_FILL
		_legend.size_flags_vertical = Control.SIZE_FILL
		add_child(_legend)


	## Removes the legend. The content then takes what the title leaves.
	func clear_legend() -> void:
		if _legend == null:
			return
		remove_child(_legend)
		_legend = null


	# The legend is left out on purpose: its size follows the space it gets.
	func _get_minimum_size() -> Vector2:
		var minimum := Vector2.ZERO
		if _title.visible:
			minimum = _title.get_combined_minimum_size()
		if _content != null:
			var content_minimum := _content.get_combined_minimum_size()
			minimum = Vector2(
				maxf(minimum.x, content_minimum.x),
				minimum.y + content_minimum.y)
		return minimum


	func _notification(p_what: int) -> void:
		if p_what == NOTIFICATION_SORT_CHILDREN:
			_sort_area()


	####################################################################################################
	# Private
	####################################################################################################

	# The size is known only here, so this is where the legend is measured.
	func _sort_area() -> void:
		var area := _take_title(Rect2(Vector2.ZERO, size))
		if _content == null:
			return

		var legend := _get_arbitrated_legend()
		if legend != null:
			area = _take_legend(legend, area)
		fit_child_in_rect(_content, area)


	# The title wraps, so its height depends on the width of the previous sort.
	# A resize settles in two passes.
	func _take_title(p_area: Rect2) -> Rect2:
		if not _title.visible:
			return p_area

		var height := minf(_title.get_combined_minimum_size().y, p_area.size.y)
		fit_child_in_rect(_title, Rect2(p_area.position, Vector2(p_area.size.x, height)))
		return Rect2(
			p_area.position + Vector2(0.0, height),
			Vector2(p_area.size.x, p_area.size.y - height))


	# A hidden legend claims nothing, like any hidden child of a container.
	func _get_arbitrated_legend() -> Legend:
		if _legend != null and _legend.visible:
			return _legend
		return null


	func _take_legend(p_legend: Legend, p_area: Rect2) -> Rect2:
		if _legend_position == Position.OUTSIDE_LEFT or _legend_position == Position.OUTSIDE_RIGHT:
			return _take_legend_width(p_legend, p_area)
		return _take_legend_height(p_legend, p_area)


	# Given the height, claims a width.
	func _take_legend_width(p_legend: Legend, p_area: Rect2) -> Rect2:
		var room := maxf(p_area.size.x - _content.get_combined_minimum_size().x, 0.0)
		var cap := Legend.get_cap_px(room, p_area.size.x, p_legend.get_max_size_px())
		var claim := p_legend.update_desired_size(p_area.size.y, cap).x
		var kept := Vector2(p_area.size.x - claim, p_area.size.y)

		if _legend_position == Position.OUTSIDE_LEFT:
			fit_child_in_rect(p_legend, Rect2(p_area.position, Vector2(claim, p_area.size.y)))
			return Rect2(p_area.position + Vector2(claim, 0.0), kept)

		fit_child_in_rect(p_legend, Rect2(
			Vector2(p_area.end.x - claim, p_area.position.y),
			Vector2(claim, p_area.size.y)))
		return Rect2(p_area.position, kept)


	# Given the width, claims a height.
	func _take_legend_height(p_legend: Legend, p_area: Rect2) -> Rect2:
		var room := maxf(p_area.size.y - _content.get_combined_minimum_size().y, 0.0)
		var cap := Legend.get_cap_px(room, p_area.size.y, p_legend.get_max_size_px())
		var claim := p_legend.update_desired_size(p_area.size.x, cap).y
		var kept := Vector2(p_area.size.x, p_area.size.y - claim)

		if _legend_position == Position.OUTSIDE_TOP:
			fit_child_in_rect(p_legend, Rect2(p_area.position, Vector2(p_area.size.x, claim)))
			return Rect2(p_area.position + Vector2(0.0, claim), kept)

		fit_child_in_rect(p_legend, Rect2(
			Vector2(p_area.position.x, p_area.end.y - claim),
			Vector2(p_area.size.x, claim)))
		return Rect2(p_area.position, kept)
