# Dataset

!!! info ""
    **Inherits:** `RefCounted`  
    **Namespace:** [`TauPlot`](tau_plot.md)

Holds all X and Y sample data for one or more named series and notifies the plot of every change.

## Description

`Dataset` is the data model of [`TauPlot`](tau_plot.md). It carries all sample values passed to a plot via
[`TauPlot.plot_xy()`](tau_plot.md#plot_xy). Every mutation
emits the [`changed`](#changed) signal, which the plot uses internally to trigger the minimum
required update. Callers never need to refresh the plot manually after modifying a dataset.

A dataset holds one or more **series**. Each series has a name, a stable integer ID assigned
at creation, and a pair of X and Y ring buffers. The series name appears in the legend. The
series ID is referenced by [`TauXYSeriesBinding`](xy_series_binding.md) to map a series to a
pane, an overlay type, and a Y axis.

A dataset operates in one of two [`Mode`](#mode) values, fixed at construction.

**[`SHARED_X`](#mode)** all series share a single ordered X buffer. Every append adds one X value
and one Y value per series simultaneously. Use this mode when all series are sampled at the
same positions: a bar chart where every group has the same labels, or a time series where
every series records a value at every timestamp.

**[`PER_SERIES_X`](#mode)** each series owns independent X and Y buffers and can have a different
sample count and different X positions. Use this mode for scatter plots where each group of
points has its own coordinates.

X values are either [`NUMERIC`](#xelementtype) (`float`, 64-bit) or [`CATEGORY`](#xelementtype)
(`String`), also fixed at construction.

All buffers are **ring buffers** with a fixed capacity. When a buffer is full, appending a
new sample drops the oldest one. This makes `Dataset` suitable for real-time streaming where
only the most recent N samples are displayed.

### Example

```gdscript
# Two data series and three categories on the shared X axis.
# SHARED_X means both series share the same X labels ("Jan", "Feb", "Mar").
var dataset := TauPlot.Dataset.make_shared_x_categorical(
    PackedStringArray(["Series A", "Series B"]),
    PackedStringArray(["Jan", "Feb", "Mar"]),
    [PackedFloat64Array([1.0, 2.0, 3.0]), PackedFloat64Array([4.0, 5.0, 6.0])]
)

# Time series that keeps only the last 256 samples per sensor.
# New data is pushed in real time, old samples are dropped automatically.
var rt := TauPlot.Dataset.new(Dataset.Mode.SHARED_X, Dataset.XElementType.NUMERIC, 256)
var id_a := rt.add_series("Sensor A")
var id_b := rt.add_series("Sensor B")

# Streaming: call this every time new measurements arrive
rt.append_shared_sample(Time.get_ticks_msec() / 1000.0, PackedFloat64Array([17.0, 42.0]))
```

### Notes

1. **Mode and element type are immutable.** To use a different combination, create a new
`Dataset` and call `plot_xy()` again.

2. **Series IDs are stable.** An ID returned by [`add_series()`](#add_series) stays valid across
reordering and renaming.

3. **Series order controls rendering order.** The visual order of series in bars, the legend,
and stacking is determined by series position in the internal array.
[`reorder_series()`](#reorder_series) changes that position.

4. **[`SHARED_X`](#mode) add-series constraint.** [`add_series()`](#add_series) can only be called before
any samples exist. Once samples are present, use
[`add_series_with_initial_y()`](#add_series_with_initial_y) to align the new Y buffer with
the existing shared X buffer.

5. **Logical sample indices convention.** All methods that accept a `p_logical_sample_index` parameter use the same convention: index `0` is the **oldest** sample currently in the buffer, and `get_shared_sample_count() - 1` (or `get_series_sample_count() - 1` in `PER_SERIES_X` mode) is the **most recently appended** one. Indices are stable as long as no new sample is appended. When the ring buffer is full and a new sample is appended, every logical index shifts by one: the sample that was at index `1` is now at index `0`, and the new sample occupies the last position. Accessing an out-of-range index logs an error.

## Enums

### `Mode`

Controls how X buffers are organized across series.

| Value | Meaning |
|---|---|
| `SHARED_X` | All series share one X buffer. Sample index `i` maps to the same X value for every series. |
| `PER_SERIES_X` | Each series owns independent X and Y buffers with its own sample count and X positions. |

### `XElementType`

Controls the type stored in X buffers.

| Value | Meaning |
|---|---|
| `NUMERIC` | X values are `float` (64-bit). Use for continuous numeric axes. |
| `CATEGORY` | X values are `String`. Use for categorical axes such as bar chart group labels. |

## Signals

### `changed()`

```gdscript
changed(p_change: DatasetChange)
```

Emitted after every mutation, or once per [`begin_batch()`](#begin_batch) /
[`end_batch()`](#end_batch) block. The plot connects to this signal internally and uses it
to decide whether to redraw or recompute the domain. Not emitted if a batch closes with no
actual data change.

## Constructor

### `new()`

```gdscript
Dataset.new(
	p_mode: Mode, 
	p_x_element_type: XElementType,
	p_shared_capacity: int = 1024
) -> Dataset
```

Creates an empty dataset with no series and no samples.

**Parameters**

* `p_mode: `[`Mode`](#mode) [`SHARED_X`](#mode) or [`PER_SERIES_X`](#mode). Fixed for the lifetime of the object.
* `p_x_element_type: `[`XElementType`](#xelementtype) [`NUMERIC`](#xelementtype) or [`CATEGORY`](#xelementtype). Fixed for the lifetime of the object.
* `p_shared_capacity: int` Ring buffer capacity. In [`SHARED_X`](#mode) mode, all X and Y buffers use this value. In [`PER_SERIES_X`](#mode) mode, per-series capacity is set individually in [`add_series()`](#add_series). Values below `1` are clamped to `1`. Default: `1024`.

---

### `make_shared_x_categorical()`

```gdscript
make_shared_x_categorical(
    p_series_names: PackedStringArray,
    p_x: PackedStringArray,
    p_y_by_series: Array[PackedFloat64Array],
    p_capacity: int = -1
) -> Dataset
```

Convenience constructor that creates a [`SHARED_X`](#mode) / [`CATEGORY`](#xelementtype) dataset
from bulk arrays. Returns `null` on error.

**Parameters**

* `p_series_names: PackedStringArray` One name per series. Must not be empty.
* `p_x: PackedStringArray` Category labels for the shared X axis.
* `p_y_by_series: Array[PackedFloat64Array]` One `PackedFloat64Array` per series. Each inner array must have exactly `p_x.size()` values.
* `p_capacity: int` Ring buffer capacity. Pass `-1` (default) to set it equal to `p_x.size()`, which is the right choice for static datasets. Pass a larger value to leave room for future appends.

**Array size constraints**

* `p_y_by_series.size()` must equal `p_series_names.size()`.
* Every `p_y_by_series[i].size()` must equal `p_x.size()`.

---

### `make_shared_x_continuous()`

```gdscript
make_shared_x_continuous(
    p_series_names: PackedStringArray,
    p_x: PackedFloat64Array,
    p_y_by_series: Array[PackedFloat64Array],
    p_capacity: int = -1
) -> Dataset
```

Convenience constructor that creates a [`SHARED_X`](#mode) / [`NUMERIC`](#xelementtype) dataset
from bulk arrays. Returns `null` on error.

**Parameters**

* `p_series_names: PackedStringArray` One name per series. Must not be empty.
* `p_x: PackedFloat64Array` Numeric X values for the shared axis.
* `p_y_by_series: Array[PackedFloat64Array]` One `PackedFloat64Array` per series. Each inner array must have exactly `p_x.size()` values.
* `p_capacity: int` Ring buffer capacity. Pass `-1` (default) to set it equal to `p_x.size()`, which is the right choice for static datasets. Pass a larger value to leave room for future appends.

**Array size constraints**

* `p_y_by_series.size()` must equal `p_series_names.size()`.
* Every `p_y_by_series[i].size()` must equal `p_x.size()`.

---

### `make_per_series_x_continuous()`

```gdscript
make_per_series_x_continuous(
    p_series_names: PackedStringArray,
    p_x_by_series: Array[PackedFloat64Array],
    p_y_by_series: Array[PackedFloat64Array],
    p_capacity_by_series: PackedInt32Array = PackedInt32Array()
) -> Dataset
```

Convenience constructor that creates a [`PER_SERIES_X`](#mode) / [`NUMERIC`](#xelementtype) dataset
from bulk arrays. Each series has its own X and Y arrays and may have a different sample
count. Returns `null` on error.

**Parameters**

* `p_series_names: PackedStringArray` One name per series. Must not be empty.
* `p_x_by_series: Array[PackedFloat64Array]` One X array per series.
* `p_y_by_series: Array[PackedFloat64Array]` One Y array per series. Each inner array must have the same size as the corresponding X array.
* `p_capacity_by_series: PackedInt32Array` Optional per-series ring buffer capacities. Pass an empty array (default) to set each series capacity equal to its initial sample count. When provided, must have exactly `p_series_names.size()` entries, and each value is clamped to a minimum of `1`.

**Array size constraints**

* `p_x_by_series.size()` must equal `p_series_names.size()`.
* `p_y_by_series.size()` must equal `p_series_names.size()`.
* For every series `i`, `p_y_by_series[i].size()` must equal `p_x_by_series[i].size()`.
* If `p_capacity_by_series` is non-empty, its size must equal `p_series_names.size()`.

## Methods

### Introspection

#### get_mode()

```gdscript
get_mode() -> Mode
```

Returns the [`Mode`](#mode) set at construction.

---

#### get_x_element_type()

```gdscript
get_x_element_type() -> XElementType
```

Returns the [`XElementType`](#xelementtype) set at construction.

---

#### is_batching()

```gdscript
is_batching() -> bool
```

Returns `true` if at least one batch is currently open.

---

### Series lifetime

#### add_series()

```gdscript
add_series(p_series_name: String, p_capacity: int = 1024) -> int
```

Registers a new empty series to the dataset and returns a stable ID valid across reordering and renaming.

**Parameters**

* `p_series_name: String` Display name shown in the legend.
* `p_capacity: int` Ring buffer capacity. Only used in [`PER_SERIES_X`](#mode) mode. Values below `1` are clamped to `1`. Default: `1024`.

**Notes**

* In [`SHARED_X`](#mode) mode, calling this after samples exist is an error. Use [`add_series_with_initial_y()`](#add_series_with_initial_y) instead.
* Returns `-1` and logs an error on failure.

---

#### add_series_with_initial_y()

```gdscript
add_series_with_initial_y(p_series_name: String, p_capacity: int, p_initial_y_values: PackedFloat64Array) -> int
```

Registers a new series in [`SHARED_X`](#mode) mode when samples already exist. The initial Y
array fills the new series buffer so it aligns with the existing shared X buffer.

**Parameters**

* `p_series_name: String` Display name shown in the legend.
* `p_capacity: int` Ring buffer capacity. Values below `1` are clamped to `1`.
* `p_initial_y_values: PackedFloat64Array` Must have exactly [`get_shared_sample_count()`](#get_shared_sample_count) values. Pass an empty array if the dataset has no samples yet (equivalent to [`add_series()`](#add_series) in that case).

Returns `-1` and logs an error on failure.

---

#### remove_series()

```gdscript
remove_series(p_series_id: int) -> void
```

Removes the series and its buffers. Emits [`changed`](#changed). Logs an error if the ID is unknown.

---

#### has_series()

```gdscript
has_series(p_series_id: int) -> bool
```

Returns `true` if a series with the given ID exists.

---

#### get_series_count()

```gdscript
get_series_count() -> int
```

Returns the number of series currently registered.

---

#### get_series_ids()

```gdscript
get_series_ids() -> PackedInt64Array
```

Returns a copy of the series ID array in current visual order.

---

#### get_series_names()

```gdscript
get_series_names() -> PackedStringArray
```

Returns a copy of the series name array in current visual order. Index `i` corresponds to
index `i` in [`get_series_ids()`](#get_series_ids).

---

#### get_series_name()

```gdscript
get_series_name(p_series_id: int) -> String
```

Returns the name of the series with the given ID. Returns an empty string if the ID is unknown.

---

#### set_series_name()

```gdscript
set_series_name(p_series_id: int, p_name: String) -> void
```

Renames the series. The updated name appears in the legend on the next plot refresh. Emits
[`changed`](#changed). Logs an error if the ID is unknown.

---

#### get_series_index_by_id()

```gdscript
get_series_index_by_id(p_series_id: int) -> int
```

Returns the zero-based position of the series in the current visual order. Returns `-1` if
the ID is unknown.

---

#### get_series_id_by_index()

```gdscript
get_series_id_by_index(p_series_index: int) -> int
```

Returns the series ID at the given visual position. Returns `-1` if the index is out of range.

---

### Series order

#### reorder_series()

```gdscript
reorder_series(p_new_order_series_ids: PackedInt64Array) -> void
```

Reorders series to match the given ID sequence. The array must contain every existing series
ID exactly once. Affects the legend order and bar rendering order. Emits [`changed`](#changed).

---

### Capacity

#### get_shared_capacity()

```gdscript
get_shared_capacity() -> int
```

Returns the shared ring buffer capacity. Only valid in [`SHARED_X`](#mode) mode.

---

#### set_shared_capacity()

```gdscript
set_shared_capacity(p_capacity: int) -> void
```

Resizes all X and Y buffers to the new shared capacity. Values below `1` are clamped to `1`.
If the new capacity is smaller than the current sample count, the oldest samples are dropped.
Only valid in [`SHARED_X`](#mode) mode. Emits [`changed`](#changed).

---

#### get_series_capacity()

```gdscript
get_series_capacity(p_series_id: int) -> int
```

Returns the ring buffer capacity for the given series. In [`SHARED_X`](#mode) mode, returns the shared
capacity. In [`PER_SERIES_X`](#mode) mode, returns the per-series capacity.

---

#### set_series_capacity()

```gdscript
set_series_capacity(p_series_id: int, p_capacity: int) -> void
```

Resizes the X and Y buffers of the given series. Values below `1` are clamped to `1`. If the
new capacity is smaller than the current sample count, the oldest samples are dropped. Only
valid in [`PER_SERIES_X`](#mode) mode. Emits [`changed`](#changed).

---

### Sample counts

#### get_shared_sample_count()

```gdscript
get_shared_sample_count() -> int
```

Returns the number of samples currently stored in the shared X buffer. Only valid in [`SHARED_X`](#mode)
mode. Logs an error and returns `0` in [`PER_SERIES_X`](#mode) mode.

---

#### get_series_sample_count()

```gdscript
get_series_sample_count(p_series_id: int) -> int
```

Returns the number of samples for the given series. In [`SHARED_X`](#mode) mode all series have the same
count. In [`PER_SERIES_X`](#mode) mode each series may differ.

---

### Appending samples

#### append_shared_sample()

```gdscript
append_shared_sample(p_x: Variant, p_y_values: PackedFloat64Array) -> void
```

Appends one sample to the shared X buffer and one Y value to every series Y buffer. This is the
primary write method for [`SHARED_X`](#mode) streaming datasets. If the buffer is full, the oldest sample is dropped. 
Only valid in [`SHARED_X`](#mode) mode.

`p_x` must be a `String` when [`XElementType`](#xelementtype) is [`CATEGORY`](#xelementtype), and a `float` when it is [`NUMERIC`](#xelementtype).
`p_y_values` must contain exactly one value per registered series.

---

#### append_sample_to_one_series()

```gdscript
append_sample_to_one_series(p_series_id: int, p_x: Variant, p_y: float) -> void
```

Appends one X/Y sample to the buffers of the specified series. This is the primary write method
for [`PER_SERIES_X`](#mode) streaming datasets. If the buffer is full, the oldest sample is dropped.
Only valid in [`PER_SERIES_X`](#mode) mode.

`p_x` must be a `float` (only [`NUMERIC`](#xelementtype) is supported in [`PER_SERIES_X`](#mode) mode).

---

### Reading and writing individual values

#### get_shared_x()

```gdscript
get_shared_x(p_logical_sample_index: int) -> Variant
```

Returns the X value at the given index from the shared X buffer. Index `0` is the oldest sample in the buffer, `count - 1` is the most recent. Returns `null` in
[`PER_SERIES_X`](#mode) mode. The return type is `String` for [`CATEGORY`](#xelementtype), `float` for [`NUMERIC`](#xelementtype).

---

#### set_shared_x()

```gdscript
set_shared_x(p_logical_sample_index: int, p_x: Variant) -> void
```

Overwrites the X value at the given index in the shared X buffer. Index `0` is the oldest sample in the buffer, `count - 1` is the most recent. Only valid in [`SHARED_X`](#mode)
mode. Emits [`changed`](#changed) for all series.

---

#### get_series_x()

```gdscript
get_series_x(p_series_id: int, p_logical_sample_index: int) -> Variant
```

Returns the X value at the given index for the specified series. Index `0` is the oldest sample in the buffer, `count - 1` is the most recent. Returns `null` in [`SHARED_X`](#mode)
mode or if the ID is unknown. The return type matches the [`XElementType`](#xelementtype) set at construction.

---

#### set_series_x()

```gdscript
set_series_x(p_series_id: int, p_logical_sample_index: int, p_x: Variant) -> void
```

Overwrites the X value at the given index for the specified series. Index `0` is the oldest sample in the buffer, `count - 1` is the most recent. Only valid in
[`PER_SERIES_X`](#mode) mode. Emits [`changed`](#changed) for the affected series.

---

#### get_series_y()

```gdscript
get_series_y(p_series_id: int, p_logical_sample_index: int) -> float
```

Returns the Y value at the given index for the specified series. Index `0` is the oldest sample in the buffer, `count - 1` is the most recent. Returns `0.0` if the ID is unknown.

---

#### set_series_y()

```gdscript
set_series_y(p_series_id: int, p_logical_sample_index: int, p_y: float) -> void
```

Overwrites the Y value at the given index for the specified series. Index `0` is the oldest sample in the buffer, `count - 1` is the most recent. Emits [`changed`](#changed)
for the affected series.

---

#### set_series_y_slice()

```gdscript
set_series_y_slice(p_series_id: int, p_start_index: int, p_values: PackedFloat64Array) -> void
```

Overwrites a contiguous range of Y values starting at `p_start_index`. Writes as many values as
fit within the buffer from that index forward. Not emitted if no values are written. Emits
[`changed`](#changed) for the affected series.

---

### Batch updates

#### begin_batch()

```gdscript
begin_batch() -> void
```

Opens a batch. All mutations accumulate into a single [`changed`](#changed) emission instead
of firing once per mutation. Batches nest: each call must be matched by [`end_batch()`](#end_batch).

---

#### end_batch()

```gdscript
end_batch() -> void
```

Closes the current batch level. At the outermost level, emits [`changed`](#changed) once with
the aggregated change. If no data changed, the signal is not emitted.

Calling this without a matching [`begin_batch()`](#begin_batch) logs an error.

---

### Clearing data

#### clear_samples()

```gdscript
clear_samples() -> void
```

Removes all samples from all buffers. Series registrations are preserved. Emits [`changed`](#changed).

---

#### reset()

```gdscript
reset() -> void
```

Removes all series and all samples. The shared X buffer is recreated in [`SHARED_X`](#mode) mode. Emits
[`changed`](#changed) with the series IDs that existed before the reset.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Calls `plot_xy()` to attach a dataset and connects to `changed` internally.
* [`TauXYSeriesBinding`](xy_series_binding.md) Maps a series ID to a pane, overlay type, and Y axis. Passed to `plot_xy()` alongside the dataset.
