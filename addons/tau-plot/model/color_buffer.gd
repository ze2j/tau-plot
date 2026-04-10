# Ring buffer storage of colors.
# Logical index 0 is the oldest element.
class ColorBuffer extends RefCounted:
	const NO_COLOR = Color(0., 0., 0., 0.)

	var _capacity: int = 1024
	var _storage_head: int = 0
	var _stored_count: int = 0
	var _buffer: PackedColorArray = []


	func _init(p_capacity: int, p_default_value: Color = NO_COLOR) -> void:
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


	func get_value(p_logical_index: int) -> Color:
		var storage_i := _map_logical_to_storage(p_logical_index)
		return _buffer[storage_i]


	func set_value(p_logical_index: int, p_value: Color) -> void:
		var storage_i := _map_logical_to_storage(p_logical_index)
		_buffer[storage_i] = p_value


	func set_values(p_start_index: int, p_values: PackedColorArray) -> int:
		if p_values.is_empty():
			return 0

		if _stored_count <= 0:
			push_error("ColorBuffer: the buffer is empty")
			return 0

		if p_start_index < 0 or p_start_index >= _stored_count:
			push_error("ColorBuffer: start_index %d out of range [0; %d[" % [p_start_index, _stored_count])
			return 0

		var max_write := min(p_values.size(), _stored_count - p_start_index)
		for i in range(max_write):
			var storage_i := _map_logical_to_storage(p_start_index + i)
			_buffer[storage_i] = p_values[i]

		return max_write


	func append_value(p_value: Color) -> int:
		var overwrote := (_stored_count + 1 > _capacity)

		_buffer[_storage_head] = p_value
		_storage_head = (_storage_head + 1) % _capacity
		if not overwrote:
			_stored_count += 1

		return 1 if overwrote else 0


	func append_values(p_values: PackedColorArray) -> int:
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

	func _map_logical_to_storage(p_logical_index: int) -> int:
		if _stored_count <= 0:
			push_error("ColorBuffer: the buffer is empty")
			return 0

		if p_logical_index < 0 or p_logical_index >= _stored_count:
			push_error("ColorBuffer: logical index %d out of range [0; %d[" % [p_logical_index, _stored_count])
			return 0

		var oldest_storage := _storage_head - _stored_count
		if oldest_storage < 0:
			oldest_storage += _capacity

		return (oldest_storage + p_logical_index) % _capacity


	static func _resize_ring_buffer(p_old: PackedColorArray, p_old_cap: int, p_old_head: int, p_old_count: int, p_new_cap: int) -> PackedColorArray:
		var out := PackedColorArray()
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
