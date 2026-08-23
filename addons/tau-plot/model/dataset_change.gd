## Describes a logical change applied to a Dataset.
## Encodes what changed (flags), how it changed (type), and the minimal sample
## indices and series ids affected, so a listener can update incrementally.
## Can also represent a batched aggregation of multiple atomic changes.
##
## Instances are produced by Dataset. The same instance reaches every listener
## connected to Dataset.changed, so treat it as read-only.
class DatasetChange extends RefCounted:
	## What changed. Combined as a bitmask in [member flags].
	enum Flags
	{
		## No flag set.
		NONE = 0,
		## X values were appended or modified.
		X_CHANGED = 1,
		## Y values were appended or modified.
		Y_CHANGED = 2,
		## The series list changed, not just the samples in it.
		SERIES_STRUCTURE_CHANGED = 4,
		## A series name changed. Its samples did not.
		SERIES_RENAMED = 8,
		## The ring buffer wrapped and the oldest samples were lost.
		OVERWROTE_OLD_SAMPLES = 16
	}

	## How it changed.
	enum Type
	{
		## One sample was appended to every series in [member series_ids].
		VALUES_APPENDED,
		## Existing values were overwritten in place. The sample count is unchanged.
		VALUES_CHANGED,
		## Cached sample state is stale and must be re-read in full. Emitted on
		## clear, on reset, and on a capacity change, which can truncate samples.
		RESET,
		## A series was added.
		SERIES_ADDED,
		## A series was removed, along with its samples.
		SERIES_REMOVED,
		## The series order changed. [member new_order_series_ids] carries the
		## new order.
		SERIES_REORDERED,
		## A series was renamed.
		SERIES_RENAMED,
		## Aggregation of every change made between begin_batch() and end_batch().
		## A batch that contains a reset reports RESET rather than BATCH.
		BATCH
	}


	## How the dataset changed. Selects which of the fields below are valid.
	var type: Type = Type.VALUES_CHANGED

	## Bitmask of [enum Flags]. Typed as int since a combination of members is
	## not itself an enum value.
	var flags: int = Flags.NONE

	## Number of samples appended.
	## Valid for VALUES_APPENDED, and for BATCH as the sum over the batch.
	## Zero once a reset dominates a batch.
	var appended_count: int = 0

	## Number of oldest samples lost to ring buffer overflow.
	## Valid for VALUES_APPENDED, and for BATCH as the sum over the batch.
	## Zero once a reset dominates a batch.
	var overwritten_count: int = 0

	## Sample count after the change. In SHARED_X mode this is the shared sample
	## count. In PER_SERIES_X mode this is the count of the series in
	## [member series_ids].
	## Valid for VALUES_APPENDED, VALUES_CHANGED, RESET, and SERIES_ADDED.
	## For BATCH it is the maximum over the aggregated changes that carry it,
	## so it is only meaningful when the batch contains one.
	var sample_count_after: int = 0

	## First affected sample index: the start of the modified range for
	## VALUES_CHANGED, of the newly appended range for VALUES_APPENDED.
	## For BATCH the range spans every aggregated change, so it
	## over-approximates: a series can be untouched at an index inside it, and in
	## PER_SERIES_X mode the range covers several per-series index spaces.
	## Zero once a reset dominates a batch.
	var start_sample_index: int = 0

	## One past the last affected sample index. Same validity as
	## [member start_sample_index].
	var end_sample_index_exclusive: int = 0

	## Series affected by the change. Holds every series id for operations that
	## affect all of them (reset, clear, shared-X append, set_shared_x,
	## set_shared_capacity, reorder) and a single id for per-series operations.
	## Empty when the dataset holds no series.
	## For BATCH it is the union over the batch, in no defined order.
	var series_ids: PackedInt64Array = []

	## Series order after the change.
	## Valid for SERIES_REORDERED, and for a batch containing a reorder, where
	## the last one wins.
	var new_order_series_ids: PackedInt64Array = []
