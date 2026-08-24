# Ring buffer storage of strings.
# Logical index 0 is the oldest element.
# Reading outside [0; size()[ is an error and returns an empty string.
class StringBuffer extends RefCounted:
	var _capacity: int = 1024
	var _storage_head: int = 0
	var _stored_count: int = 0
	var _buffer: PackedStringArray = []


	func _init(p_capacity: int) -> void:
		_capacity = max(p_capacity, 1)
		_storage_head = 0
		_stored_count = 0
		_buffer.resize(_capacity)


	func get_capacity() -> int:
		return _capacity


	func set_capacity(p_capacity: int) -> void:
		var new_cap := max(p_capacity, 1)
		if new_cap == _capacity:
			return

		var keep := min(_stored_count, new_cap)
		_buffer = _resize_ring_buffer(_buffer, _capacity, _storage_head, _stored_count, new_cap)

		_capacity = new_cap
		_stored_count = keep
		_storage_head = keep % _capacity


	func size() -> int:
		return _stored_count


	func clear() -> void:
		_storage_head = 0
		_stored_count = 0


	func get_value(p_logical_index: int) -> String:
		if _stored_count <= 0:
			push_error("StringBuffer: the buffer is empty")
			return ""

		if p_logical_index < 0 or p_logical_index >= _stored_count:
			push_error("StringBuffer: logical index %d out of range [0; %d[" % [p_logical_index, _stored_count])
			return ""

		return _buffer[(_storage_origin() + p_logical_index) % _capacity]


	## Skips the range validation of get_value(). Outside [0; size()[ this reads
	## an unrelated slot of the ring storage instead of reporting an error, so
	## the caller must already hold the bound.
	func get_value_unsafe(p_logical_index: int) -> String:
		return _buffer[(_storage_origin() + p_logical_index) % _capacity]


	func get_values(p_start_index: int, p_count: int) -> PackedStringArray:
		if p_count <= 0:
			return PackedStringArray()

		if p_start_index < 0 or p_start_index + p_count > _stored_count:
			push_error("StringBuffer: range [%d; %d[ out of range [0; %d[" % [p_start_index, p_start_index + p_count, _stored_count])
			return PackedStringArray()

		# Optimization. The range is validated once, the ring origin is computed
		# once, and the read is split at the seam into at most two native
		# slices. Reading element by element would cost a script iteration and
		# an index mapping per value, which dominates on a large read.
		var start := (_storage_origin() + p_start_index) % _capacity
		var head := _capacity - start
		if p_count <= head:
			return _buffer.slice(start, start + p_count)

		var out := _buffer.slice(start, _capacity)
		out.append_array(_buffer.slice(0, p_count - head))
		return out


	func set_value(p_logical_index: int, p_value: String) -> void:
		if _stored_count <= 0:
			push_error("StringBuffer: the buffer is empty")
			return

		if p_logical_index < 0 or p_logical_index >= _stored_count:
			push_error("StringBuffer: logical index %d out of range [0; %d[" % [p_logical_index, _stored_count])
			return

		_buffer[(_storage_origin() + p_logical_index) % _capacity] = p_value


	func set_values(p_start_index: int, p_values: PackedStringArray) -> int:
		if p_values.is_empty():
			return 0

		if _stored_count <= 0:
			push_error("StringBuffer: the buffer is empty")
			return 0

		if p_start_index < 0 or p_start_index >= _stored_count:
			push_error("StringBuffer: start_index %d out of range [0; %d[" % [p_start_index, _stored_count])
			return 0

		# Optimization. The range is validated once, the ring origin is computed
		# once, and the write is split at the seam into two contiguous runs.
		# Mapping each logical index on its own would repeat both the validation
		# and the origin arithmetic per element.
		#
		# The write stays in place on purpose. Rebuilding the storage from
		# slices would be one native copy but would reallocate the whole buffer,
		# which loses on the small writes a streaming plot makes.
		var write_count := min(p_values.size(), _stored_count - p_start_index)
		var start := (_storage_origin() + p_start_index) % _capacity
		var head := min(write_count, _capacity - start)
		for i in range(head):
			_buffer[start + i] = p_values[i]
		for i in range(write_count - head):
			_buffer[i] = p_values[head + i]

		return write_count


	func append_value(p_value: String) -> int:
		var overwrote := (_stored_count == _capacity)

		_buffer[_storage_head] = p_value
		_storage_head = (_storage_head + 1) % _capacity
		if not overwrote:
			_stored_count += 1

		return 1 if overwrote else 0


	func append_values(p_values: PackedStringArray) -> int:
		if p_values.is_empty():
			return 0

		var write_count := p_values.size()
		var free_space := _capacity - _stored_count
		var overwritten_count := max(write_count - free_space, 0)

		if overwritten_count > 0:
			_stored_count = _capacity
		else:
			_stored_count += write_count

		# Write sequentially starting at head, wrapping as needed.
		var remaining := write_count
		var src_i := 0
		while remaining > 0:
			var chunk := min(remaining, _capacity - _storage_head)
			for i in range(chunk):
				_buffer[_storage_head + i] = p_values[src_i + i]

			_storage_head = (_storage_head + chunk) % _capacity
			src_i += chunk
			remaining -= chunk

		return overwritten_count


	####################################################################################################
	# Private
	####################################################################################################

	# Storage index of logical index 0. Carries no validation so bulk paths can
	# hoist it out of their loop and index the storage directly. Callers
	# validate the logical range before using it.
	func _storage_origin() -> int:
		var origin := _storage_head - _stored_count
		return origin + _capacity if origin < 0 else origin


	static func _resize_ring_buffer(p_old: PackedStringArray, p_old_cap: int, p_old_head: int, p_old_count: int, p_new_cap: int) -> PackedStringArray:
		var out := PackedStringArray()
		out.resize(p_new_cap)

		var keep := min(p_old_count, p_new_cap)
		if keep <= 0:
			return out

		var oldest_storage := p_old_head - p_old_count
		if oldest_storage < 0:
			oldest_storage += p_old_cap

		var start_logical: int = p_old_count - keep
		for i in range(keep):
			var logical_i := start_logical + i
			var storage_i := (oldest_storage + logical_i) % p_old_cap
			out[i] = p_old[storage_i]

		return out
