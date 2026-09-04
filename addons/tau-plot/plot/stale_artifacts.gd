# Tracks which artifacts a refresh still has to recompute.
#
# An artifact is a value a refresh derives and that can become stale: a domain,
# a layout, a drawing for example. Which artifacts exist, and which one feeds which,
# belong to the plot. This class holds one stale flag per artifact and walks the table
# the plot declares.
#
# Marking an artifact stale marks everything downstream of it, transitively.
class StaleArtifacts extends RefCounted:

	# What an artifact feeds directly, keyed by artifact id.
	# Each value is an array of artifact ids. An id absent from it feeds nothing.
	var _dependents: Dictionary

	# The stale artifact ids, held as a set.
	var _stale: Dictionary[int, bool] = {}

	# What to run instead of raising a flag, keyed by artifact id.
	var _handlers: Dictionary[int, Callable] = {}


	# p_dependents must be acyclic, as the propagation has no cycle guard.
	#
	# The ids of p_initially_stale are flagged as given, without propagation, so
	# the list must name every artifact that starts stale.
	func _init(p_dependents: Dictionary, p_initially_stale: Array[int]) -> void:
		_dependents = p_dependents
		for artifact_id in p_initially_stale:
			_stale[artifact_id] = true


	# Marks p_id and everything under it as due for a recompute.
	func mark(p_id: int) -> void:
		if _handlers.has(p_id):
			_handlers[p_id].call()
		else:
			_stale[p_id] = true

		mark_dependents(p_id)


	# Same, for an artifact that has just been recomputed into a value differing
	# from the one before it. The artifact itself is up to date, what reads it is
	# not.
	func mark_dependents(p_id: int) -> void:
		if not _dependents.has(p_id):
			return
		for dependent: int in _dependents[p_id]:
			mark(dependent)


	func is_stale(p_id: int) -> bool:
		return _stale.has(p_id)


	func clear(p_id: int) -> void:
		_stale.erase(p_id)


	# An artifact whose staleness is held elsewhere registers what to run
	# instead of raising a flag. What it feeds propagates as it does for any
	# other artifact.
	func set_handler(p_id: int, p_handler: Callable) -> void:
		_handlers[p_id] = p_handler
