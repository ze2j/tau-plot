# Describes a logical change applied to a Dataset.
# Encodes what changed (flags), how it changed (type), and the minimal indices / series ids affected.
# Can also represent a batched aggregation of multiple atomic changes.
class DatasetChange extends RefCounted:
	# What changed.
	enum Flags
	{
		X_CHANGED = 1,
		Y_CHANGED = 2,
		SERIES_STRUCTURE_CHANGED = 4, # Series added, removed, or reordered
		SERIES_RENAMED = 8,
		OVERWROTE_OLD_SAMPLES = 16
	}

	# How it changed.
	enum Type
	{
		VALUES_APPENDED,
		VALUES_CHANGED,
		RESET,
		SERIES_ADDED,
		SERIES_REMOVED,
		SERIES_REORDERED,
		SERIES_RENAMED,
		BATCH
	}


	var type: Type = Type.VALUES_CHANGED
	var flags: int = 0

	# Number of samples appended in this change.
	# Valid when type == VALUES_APPENDED or type == BATCH (aggregated).
	var appended_count: int = 0

	# Number of oldest samples dropped (ring buffer overflow) by this change.
	# Valid when type == VALUES_APPENDED or type == BATCH (aggregated).
	var dropped_count: int = 0

	# Total sample count after this change was applied.
	# Valid when type == VALUES_APPENDED, VALUES_CHANGED, SERIES_ADDED, or BATCH.
	var count_after: int = 0

	# Logical index range [start_index, end_index_exclusive) of affected samples.
	# Valid when type == VALUES_CHANGED or type == VALUES_APPENDED.
	# For VALUES_CHANGED: the range of modified samples.
	# For VALUES_APPENDED: the range of newly appended samples.
	# Also valid for BATCH when the batch contains VALUES_CHANGED or VALUES_APPENDED
	# changes (the range is the union of all affected indices).
	var start_index: int = 0
	var end_index_exclusive: int = 0

	# Series affected by this change. Always populated.
	# Contains all series ids for operations that affect every series (RESET,
	# SHARED_X appends, set_shared_x, reorder). Contains a single id for
	# per-series operations (per-series append, set_series_y, SERIES_ADDED,
	# SERIES_REMOVED, SERIES_RENAMED).
	var series_ids: PackedInt64Array = []

	# New series order after a SERIES_REORDERED change.
	# Valid only when type == SERIES_REORDERED or when a BATCH contains a reorder.
	var new_order_series_ids: PackedInt64Array = []
