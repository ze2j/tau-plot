# Change detection for one resource the plot reads but does not own.
#
# The resource is compared against a snapshot of itself, taken the last time a
# change was reported, and the report says whether the layout has to be
# recomputed or only repainted.
#
# A resource that emits `changed` is compared only once it has said something,
# so the cost follows what the user touched rather than the number of tracked
# resources. One that stays silent is compared on every poll.
#
# A tracked resource declares `make_snapshot()`, `is_equal_to()` and
# `has_layout_affecting_change()`. No base class declares the three together,
# so the resource is held untyped and those calls are resolved at runtime.
class Tracked extends RefCounted:

	enum Change
	{
		UNCHANGED,
		VISUAL,		# Content changed, none of it read by the layout.
		LAYOUT,		# Content the layout reads changed.
	}

	# Reads the tracked resource. Read again on every poll rather than stored,
	# since the user may assign a different one at any time.
	var _read: Callable
	# Takes the Change a poll reported, unless that Change is UNCHANGED.
	var _react: Callable
	# Runs when the resource announces a mutation, to schedule the poll that
	# will pick it up.
	var _wake_up: Callable
	var _announces_change: bool

	# The resource the snapshot was taken from, and the snapshot itself.
	var _ref = null
	var _snapshot = null

	# A comparison is due. Raised by the changed signal, and never lowered for
	# a resource that emits none.
	var _compare_due := true
	# The next poll reports a change whatever the comparison finds.
	var _forced := false


	# Tracks a resource that emits `changed` when it is mutated.
	static func announced(p_read: Callable, p_react: Callable, p_wake_up: Callable) -> Tracked:
		return Tracked.new(p_read, p_react, p_wake_up, true)


	# Tracks a resource that announces nothing, which is compared on every poll.
	static func silent(p_read: Callable, p_react: Callable) -> Tracked:
		return Tracked.new(p_read, p_react, Callable(), false)


	func _init(p_read: Callable, p_react: Callable, p_wake_up: Callable, p_announces_change: bool) -> void:
		_read = p_read
		_react = p_react
		_wake_up = p_wake_up
		_announces_change = p_announces_change


	# Polls the resource and hands over what changed.
	func update() -> void:
		var change := poll()
		if change != Change.UNCHANGED:
			_react.call(change)


	# Reports what changed on the resource since the last change reported.
	func poll() -> Change:
		var current = _read.call()

		if current != _ref:
			_watch(current)
		elif not _forced and not _compare_due:
			return Change.UNCHANGED

		_compare_due = not _announces_change
		var forced := _forced
		_forced = false

		if current == null:
			# Taking the resource away takes its whole contribution with it,
			# layout included. Forced covers the first resolve of a plot the
			# user gave no resource at all, which the layer underneath still
			# feeds.
			if _snapshot == null and not forced:
				return Change.UNCHANGED
			_snapshot = null
			return Change.LAYOUT

		if not forced and current.is_equal_to(_snapshot):
			return Change.UNCHANGED

		var change := Change.LAYOUT if current.has_layout_affecting_change(_snapshot) else Change.VISUAL
		_snapshot = current.make_snapshot()
		return change


	# Makes the next poll report a change even when the resource itself held
	# still. For the layers underneath it, which it knows nothing about.
	func force_change() -> void:
		_forced = true


	# Drops the subscription. A tracked resource belongs to the user and
	# outlives the plot that watched it.
	func release() -> void:
		_watch(null)


	# ==================================================================================
	# PRIVATE
	# ==================================================================================

	# Moves the subscription over to p_resource.
	func _watch(p_resource) -> void:
		if _ref != null and _announces_change:
			_ref.changed.disconnect(_on_resource_changed)
		_ref = p_resource
		if _ref != null and _announces_change:
			_ref.changed.connect(_on_resource_changed)


	func _on_resource_changed() -> void:
		_compare_due = true
		_wake_up.call()
