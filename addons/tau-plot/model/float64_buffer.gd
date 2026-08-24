# Ring buffer storage of 64-bits floats.
# Logical index 0 is the oldest element.
# Reading outside [0; size()[ is an error and returns 0.0.
class Float64Buffer extends RefCounted:
	var _capacity: int = 1024
	var _storage_head: int = 0
	var _stored_count: int = 0
	var _buffer: PackedFloat64Array = []


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


	func get_value(p_logical_index: int) -> float:
		if _stored_count <= 0:
			push_error("Float64Buffer: the buffer is empty")
			return 0.0

		if p_logical_index < 0 or p_logical_index >= _stored_count:
			push_error("Float64Buffer: logical index %d out of range [0; %d[" % [p_logical_index, _stored_count])
			return 0.0

		return _buffer[(_storage_origin() + p_logical_index) % _capacity]


	# Unsafe: it does not check the index. Outside [0; size()[ it reads the
	# wrong slot of the ring storage and reports no error. Only call it when
	# the index is already known to be valid.
	func get_value_unsafe(p_logical_index: int) -> float:
		return _buffer[(_storage_origin() + p_logical_index) % _capacity]


	func get_values(p_start_index: int, p_count: int) -> PackedFloat64Array:
		if p_count <= 0:
			return PackedFloat64Array()

		if p_start_index < 0 or p_start_index + p_count > _stored_count:
			push_error("Float64Buffer: range [%d; %d[ out of range [0; %d[" % [p_start_index, p_start_index + p_count, _stored_count])
			return PackedFloat64Array()

		# Optimization. The range is checked once, the ring origin is computed
		# once, and the read is cut at the ring seam into one or two native
		# slices. Reading one value at a time would cost a loop step and an
		# index mapping per value, which is most of the cost of a big read.
		var start := (_storage_origin() + p_start_index) % _capacity
		var head := _capacity - start
		if p_count <= head:
			return _buffer.slice(start, start + p_count)

		var out := _buffer.slice(start, _capacity)
		out.append_array(_buffer.slice(0, p_count - head))
		return out


	func set_value(p_logical_index: int, p_value: float) -> void:
		if _stored_count <= 0:
			push_error("Float64Buffer: the buffer is empty")
			return

		if p_logical_index < 0 or p_logical_index >= _stored_count:
			push_error("Float64Buffer: logical index %d out of range [0; %d[" % [p_logical_index, _stored_count])
			return

		_buffer[(_storage_origin() + p_logical_index) % _capacity] = p_value


	func set_values(p_start_index: int, p_values: PackedFloat64Array) -> int:
		if p_values.is_empty():
			return 0

		if _stored_count <= 0:
			push_error("Float64Buffer: the buffer is empty")
			return 0

		if p_start_index < 0 or p_start_index >= _stored_count:
			push_error("Float64Buffer: start_index %d out of range [0; %d[" % [p_start_index, _stored_count])
			return 0

		# Optimization. The range is checked once, the ring origin is computed
		# once, and the write is cut at the ring seam into two contiguous runs.
		# Mapping each index on its own would repeat the check and the origin
		# maths for every value.
		#
		# The write stays in place on purpose. Rebuilding the storage from
		# slices would be one native copy, but it would allocate the whole
		# buffer again, which is slower for the small writes a streaming plot
		# makes.
		var write_count := min(p_values.size(), _stored_count - p_start_index)
		var start := (_storage_origin() + p_start_index) % _capacity
		var head := min(write_count, _capacity - start)
		for i in range(head):
			_buffer[start + i] = p_values[i]
		for i in range(write_count - head):
			_buffer[i] = p_values[head + i]

		return write_count


	func append_value(p_value: float) -> int:
		var overwrote := (_stored_count == _capacity)

		_buffer[_storage_head] = p_value
		_storage_head = (_storage_head + 1) % _capacity
		if not overwrote:
			_stored_count += 1

		return 1 if overwrote else 0


	func append_values(p_values: PackedFloat64Array) -> int:
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

	# Storage index of logical index 0. It checks nothing, so a bulk read or
	# write can call it once before its loop and then index the storage
	# directly. Callers check the logical range themselves.
	func _storage_origin() -> int:
		var origin := _storage_head - _stored_count
		return origin + _capacity if origin < 0 else origin


	static func _resize_ring_buffer(p_old: PackedFloat64Array, p_old_cap: int, p_old_head: int, p_old_count: int, p_new_cap: int) -> PackedFloat64Array:
		var out := PackedFloat64Array()
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
