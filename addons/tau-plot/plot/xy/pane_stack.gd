# Sizes the panes of an XY plot along the stacking direction.
#
# A pane reserves space on its edges for tick marks and tick labels, and draws
# its data in what is left. Along the stacking direction the x axis is drawn on
# one pane only, so that pane reserves space and the others reserve none.
#
# A BoxContainer splits its whole size by stretch ratio alone. The pane that
# draws the x axis then takes that space out of its own share, and its data
# area comes out smaller than the data areas of the other panes.
#
# PaneStack gives each pane the space it reserves, then splits the rest by
# stretch ratio. Data areas follow the stretch ratios, whatever a pane reserves.
class PaneStack extends Container:
	## True when panes are stacked from top to bottom,
	## false when they are stacked from left to right.
	var vertical: bool = true:
		set(value):
			if vertical == value:
				return
			vertical = value
			queue_sort()

	## Space in pixels between two panes.
	var separation: int = 0:
		set(value):
			if separation == value:
				return
			separation = value
			queue_sort()

	# Space each pane reserves along the stacking direction, in pixels.
	# One entry per child, in child order.
	var _reservations: PackedFloat32Array = PackedFloat32Array()


	## Sets the space each pane reserves along the stacking direction.
	## Returns true when the values changed, which means the panes are about to
	## be resized.
	## [param p_reservations] One entry per child, in child order.
	func set_reservations(p_reservations: PackedFloat32Array) -> bool:
		if _reservations == p_reservations:
			return false
		_reservations = p_reservations
		queue_sort()
		return true


	func _notification(p_what: int) -> void:
		if p_what == NOTIFICATION_SORT_CHILDREN:
			_sort_panes()


	## Returns the rect of every pane, in PaneStack-local coordinates and in
	## child order.
	##
	## The sort applies exactly these rects, so a caller that needs the pane
	## geometry reads it here rather than from the pane nodes, which still
	## carry the sizes of the previous sort.
	func compute_child_rects() -> Array[Rect2]:
		var count := get_child_count()
		var rects: Array[Rect2] = []
		rects.resize(count)
		if count == 0:
			return rects

		var reserved_total := 0.0
		var ratio_total := 0.0
		for i in range(count):
			var child: Control = get_child(i)
			reserved_total += _reservations[i]
			ratio_total += child.size_flags_stretch_ratio

		var extent := size.y if vertical else size.x
		var gaps := float(separation * (count - 1))
		var free := extent - reserved_total - gaps

		# Not enough room for the reserved space. Shrink it so the panes still
		# fit, and let the data areas go to zero.
		var reserved_scale := 1.0
		if free < 0.0 and reserved_total > 0.0:
			reserved_scale = maxf(extent - gaps, 0.0) / reserved_total
		free = maxf(free, 0.0)

		var offset := 0.0
		for i in range(count):
			var child: Control = get_child(i)
			var pane_extent := _reservations[i] * reserved_scale + free * child.size_flags_stretch_ratio / ratio_total
			# Round both ends, not the size, so the rounding error does not add up along the stack.
			var start := roundf(offset)
			var end := roundf(offset + pane_extent)
			if vertical:
				rects[i] = Rect2(0.0, start, size.x, end - start)
			else:
				rects[i] = Rect2(start, 0.0, end - start, size.y)
			offset += pane_extent + float(separation)

		return rects


	func _sort_panes() -> void:
		var rects := compute_child_rects()
		for i in range(rects.size()):
			fit_child_in_rect(get_child(i), rects[i])
