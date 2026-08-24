# StringBuffer

!!! info ""
    **Inherits:** `RefCounted`  
    **Namespace:** [`TauPlot`](tau_plot.md)

Ring buffer that stores `String` values with a fixed capacity.

## Description

`StringBuffer` stores a sequence of `String` values in a ring buffer of fixed capacity. When the buffer is full, appending a new value drops the oldest one. 

All read and write operations use **logical indices**. Index `0` refers to the oldest value currently in the buffer. Index [`size()`](#size)` - 1` refers to the most recently appended one. Logical indices shift when the buffer wraps: after a new value is appended into a full buffer, every index decreases by one.

The buffer holds no readable value outside `[0, `[`size()`](#size)` - 1]`. Capacity bounds how many values the buffer can hold at once, and appending is the only operation that raises [`size()`](#size).

The buffer is pre-allocated at construction and does not resize unless [`set_capacity()`](#set_capacity) is called explicitly.

### Example

```gdscript
# Ring buffer with a capacity of 64 strings.
var labels := TauPlot.StringBuffer.new(64)

# Append one string.
labels.append_value("January")
```

### Notes

1. **A new buffer is empty.** Construction allocates the slots and stores no value, so [`size()`](#size) is `0` and every read fails until the first append. [`clear()`](#clear) returns the buffer to that state.

2. **Out-of-range access logs an error.** [`set_value()`](#set_value) and [`set_values()`](#set_values) log an error and write nothing when the buffer is empty or the index is out of range. [`get_value()`](#get_value) reports the same failure through its return value, and [`get_values()`](#get_values) returns an empty array.

3. **[`append_value()`](#append_value) and [`append_values()`](#append_values) always succeed.** They never reject input. When the buffer is full, the oldest value is silently overwritten. The return value indicates how many existing values were overwritten.

## Constructor

### `new()`

```gdscript
StringBuffer.new(p_capacity: int) -> StringBuffer
```

Creates an empty buffer with the given capacity.

**Parameters**

* `p_capacity: int` Maximum number of `String` values the buffer can hold. Values below `1` are clamped to `1`.

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

### Reading and writing values

#### get_value()

```gdscript
get_value(p_logical_index: int) -> String
```

Returns the `String` at the given logical index. Index `0` is the oldest value in the buffer, [`size()`](#size)` - 1` is the most recent.

Reading an empty buffer, or a logical index below `0` or at or above [`size()`](#size), pushes an error and returns `""`.

**Parameters**

* `p_logical_index: int` Logical index in the range `[0, `[`size()`](#size)` - 1]`.

---

#### get_value_unsafe()

```gdscript
get_value_unsafe(p_logical_index: int) -> String
```

Returns the `String` at the given logical index, without checking the index. On a valid index it returns the same value as [`get_value()`](#get_value), and it is faster because it skips the check.

This method is unsafe. An index outside `[0, `[`size()`](#size)` - 1]` is undefined behavior. Use [`get_value()`](#get_value) unless the index is already known to be valid, for example a loop counter that stops at [`size()`](#size).

**Parameters**

* `p_logical_index: int` Logical index in the range `[0, `[`size()`](#size)` - 1]`. The method does not check it.

---

#### get_values()

```gdscript
get_values(p_start_index: int, p_count: int) -> PackedStringArray
```

Returns `p_count` values, starting at logical index `p_start_index`. Index `0` is the oldest value in the buffer, [`size()`](#size)` - 1` is the most recent. The returned array is a copy, so writing to it does not change the buffer.

If `p_count` is `0` or less, the method returns an empty array and pushes no error. If the range goes outside `[0, `[`size()`](#size)`[`, it pushes an error and returns an empty array.

Reading a whole range at once is faster than reading one value at a time. Use it whenever you need more than a few values.

**Parameters**

* `p_start_index: int` Logical index of the first value to read. Must be in the range `[0, `[`size()`](#size)` - 1]`.
* `p_count: int` How many values to read. `p_start_index + p_count` must not be greater than [`size()`](#size).

---

#### set_value()

```gdscript
set_value(p_logical_index: int, p_value: String) -> void
```

Overwrites the `String` at the given logical index. Index `0` is the oldest value, [`size()`](#size)` - 1` is the most recent. Logs an error and does nothing if the buffer is empty or the index is out of range.

**Parameters**

* `p_logical_index: int` Logical index in the range `[0, `[`size()`](#size)` - 1]`.
* `p_value: String` Replacement value.

---

#### set_values()

```gdscript
set_values(p_start_index: int, p_values: PackedStringArray) -> int
```

Overwrites a contiguous range of values starting at `p_start_index`. Writes as many values as fit from `p_start_index` to the end of the currently stored range. Returns the number of values actually written. Returns `0` without writing if `p_values` is empty, the buffer is empty, or `p_start_index` is out of range. Logs an error in the latter two cases.

**Parameters**

* `p_start_index: int` Logical index of the first slot to overwrite. Must be in the range `[0, `[`size()`](#size)` - 1]`.
* `p_values: PackedStringArray` Replacement values. Values beyond [`size()`](#size)` - p_start_index` are ignored.

---

### Appending values

#### append_value()

```gdscript
append_value(p_value: String) -> int
```

Appends one `String` to the buffer. If the buffer is full, the oldest value is overwritten. Returns `1` if an existing value was overwritten, `0` otherwise.

**Parameters**

* `p_value: String` Value to append.

---

#### append_values()

```gdscript
append_values(p_values: PackedStringArray) -> int
```

Appends multiple `String` values to the buffer. If the buffer does not have enough free slots, the oldest values are overwritten. Returns the number of existing values overwritten. Returns `0` immediately if `p_values` is empty.

**Parameters**

* `p_values: PackedStringArray` Values to append, in order from oldest to newest.

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
* [`Float64Buffer`](float64_buffer.md) Sibling ring buffer storing `float` values (64-bit).
* [`Int32Buffer`](int32_buffer.md) Sibling ring buffer storing `int` values (32-bit).