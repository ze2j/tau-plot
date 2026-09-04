# Change detection for the resources the user gives to the plot.
#
# A tracker monitors one resource provided by the user, every property of it, and
# reports the changes through the react callback.
#
# Detection runs during update(), and the kind of the tracked resource makes it
# slightly different:
# - a style resource emits the changed signal and the tracker listens to it. During
# update() the resource is checked only if the signal has been emitted. Otherwise the
# resource is considered unchanged.
# - a config resource does not emit the changed signal. So during update() the check is
# performed unconditionally.
#
# A resource the user swapped for another instance is caught either way, as read is
# called on every update.
#
# A tracked resource must implement these methods:
#
#	make_snapshot() -> Object
#		Returns a copy of the resource, independent of it as the user goes on
#		mutating the original.
#
#	is_equal_to(p_other) -> bool
#		True when both resources are equal, false otherwise. p_other is null until a
#		first snapshot is taken, which counts as not equal.
#
#	has_layout_affecting_change(p_other) -> bool
#		Called only when is_equal_to() returned false.
#		True when the change should trigger a layout pass, false when a redraw is enough.
#
# Notes:
# - This contract relies on duck typing instead of polymorphism for now.
# - The tracking of config resources will be aligned to the style one in the future.
# - Both are breaking changes and will be addressed by https://github.com/ze2j/tau-plot/issues/26
@abstract class Tracker extends RefCounted:

	# Impact of a change.
	enum Change
	{
		# Nothing changed, so no impact.
		NONE,
		# A redraw is required.
		VISUAL,
		# A new layout pass is required.
		LAYOUT,
	}

	var _read: Callable
	var _react: Callable

	# The tracked resource.
	var _ref = null
	# The snapshot, taken at the last reported change.
	var _snapshot = null

	# If true, the next update reports a change whatever is_equal_to() returns.
	var _forced := false

	#	read: func() -> Object
	#		Returns the tracked resource as it stands now, null when the user cleared it.
	#	react: func(p_change: Change) -> void
	#		Called when a change has been detected. NONE is never passed.
	func _init(p_read: Callable, p_react: Callable) -> void:
		_read = p_read
		_react = p_react


	# Reads the resource and calls the react callback when something changed.
	func update() -> void:
		var change := _detect_change()
		if change != Change.NONE:
			_react.call(change)


	# Makes the next update report a change even when the user resource did not
	# change. This is useful for theme changes, which must force the resolution of
	# the styles even though the user styles were not touched.
	func force_change() -> void:
		_forced = true


	# Stops tracking the resource.
	func release() -> void:
		_watch(null)


	# ==================================================================================
	# PRIVATE
	# ==================================================================================

	# Tracks p_resource from now on.
	@abstract func _watch(p_resource) -> void


	# True when the resource must be checked on this update, false otherwise.
	# Called once per update.
	@abstract func _is_check_requested() -> bool


	# Returns what changed on the resource since the last reported change.
	func _detect_change() -> Change:
		var current = _read.call()
		var check_requested := _is_check_requested()

		if current != _ref:
			_watch(current)
		elif not _forced and not check_requested:
			return Change.NONE

		var forced := _forced
		_forced = false

		if current == null:
			# Losing the resource loses its whole contribution, layout included.
			# forced covers the first update of a plot the user gave no resource at
			# all, which the layer underneath still feeds.
			if _snapshot == null and not forced:
				return Change.NONE
			_snapshot = null
			return Change.LAYOUT

		if not forced and current.is_equal_to(_snapshot):
			return Change.NONE

		var change := Change.LAYOUT if current.has_layout_affecting_change(_snapshot) else Change.VISUAL
		_snapshot = current.make_snapshot()
		return change


# Tracks a resource that emits changed when it is mutated. Only the resources
# the user touched since the last update are checked.
class NotifiedTracker extends Tracker:

	var _wake_up: Callable

	# If true, changed has been emitted and no check ran since. True to start with,
	# as a snapshot must be created on the first update.
	var _check_requested := true

	#	read: func() -> Object
	#		Returns the tracked resource as it stands now, null when the user cleared it.
	#	react: func(p_change: Change) -> void
	#		Called when a change has been detected. NONE is never passed.
	#	wake_up: func() -> void
	#		Called to schedule a refresh when the tracked resource signals a change.
	func _init(p_read: Callable, p_react: Callable, p_wake_up: Callable) -> void:
		super(p_read, p_react)
		_wake_up = p_wake_up


	func _watch(p_resource) -> void:
		if _ref != null:
			_ref.changed.disconnect(_on_resource_changed)
		_ref = p_resource
		if _ref != null:
			_ref.changed.connect(_on_resource_changed)


	# The request is consumed so that no checks are performed until the changed signal is emitted again.
	func _is_check_requested() -> bool:
		var requested := _check_requested
		_check_requested = false
		return requested


	func _on_resource_changed() -> void:
		_check_requested = true
		_wake_up.call()


# Tracks a resource that emits nothing, checked on every update.
class PolledTracker extends Tracker:

	func _watch(p_resource) -> void:
		_ref = p_resource


	# The check is performed on every update as this tracker does not listen to the changed signal.
	func _is_check_requested() -> bool:
		return true
