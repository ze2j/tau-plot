# Sizes the panes of an XY plot along the stacking direction, and settles the
# layout they are drawn against.
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
	# Rounds the sort runs to make the reservations converge. A second round is
	# needed when measuring the tick labels changes what a pane reserves. A
	# third has never been observed to change anything.
	const _ROUNDS_MAX := 2

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

	# Measures the layout against a set of pane rects and returns what each pane
	# reserves along the stacking direction, one entry per child in child order.
	# Signature: func(p_rects: Array[Rect2]) -> PackedFloat32Array
	var _arrange: Callable = Callable()

	# Reports the rects the sort settled on, in PaneStack-local coordinates and
	# in child order, together with the position they are relative to.
	# Signature: func(p_rects: Array[Rect2], p_stack_global_position: Vector2) -> void
	var _geometry_settled: Callable = Callable()

	# Space each pane reserves along the stacking direction, in pixels, as the
	# last sort settled it. One entry per child, in child order. It only seeds
	# the next sort, which measures its own values.
	var _reservations: PackedFloat32Array = PackedFloat32Array()


	## Sets the two callbacks the sort runs. Both are required.
	## [param p_arrange] Measures the layout against a set of pane rects and
	## returns the space each pane reserves along the stacking direction.
	## [param p_geometry_settled] Receives the rects the sort applied and the
	## global position they are relative to.
	func setup(p_arrange: Callable, p_geometry_settled: Callable) -> void:
		_arrange = p_arrange
		_geometry_settled = p_geometry_settled


	func _notification(p_what: int) -> void:
		if p_what == NOTIFICATION_SORT_CHILDREN:
			_sort_panes()


	####################################################################################################
	# Private
	####################################################################################################

	# The whole layout of the plot is settled here, because this is the first
	# moment the stack holds the size Godot gives it. A caller that needs the
	# pane geometry takes it from the settled callback: the pane nodes only
	# carry it once this has run.
	func _sort_panes() -> void:
		var reservations := _seed_reservations()
		var rects := _compute_child_rects(reservations)

		# What a pane reserves is measured from the layout, and the layout is
		# measured against the extent the reservations leave. A round runs again
		# when the measurement changed them, so the panes are never drawn
		# against a set of reservations the layout does not match. Out of rounds, the
		# applied rects keep the layout they were measured with and the last
		# measurement seeds the next sort.
		for round_index in _ROUNDS_MAX:
			var measured: PackedFloat32Array = _arrange.call(rects)
			if measured == reservations:
				break
			reservations = measured
			if round_index < _ROUNDS_MAX - 1:
				rects = _compute_child_rects(reservations)
		_reservations = reservations

		for i in range(rects.size()):
			fit_child_in_rect(get_child(i), rects[i])

		_geometry_settled.call(rects, global_position)


	# A seed of a different length belongs to a different set of panes, which is
	# what ties _reservations to the child count the rects are indexed by.
	func _seed_reservations() -> PackedFloat32Array:
		var count := get_child_count()
		if _reservations.size() == count:
			return _reservations
		var fresh := PackedFloat32Array()
		fresh.resize(count)
		return fresh


	# Returns the rect of every pane, in PaneStack-local coordinates and in
	# child order, from the space each pane reserves along the stacking
	# direction.
	func _compute_child_rects(p_reservations: PackedFloat32Array) -> Array[Rect2]:
		var count := get_child_count()
		var rects: Array[Rect2] = []
		rects.resize(count)
		if count == 0:
			return rects

		var reserved_total := 0.0
		var ratio_total := 0.0
		for i in range(count):
			var child: Control = get_child(i)
			reserved_total += p_reservations[i]
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
			var pane_extent := p_reservations[i] * reserved_scale + free * child.size_flags_stretch_ratio / ratio_total
			# Round both ends, not the size, so the rounding error does not add up along the stack.
			var start := roundf(offset)
			var end := roundf(offset + pane_extent)
			if vertical:
				rects[i] = Rect2(0.0, start, size.x, end - start)
			else:
				rects[i] = Rect2(start, 0.0, end - start, size.y)
			offset += pane_extent + float(separation)

		return rects
