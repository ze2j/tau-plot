# Int32Buffer

!!! info ""
    **Inherits:** `RefCounted`  
    **Namespace:** [`TauPlot`](tau_plot.md)

Ring buffer that stores `int` values (32-bit) with a fixed capacity.

## Description

`Int32Buffer` stores a sequence of `int` values (32-bit) in a ring buffer of fixed capacity. When the buffer is full, appending a new value drops the oldest one. 

All read and write operations use **logical indices**. Index `0` refers to the oldest value currently in the buffer. Index [`size()`](#size)` - 1` refers to the most recently appended one. Logical indices shift when the buffer wraps: after a new value is appended into a full buffer, every index decreases by one.

The buffer is pre-allocated at construction and does not resize unless [`set_capacity()`](#set_capacity) is called explicitly.

### Example

```gdscript
# Ring buffer with a capacity of 128 integers (32-bit).
var shapes := TauPlot.Int32Buffer.new(128)

# Append one integer
shapes.append_value(42)
```

### Notes

1. **Default value fills unused slots.** At construction and after [`clear()`](#clear), every slot is filled with `p_default_value`. Default: `-1`, which is the conventional sentinel meaning "unset" in contexts such as [`ScatterVisualAttributes.shape_buffer`](scatter_visual_attributes.md#shape_buffer).

2. **Out-of-range access logs an error.** [`get_value()`](#get_value), [`set_value()`](#set_value), and [`set_values()`](#set_values) log an error and return early when the buffer is empty or the index is out of range.

3. **[`append_value()`](#append_value) and [`append_values()`](#append_values) always succeed.** They never reject input. When the buffer is full, the oldest value is silently overwritten. The return value indicates how many existing values were overwritten.

## Constructor

### `new()`

```gdscript
Int32Buffer.new(p_capacity: int) -> Int32Buffer
```

Creates an empty buffer with the given capacity. The buffer is ready to use immediately after construction.

**Parameters**

* `p_capacity: int` Maximum number of `int` values the buffer can hold. Values below `1` are clamped to `1`.
* `p_default_value: int` Value used to fill unused slots at construction and after [`clear()`](#clear). Default: `-1`.

## Methods

### Introspection

#### get_capacity()

```gdscript
get_capacity() -> int
```

Returns the maximum number of values the buffer can hold.

---

#### size()

```gdscript
size() -> int
```

Returns the number of values currently stored. Always between `0` and [`get_capacity()`](#get_capacity).

---

### Reading and writing individual values

#### get_value()

```gdscript
get_value(p_logical_index: int) -> int
```

Returns the `int` at the given logical index. Index `0` is the oldest value in the buffer, [`size()`](#size)` - 1` is the most recent. Logs an error and returns `-1` if the buffer is empty or the index is out of range.

**Parameters**

* `p_logical_index: int` Logical index in the range `[0, `[`size()`](#size)` - 1]`.

---

#### set_value()

```gdscript
set_value(p_logical_index: int, p_value: int) -> void
```

Overwrites the `int` at the given logical index. Index `0` is the oldest value, [`size()`](#size)` - 1` is the most recent. Logs an error and does nothing if the buffer is empty or the index is out of range.

**Parameters**

* `p_logical_index: int` Logical index in the range `[0, `[`size()`](#size)` - 1]`.
* `p_value: int` Replacement value.

---

#### set_values()

```gdscript
set_values(p_start_index: int, p_values: PackedInt32Array) -> int
```

Overwrites a contiguous range of values starting at `p_start_index`. Writes as many values as fit from `p_start_index` to the end of the currently stored range. Returns the number of values actually written. Returns `0` without writing if `p_values` is empty, the buffer is empty, or `p_start_index` is out of range. Logs an error in the latter two cases.

**Parameters**

* `p_start_index: int` Logical index of the first slot to overwrite. Must be in the range `[0, `[`size()`](#size)` - 1]`.
* `p_values: PackedInt32Array` Replacement values. Values beyond [`size()`](#size)` - p_start_index` are ignored.

---

### Appending values

#### append_value()

```gdscript
append_value(p_value: int) -> int
```

Appends one `int` to the buffer. If the buffer is full, the oldest value is overwritten. Returns `1` if an existing value was overwritten, `0` otherwise.

**Parameters**

* `p_value: int` Value to append.

---

#### append_values()

```gdscript
append_values(p_values: PackedInt32Array) -> int
```

Appends multiple `int` values to the buffer. If the buffer does not have enough free slots, the oldest values are overwritten. Returns the number of existing values overwritten. Returns `0` immediately if `p_values` is empty.

**Parameters**

* `p_values: PackedInt32Array` Values to append, in order from oldest to newest.

---

### Capacity

#### set_capacity()

```gdscript
set_capacity(p_capacity: int) -> void
```

Resizes the buffer to the new capacity. Values below `1` are clamped to `1`. If the new capacity is smaller than the current sample count, the oldest values are dropped. If the new capacity is greater, existing values are preserved, new slots are pre-filled with the default value set at construction, and [`size()`](#size) is unchanged. Does nothing if the new capacity equals the current one.

**Parameters**

* `p_capacity: int` New maximum number of values the buffer can hold.

---

### Clearing data

#### clear()

```gdscript
clear() -> void
```

Removes all stored values. The buffer capacity is unchanged. All slots are refilled with the `p_default_value` set at construction.

## Related Classes

* [`ColorBuffer`](color_buffer.md) Sibling ring buffer storing `Color` values.
* [`Float32Buffer`](float32_buffer.md) Sibling ring buffer storing `float` values (32-bit).
* [`Float64Buffer`](float64_buffer.md) Sibling ring buffer storing `float` values (64-bit).
* [`StringBuffer`](string_buffer.md) Sibling ring buffer storing `String` values.
