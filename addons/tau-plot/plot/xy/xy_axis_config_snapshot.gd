# Dependencies
const AxisId := preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId


# The four properties of one TauAxisConfig the ticks are resolved from.
class _AxisSnapshot extends RefCounted:
	var tick_count_preferred: int
	var overlap_strategy: TauAxisConfig.OverlapStrategy
	var min_label_spacing_px: int
	var inverted: bool


	func _init(p_config: TauAxisConfig) -> void:
		tick_count_preferred = p_config.tick_count_preferred
		overlap_strategy = p_config.overlap_strategy
		min_label_spacing_px = p_config.min_label_spacing_px
		inverted = p_config.inverted


	func matches(p_config: TauAxisConfig) -> bool:
		return (p_config.tick_count_preferred == tick_count_preferred
				and p_config.overlap_strategy == overlap_strategy
				and p_config.min_label_spacing_px == min_label_spacing_px
				and p_config.inverted == inverted)


# What a refresh compares the axis configs against, for the shared x axis and
# the y axes of every pane.
#
# No tracker watches TauAxisConfig, so the four properties above are copied here
# once a refresh has read them, and compared on the next one. The rest of that
# class is read at setup only, and nothing compares it.
class XYAxisConfigSnapshot extends RefCounted:
	const _Y_AXIS_IDS: Array[AxisId] = [AxisId.BOTTOM, AxisId.TOP, AxisId.LEFT, AxisId.RIGHT]

	# Null when the plot configures no x axis.
	var _x_axis: _AxisSnapshot = null

	# One entry per pane, each a Dictionary[AxisId, _AxisSnapshot] holding the
	# edges the pane configures. FIXME Godot 4.5 does not support nested typed
	# collections.
	var _y_axes_per_pane: Array[Dictionary] = []


	# True when a snapshotted property differs from p_config, or when an axis
	# was added or removed since the snapshot was taken.
	func has_changed(p_config: TauXYConfig) -> bool:
		if _has_axis_changed(_x_axis, p_config.x_axis):
			return true

		if p_config.panes.size() != _y_axes_per_pane.size():
			return true

		for pane_index in range(p_config.panes.size()):
			var pane_config: TauPaneConfig = p_config.panes[pane_index]
			var pane_snapshots: Dictionary = _y_axes_per_pane[pane_index]
			for axis_id: AxisId in _Y_AXIS_IDS:
				var snapshot: _AxisSnapshot = pane_snapshots.get(axis_id)
				if _has_axis_changed(snapshot, pane_config.get_y_axis_config(axis_id)):
					return true

		return false


	# An axis the user leaves unconfigured gets no snapshot, on the x axis as on
	# a pane edge.
	func save(p_config: TauXYConfig) -> void:
		_x_axis = null
		if p_config.x_axis != null:
			_x_axis = _AxisSnapshot.new(p_config.x_axis)

		_y_axes_per_pane.clear()
		for pane_config: TauPaneConfig in p_config.panes:
			var pane_snapshots: Dictionary[AxisId, _AxisSnapshot] = {}
			for axis_id: AxisId in _Y_AXIS_IDS:
				var axis_config := pane_config.get_y_axis_config(axis_id)
				if axis_config != null:
					pane_snapshots[axis_id] = _AxisSnapshot.new(axis_config)
			_y_axes_per_pane.append(pane_snapshots)


	func reset() -> void:
		_x_axis = null
		_y_axes_per_pane.clear()


	# ==================================================================================
	# PRIVATE
	# ==================================================================================

	static func _has_axis_changed(p_snapshot: _AxisSnapshot, p_config: TauAxisConfig) -> bool:
		if p_config == null:
			return p_snapshot != null
		if p_snapshot == null:
			return true
		return not p_snapshot.matches(p_config)
