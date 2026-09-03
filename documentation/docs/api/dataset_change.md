# DatasetChange

!!! info ""
    **Inherits:** `RefCounted`  
    **Namespace:** [`TauPlot`](tau_plot.md)

Describes one change applied to a [`Dataset`](dataset.md), carried by its [`changed`](dataset.md#changed) signal.

## Description

`DatasetChange` is the payload of [`Dataset.changed`](dataset.md#changed). The dataset builds one for every mutation and hands it to every connected listener. Treat it as read only.

The payload describes a change in three parts.

[`type`](#type) says how the dataset changed, and selects which of the other fields carry a meaningful value. A field the type does not carry keeps its initial value, so a handler that reads it gets `0` or an empty array rather than stale data from a previous change.

[`flags`](#flags) is a bitmask of [`Flags`](#flags-enum) values saying what changed. It answers whether X values, Y values, or the series list changed without matching on the type, which is what a listener that only redraws needs.

The seven remaining fields narrow the change down to the series it touched and the range of samples inside them, so a listener can update incrementally instead of re-reading the whole dataset.

Sample indices are **logical indices**: `0` is the oldest sample still held and the highest is the newest. When a ring buffer wraps, every logical index shifts by one and the emission carries [`OVERWROTE_OLD_SAMPLES`](#flags-enum).

Mutations made between [`Dataset.begin_batch()`](dataset.md#begin_batch) and [`Dataset.end_batch()`](dataset.md#end_batch) produce a single emission of type [`BATCH`](#type-enum) instead of one per mutation. The aggregation is per field: [`flags`](#flags) is the union of the flags of every change in the block, [`appended_count`](#appended_count) and [`overwritten_count`](#overwritten_count) are sums, [`sample_count_after`](#sample_count_after) is the maximum, [`start_sample_index`](#start_sample_index) and [`end_sample_index_exclusive`](#end_sample_index_exclusive) span every change, [`series_ids`](#series_ids) is the union, and [`new_order_series_ids`](#new_order_series_ids) keeps the last reorder of the block. A block containing a reset reports [`RESET`](#type-enum) rather than [`BATCH`](#type-enum), because the listener has to re-read everything either way.

### Example

```gdscript
func _ready() -> void:
	var dataset := TauPlot.Dataset.new(TauPlot.Dataset.Mode.SHARED_X, TauPlot.Dataset.XElementType.NUMERIC)
	dataset.changed.connect(_on_dataset_changed)


func _on_dataset_changed(p_change: TauPlot.DatasetChange) -> void:
	if p_change.type == TauPlot.DatasetChange.Type.RESET:
		_reread_all_series()
		return

	# Every other type carries a range, so only the touched samples are read.
	for series_id in p_change.series_ids:
		_reread_range(series_id, p_change.start_sample_index, p_change.end_sample_index_exclusive)
```

### Notes

1. **The instance is shared.** Every listener connected to [`changed`](dataset.md#changed) receives the same object.

2. **Test `flags` with a bitwise and.** `flags` holds a combination of [`Flags`](#flags-enum) values, so `p_change.flags & TauPlot.DatasetChange.Flags.Y_CHANGED != 0` is the test. Comparing it to a single value only matches when that value is the only one set.

3. **A batched range over-approximates.** [`start_sample_index`](#start_sample_index) and [`end_sample_index_exclusive`](#end_sample_index_exclusive) span every aggregated change, so a series in [`series_ids`](#series_ids) can be untouched at an index inside the range. In [`PER_SERIES_X`](dataset.md#mode) mode the range also covers several per-series index spaces at once.

4. **An empty batch emits nothing.** [`Dataset.end_batch()`](dataset.md#end_batch) skips the emission when no mutation inside the block set a flag.

## Enums

### `Flags` { #flags-enum }

Identifies what changed. Combined as a bitmask in [`flags`](#flags), so each value is a distinct power of two.

| Value | Meaning |
|---|---|
| `NONE` | `0`. No flag set. |
| `X_CHANGED` | `1`. X values were appended or overwritten. |
| `Y_CHANGED` | `2`. Y values were appended or overwritten. |
| `SERIES_STRUCTURE_CHANGED` | `4`. The series list changed, by addition, removal, or reordering. |
| `SERIES_RENAMED` | `8`. A series name changed. Its samples did not. |
| `OVERWROTE_OLD_SAMPLES` | `16`. A ring buffer reached its capacity and dropped its oldest samples, shifting every logical index. |

---

### `Type` { #type-enum }

Identifies how the dataset changed, and selects which fields of the payload are valid.

| Value | Meaning |
|---|---|
| `VALUES_APPENDED` | Samples were appended to every series in [`series_ids`](#series_ids). |
| `VALUES_CHANGED` | Existing values were overwritten in place. The sample count is unchanged. |
| `RESET` | Cached sample state is stale and must be re-read in full. Emitted by [`clear_samples()`](dataset.md#clear_samples), by [`reset()`](dataset.md#reset), and by a capacity change, which can truncate samples. |
| `SERIES_ADDED` | A series was added. [`series_ids`](#series_ids) holds its ID alone. |
| `SERIES_REMOVED` | A series was removed, along with its samples. |
| `SERIES_REORDERED` | The series order changed. [`new_order_series_ids`](#new_order_series_ids) carries the new order. |
| `SERIES_RENAMED` | A series was renamed. |
| `BATCH` | Aggregation of every change made between [`begin_batch()`](dataset.md#begin_batch) and [`end_batch()`](dataset.md#end_batch). |

## Properties

### type

`type`: [`Type`](#type-enum)

How the dataset changed. Default is [`VALUES_CHANGED`](#type-enum).

Selects which of the other fields carry a meaningful value. Each property below states the types it is valid for.

---

### flags

`flags`: `int`

Bitmask of [`Flags`](#flags-enum) values saying what changed. Default is [`NONE`](#flags-enum).

Valid for every [`type`](#type). Typed as `int` rather than as the enum, since a combination of members is not itself an enum value.

---

### appended_count

`appended_count`: `int`

Number of samples appended to each series in [`series_ids`](#series_ids). Default is `0`.

Valid for [`VALUES_APPENDED`](#type-enum), and for [`BATCH`](#type-enum) as the sum over the block. Back to `0` once a reset dominates a batch.

---

### overwritten_count

`overwritten_count`: `int`

Number of oldest samples dropped by a ring buffer that reached its capacity during the change. Default is `0`.

Valid for [`VALUES_APPENDED`](#type-enum), and for [`BATCH`](#type-enum) as the sum over the block. A non-zero value comes with the [`OVERWROTE_OLD_SAMPLES`](#flags-enum) flag and means every logical index held by the listener has shifted down by this amount. Back to `0` once a reset dominates a batch.

---

### sample_count_after

`sample_count_after`: `int`

Sample count once the change is applied. Default is `0`.

In [`SHARED_X`](dataset.md#mode) mode this is the shared sample count. In [`PER_SERIES_X`](dataset.md#mode) mode this is the count of the series in [`series_ids`](#series_ids).

Valid for [`VALUES_APPENDED`](#type-enum), [`VALUES_CHANGED`](#type-enum), [`RESET`](#type-enum), and [`SERIES_ADDED`](#type-enum). For [`BATCH`](#type-enum) it is the maximum over the aggregated changes that carry it, so it is only meaningful when the block contains one.

---

### start_sample_index

`start_sample_index`: `int`

First affected logical sample index. Default is `0`.

Valid for [`VALUES_CHANGED`](#type-enum), where it starts the modified range, and for [`VALUES_APPENDED`](#type-enum), where it starts the newly appended range. For [`BATCH`](#type-enum) the range spans every aggregated change, see [note 3](#notes). Back to `0` once a reset dominates a batch.

---

### end_sample_index_exclusive

`end_sample_index_exclusive`: `int`

One past the last affected logical sample index. Default is `0`.

Same validity as [`start_sample_index`](#start_sample_index). An empty range has both fields equal.

---

### series_ids

`series_ids`: `PackedInt64Array`

Series affected by the change, by [series ID](dataset.md#add_series). Default is an empty array.

Valid for every [`type`](#type). Holds every series ID for operations that affect all of them, which are [`reset()`](dataset.md#reset), [`clear_samples()`](dataset.md#clear_samples), a shared-X append, [`set_shared_x()`](dataset.md#set_shared_x), [`set_shared_capacity()`](dataset.md#set_shared_capacity), and [`reorder_series()`](dataset.md#reorder_series). Holds a single ID for per-series operations. Empty when the dataset holds no series. For [`BATCH`](#type-enum) it is the union over the block, in no defined order.

---

### new_order_series_ids

`new_order_series_ids`: `PackedInt64Array`

Series IDs in their order after the change. Default is an empty array.

Valid for [`SERIES_REORDERED`](#type-enum), and for a [`BATCH`](#type-enum) containing a reorder, where the last one wins. Empty for every other type.

## Related Classes

* [`Dataset`](dataset.md) The data model. Produces every `DatasetChange` and emits it through [`changed`](dataset.md#changed).
* [`TauPlot`](tau_plot.md) The plot node. Connects to [`Dataset.changed`](dataset.md#changed) internally and decides from the payload whether to redraw or recompute the domain.