# Dependencies
const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const Axis = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis

# Partitions series IDs by pane and y-axis.
# All series contribute to the single shared x axis.
# Used by XYDomain, XYLayout, and renderers to know which series belong to which y-axis.
class SeriesAxisAssignment extends RefCounted:

	# Per-pane storage with AxisId-keyed dictionaries.
	class _PaneSlot extends RefCounted:
		var series_ids_per_y_axis: Dictionary[AxisId, PackedInt64Array] = {
			AxisId.BOTTOM: PackedInt64Array(),
			AxisId.TOP: PackedInt64Array(),
			AxisId.LEFT: PackedInt64Array(),
			AxisId.RIGHT: PackedInt64Array(),
		}
		var series_ids_of_x_axis: PackedInt64Array = PackedInt64Array()

	var _panes: Array[_PaneSlot] = []
	var _series_ids_of_x_axis: PackedInt64Array = PackedInt64Array()

	func _init(p_pane_count: int = 1) -> void:
		_panes.clear()
		for i in range(p_pane_count):
			_panes.append(_PaneSlot.new())


	# Adds a series ID to the given pane and y-axis id.
	# All series are also added to the "series_ids_of_x_axis" list for x-axis domain collection.
	# Duplicates are silently ignored.
	func assign(p_series_id: int, p_pane_index: int, p_y_axis_id: AxisId) -> void:
		if p_pane_index < 0 or p_pane_index >= _panes.size():
			push_error("SeriesAxisAssignment.assign(): pane index %d out of range (0..%d)" % [p_pane_index, _panes.size() - 1])
			return

		var slot: _PaneSlot = _panes[p_pane_index]

		if p_y_axis_id not in slot.series_ids_per_y_axis:
			push_error("SeriesAxisAssignment.assign(): unexpected y_axis_id %d" % p_y_axis_id)
			return

		if p_series_id not in slot.series_ids_per_y_axis[p_y_axis_id]:
			slot.series_ids_per_y_axis[p_y_axis_id].append(p_series_id)

		if p_series_id not in slot.series_ids_of_x_axis:
			slot.series_ids_of_x_axis.append(p_series_id)

		if p_series_id not in _series_ids_of_x_axis:
			_series_ids_of_x_axis.append(p_series_id)


	func get_x_axis_series_ids_per_pane(p_pane: int) -> PackedInt64Array:
		if p_pane < 0 or p_pane >= _panes.size():
			return PackedInt64Array()
		return _panes[p_pane].series_ids_of_x_axis


	func get_x_axis_series_ids() -> PackedInt64Array:
		return _series_ids_of_x_axis


	func get_y_axis_series_ids(p_pane: int, p_y_axis_id: AxisId) -> PackedInt64Array:
		if p_pane < 0 or p_pane >= _panes.size():
			return PackedInt64Array()

		var slot: _PaneSlot = _panes[p_pane]
		if p_y_axis_id not in slot.series_ids_per_y_axis:
			return PackedInt64Array()

		return slot.series_ids_per_y_axis[p_y_axis_id]


	func get_x_axis_series_count(p_pane: int) -> int:
		if p_pane < 0 or p_pane >= _panes.size():
			return 0
		return _panes[p_pane].series_ids_of_x_axis.size()


	func get_y_axis_series_count(p_pane: int, p_y_axis_id: AxisId) -> int:
		if p_pane < 0 or p_pane >= _panes.size():
			return 0

		var slot: _PaneSlot = _panes[p_pane]
		if p_y_axis_id not in slot.series_ids_per_y_axis:
			return 0

		return slot.series_ids_per_y_axis[p_y_axis_id].size()


	func is_assigned_to_y_axis(p_series_id: int, p_pane: int, p_y_axis_id: AxisId) -> bool:
		return p_series_id in get_y_axis_series_ids(p_pane, p_y_axis_id)


	# Returns the y-axis a series is assigned to in the given pane, or -1 if
	# the series is not found in any y-axis slot of that pane.
	func get_y_axis_id_for_series(p_series_id: int, p_pane: int) -> int:
		if p_pane < 0 or p_pane >= _panes.size():
			return -1

		var slot: _PaneSlot = _panes[p_pane]
		for axis_id in slot.series_ids_per_y_axis:
			if p_series_id in slot.series_ids_per_y_axis[axis_id]:
				return axis_id
		return -1
