# Float64Buffer

!!! info ""
    **Inherits:** `RefCounted`  
    **Namespace:** [`TauPlot`](tau_plot.md)

Ring buffer that stores `float` values (64-bit) with a fixed capacity.

## Description

`Float64Buffer` stores a sequence of `float` values (64-bit) in a ring buffer of fixed capacity. When the buffer is full, appending a new value drops the oldest one. 

All read and write operations use **logical indices**. Index `0` refers to the oldest value currently in the buffer. Index [`size()`](#size)` - 1` refers to the most recently appended one. Logical indices shift when the buffer wraps: after a new value is appended into a full buffer, every index decreases by one.

The buffer holds no readable value outside `[0, `[`size()`](#size)` - 1]`. Capacity bounds how many values the buffer can hold at once, and appending is the only operation that raises [`size()`](#size).

The buffer is pre-allocated at construction and does not resize unless [`set_capacity()`](#set_capacity) is called explicitly.

### Example

```gdscript
# Ring buffer with a capacity of 512 floats (64-bit).
var y_vals := TauPlot.Float64Buffer.new(512)

# Append one float.
y_vals.append_value(3.14159265358979)
```

### Notes

1. **A new buffer is empty.** Construction allocates the slots and stores no value, so [`size()`](#size) is `0` and every read fails until the first append. [`clear()`](#clear) returns the buffer to that state.

2. **Out-of-range access logs an error.** [`set_value()`](#set_value) and [`set_values()`](#set_values) log an error and write nothing when the buffer is empty or the index is out of range. [`get_value()`](#get_value) reports the same failure through its return value.

3. **[`append_value()`](#append_value) and [`append_values()`](#append_values) always succeed.** They never reject input. When the buffer is full, the oldest value is silently overwritten. The return value indicates how many existing values were overwritten.

## Constructor

### `new()`

```gdscript
Float64Buffer.new(p_capacity: int) -> Float64Buffer
```

Creates an empty buffer with the given capacity.

**Parameters**

* `p_capacity: int` Maximum number of `float` values (64-bit) the buffer can hold. Values below `1` are clamped to `1`.

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
get_value(p_logical_index: int) -> float
```

Returns the `float` at the given logical index. Index `0` is the oldest value in the buffer, [`size()`](#size)` - 1` is the most recent.

Reading an empty buffer, or a logical index below `0` or at or above [`size()`](#size), pushes an error and returns `0.0`.

**Parameters**

* `p_logical_index: int` Logical index in the range `[0, `[`size()`](#size)` - 1]`.

---

#### set_value()

```gdscript
set_value(p_logical_index: int, p_value: float) -> void
```

Overwrites the `float` at the given logical index. Index `0` is the oldest value, [`size()`](#size)` - 1` is the most recent. Logs an error and does nothing if the buffer is empty or the index is out of range.

**Parameters**

* `p_logical_index: int` Logical index in the range `[0, `[`size()`](#size)` - 1]`.
* `p_value: float` Replacement value.

---

#### set_values()

```gdscript
set_values(p_start_index: int, p_values: PackedFloat64Array) -> int
```

Overwrites a contiguous range of values starting at `p_start_index`. Writes as many values as fit from `p_start_index` to the end of the currently stored range. Returns the number of values actually written. Returns `0` without writing if `p_values` is empty, the buffer is empty, or `p_start_index` is out of range. Logs an error in the latter two cases.

**Parameters**

* `p_start_index: int` Logical index of the first slot to overwrite. Must be in the range `[0, `[`size()`](#size)` - 1]`.
* `p_values: PackedFloat64Array` Replacement values. Values beyond [`size()`](#size)` - p_start_index` are ignored.

---

### Appending values

#### append_value()

```gdscript
append_value(p_value: float) -> int
```

Appends one `float` to the buffer. If the buffer is full, the oldest value is overwritten. Returns `1` if an existing value was overwritten, `0` otherwise.

**Parameters**

* `p_value: float` Value to append.

---

#### append_values()

```gdscript
append_values(p_values: PackedFloat64Array) -> int
```

Appends multiple `float` values (64-bit) to the buffer. If the buffer does not have enough free slots, the oldest values are overwritten. Returns the number of existing values overwritten. Returns `0` immediately if `p_values` is empty.

**Parameters**

* `p_values: PackedFloat64Array` Values to append, in order from oldest to newest.

---

### Capacity

#### set_capacity()

```gdscript
set_capacity(p_capacity: int) -> void
```

Resizes the buffer to the new capacity. Values below `1` are clamped to `1`. If the new capacity is below [`size()`](#size), the oldest values are dropped and [`size()`](#size) becomes the new capacity. If it is above, every stored value is preserved and [`size()`](#size) is unchanged. Does nothing if the new capacity equals the current one.

**Parameters**

* `p_capacity: int` New maximum number of values the buffer can hold.

---

### Clearing data

#### clear()

```gdscript
clear() -> void
```

Removes all stored values. [`size()`](#size) becomes `0` and the capacity is unchanged.

## Related Classes

* [`ColorBuffer`](color_buffer.md) Sibling ring buffer storing `Color` values.
* [`Float32Buffer`](float32_buffer.md) Sibling ring buffer storing `float` values (32-bit).
* [`Int32Buffer`](int32_buffer.md) Sibling ring buffer storing `int` values (32-bit).
* [`StringBuffer`](string_buffer.md) Sibling ring buffer storing `String` values.