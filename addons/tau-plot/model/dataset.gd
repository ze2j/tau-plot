# Dependencies
const DatasetChange := preload("res://addons/tau-plot/model/dataset_change.gd").DatasetChange
const StringBuffer := preload("res://addons/tau-plot/model/string_buffer.gd").StringBuffer
const Float64Buffer := preload("res://addons/tau-plot/model/float64_buffer.gd").Float64Buffer


## Dataset
## Dataset is the central data container used by plots.
## It holds multiple data series and all their samples (X and Y values).
##
## The Dataset is responsible for:
## - storing samples efficiently for real-time updates,
## - deciding whether X values are shared by all series or owned per series,
## - adding, removing, reordering, and renaming series,
## - appending new samples or updating existing ones,
## - notifying listeners about what changed so they can update incrementally.
class Dataset extends RefCounted:
	signal changed(p_change: DatasetChange)

	enum Mode
	{
		SHARED_X,       # All series share the same X values at each sample index.
		PER_SERIES_X    # Each series owns its own independent X values.
	}

	enum XElementType
	{
		CATEGORY,   # X values are strings.
		NUMERIC     # X values are 64-bits floats.
	}

	var _mode: Mode = Mode.SHARED_X
	var _x_element_type: XElementType = XElementType.CATEGORY

	var _series_ids: PackedInt64Array = [] # In GdScript int is a signed 64-bit integer type. So KISS.
	var _series_names: PackedStringArray = []
	var _next_series_id: int = 1

	var _x_buffers: Array = []
	var _y_buffers: Array[Float64Buffer] = []

	var _shared_capacity: int = 1024

	var _is_batching: bool = false
	var _batch_depth: int = 0
	var _batched_change: DatasetChange = null


	func _init(p_mode: Mode,
			   p_x_element_type: XElementType,
			   p_shared_capacity: int = 1024) -> void:
		_mode = p_mode
		_x_element_type = p_x_element_type
		_shared_capacity = max(p_shared_capacity, 1)

		_series_ids = []
		_series_names = []
		_x_buffers = []
		_y_buffers = []

		if _mode == Mode.SHARED_X:
			match _x_element_type:
				XElementType.CATEGORY:
					_x_buffers.append(StringBuffer.new(_shared_capacity))
				XElementType.NUMERIC:
					_x_buffers.append(Float64Buffer.new(_shared_capacity))
				_:
					push_error("Dataset(): unexpected X element type")


	## Convenience method to create and fully initialize a SHARED_X dataset with categorical X values and multiple series from bulk arrays.
	static func make_shared_x_categorical(p_series_names: PackedStringArray, p_x: PackedStringArray, p_y_by_series: Array[PackedFloat64Array], p_capacity: int = -1) -> Dataset:
		if p_series_names.is_empty():
			push_error("Dataset.make_shared_x_categorical(): p_series_names is empty")
			return null

		if p_y_by_series.size() != p_series_names.size():
			push_error("Dataset.make_shared_x_categorical(): expected %d y arrays, got %d" % [p_series_names.size(), p_y_by_series.size()])
			return null

		for s_i in range(p_series_names.size()):
			var y := p_y_by_series[s_i]
			if y.size() != p_x.size():
				push_error("Dataset.make_shared_x_categorical(): series '%s' expected %d y values, got %d" % [p_series_names[s_i], p_x.size(), y.size()])
				return null

		var cap := p_capacity
		if cap < 0:
			cap = p_x.size()

		var dataset := Dataset.new(Mode.SHARED_X, XElementType.CATEGORY, cap)

		for name in p_series_names:
			dataset.add_series(name)

		for i in range(p_x.size()):
			var ys := PackedFloat64Array()
			ys.resize(p_series_names.size())
			for s_i in range(p_series_names.size()):
				ys[s_i] = p_y_by_series[s_i][i]
			dataset.append_shared_sample(p_x[i], ys)

		return dataset


	## Convenience method to create and fully initialize a SHARED_X dataset with continuous X values and multiple series from bulk arrays.
	static func make_shared_x_continuous(p_series_names: PackedStringArray, p_x: PackedFloat64Array, p_y_by_series: Array[PackedFloat64Array], p_capacity: int = -1) -> Dataset:
		if p_series_names.is_empty():
			push_error("Dataset.make_shared_x_continuous(): p_series_names is empty")
			return null

		if p_y_by_series.size() != p_series_names.size():
			push_error("Dataset.make_shared_x_continuous(): expected %d y arrays, got %d" % [p_series_names.size(), p_y_by_series.size()])
			return null

		for s_i in range(p_series_names.size()):
			var y := p_y_by_series[s_i]
			if y.size() != p_x.size():
				push_error("Dataset.make_shared_x_continuous(): series '%s' expected %d y values, got %d" % [p_series_names[s_i], p_x.size(), y.size()])
				return null

		var cap := p_capacity
		if cap < 0:
			cap = p_x.size()

		var dataset := Dataset.new(Mode.SHARED_X, XElementType.NUMERIC, cap)

		for name in p_series_names:
			dataset.add_series(name)

		for i in range(p_x.size()):
			var ys := PackedFloat64Array()
			ys.resize(p_series_names.size())
			for s_i in range(p_series_names.size()):
				ys[s_i] = p_y_by_series[s_i][i]
			dataset.append_shared_sample(p_x[i], ys)

		return dataset


	## Convenience method to create and fully initialize a PER_SERIES_X dataset with continuous X values, where each series provides its own X/Y arrays.
	static func make_per_series_x_continuous(p_series_names: PackedStringArray, p_x_by_series: Array[PackedFloat64Array], p_y_by_series: Array[PackedFloat64Array], p_capacity_by_series: PackedInt32Array = PackedInt32Array()) -> Dataset:
		if p_series_names.is_empty():
			push_error("Dataset.make_per_series_x_continuous(): p_series_names is empty")
			return null

		if p_x_by_series.size() != p_series_names.size():
			push_error("Dataset.make_per_series_x_continuous(): expected %d x arrays, got %d" % [p_series_names.size(), p_x_by_series.size()])
			return null

		if p_y_by_series.size() != p_series_names.size():
			push_error("Dataset.make_per_series_x_continuous(): expected %d y arrays, got %d" % [p_series_names.size(), p_y_by_series.size()])
			return null

		if not p_capacity_by_series.is_empty() and p_capacity_by_series.size() != p_series_names.size():
			push_error("Dataset.make_per_series_x_continuous(): capacity_by_series must be empty or have %d entries, got %d" % [p_series_names.size(), p_capacity_by_series.size()])
			return null

		for s_i in range(p_series_names.size()):
			var xs := p_x_by_series[s_i]
			var ys := p_y_by_series[s_i]
			if xs.size() != ys.size():
				push_error("Dataset.make_per_series_x_continuous(): series '%s' expected x/y arrays to have same size, got x=%d y=%d" % [p_series_names[s_i], xs.size(), ys.size()])
				return null

		var dataset := Dataset.new(Mode.PER_SERIES_X, XElementType.NUMERIC, 1)

		var series_ids := PackedInt64Array()
		series_ids.resize(p_series_names.size())

		for s_i in range(p_series_names.size()):
			var xs := p_x_by_series[s_i]
			var cap := xs.size()
			if not p_capacity_by_series.is_empty():
				cap = max(p_capacity_by_series[s_i], 1)
			series_ids[s_i] = dataset.add_series(p_series_names[s_i], cap)

		for s_i in range(p_series_names.size()):
			var series_id := series_ids[s_i]
			var xs := p_x_by_series[s_i]
			var ys := p_y_by_series[s_i]

			for i in range(xs.size()):
				dataset.append_sample_to_one_series(series_id, xs[i], ys[i])

		return dataset


	func get_mode() -> Mode:
		return _mode


	func get_x_element_type() -> XElementType:
		return _x_element_type


	func begin_batch() -> void:
		_batch_depth += 1
		_is_batching = _batch_depth > 0

		if _batched_change == null:
			_batched_change = DatasetChange.new()
			_batched_change.type = DatasetChange.Type.BATCH


	func end_batch() -> void:
		if _batch_depth <= 0:
			push_error("Dataset.end_batch(): called without matching begin_batch()")
			return

		_batch_depth -= 1
		_is_batching = _batch_depth > 0

		if _batch_depth == 0:
			if _batched_change != null and _batched_change.flags != 0:
				changed.emit(_batched_change)
			_batched_change = null


	func is_batching() -> bool:
		return _is_batching


	func get_series_count() -> int:
		return _series_ids.size()


	func get_series_ids() -> PackedInt64Array:
		return _series_ids.duplicate()


	func get_series_names() -> PackedStringArray:
		return _series_names.duplicate()


	func get_series_name(p_series_id: int) -> String:
		var idx := get_series_index_by_id(p_series_id)
		if idx < 0:
			return ""
		return _series_names[idx]


	func set_series_name(p_series_id: int, p_name: String) -> void:
		var idx := _require_series_exists(p_series_id)
		if idx < 0:
			return
		_series_names[idx] = p_name

		var c := DatasetChange.new()
		c.type = DatasetChange.Type.SERIES_RENAMED
		c.flags = DatasetChange.Flags.SERIES_RENAMED
		c.series_ids = PackedInt64Array([p_series_id])
		_emit_or_batch_change(c)


	func has_series(p_series_id: int) -> bool:
		return get_series_index_by_id(p_series_id) >= 0


	func get_series_index_by_id(p_series_id: int) -> int:
		for i in range(_series_ids.size()):
			if _series_ids[i] == p_series_id:
				return i
		return -1


	func get_series_id_by_index(p_series_index: int) -> int:
		if p_series_index < 0 or p_series_index >= _series_ids.size():
			return -1
		return _series_ids[p_series_index]


	func add_series(p_series_name: String, p_capacity: int = 1024) -> int:
		if _mode == Mode.SHARED_X and get_shared_sample_count() > 0:
			push_error("Dataset.add_series(): shared-X mode requires add_series_with_initial_y() when samples already exist")
			return -1

		return _add_series_internal(p_series_name, p_capacity, PackedFloat64Array())


	func add_series_with_initial_y(p_series_name: String, p_capacity: int, p_initial_y_values: PackedFloat64Array) -> int:
		if _mode != Mode.SHARED_X:
			push_error("Dataset.add_series_with_initial_y(): only valid in SHARED_X mode")
			return -1

		var n := get_shared_sample_count()
		if n <= 0:
			if not p_initial_y_values.is_empty():
				push_error("Dataset.add_series_with_initial_y(): dataset has no samples, initial values must be empty")
				return -1
		else:
			if p_initial_y_values.size() != n:
				push_error("Dataset.add_series_with_initial_y(): expected %d initial values, got %d" % [n, p_initial_y_values.size()])
				return -1

		return _add_series_internal(p_series_name, p_capacity, p_initial_y_values)


	func remove_series(p_series_id: int) -> void:
		var idx := _require_series_exists(p_series_id)
		if idx < 0:
			return

		_series_ids.remove_at(idx)
		_series_names.remove_at(idx)
		_y_buffers.remove_at(idx)

		if _mode == Mode.PER_SERIES_X:
			_x_buffers.remove_at(idx)

		var c := DatasetChange.new()
		c.type = DatasetChange.Type.SERIES_REMOVED
		c.flags = DatasetChange.Flags.SERIES_STRUCTURE_CHANGED
		c.series_ids = PackedInt64Array([p_series_id])
		_emit_or_batch_change(c)


	func reorder_series(p_new_order_series_ids: PackedInt64Array) -> void:
		if p_new_order_series_ids.size() != _series_ids.size():
			push_error("Dataset.reorder_series(): new order must contain exactly %d ids" % _series_ids.size())
			return

		var seen := {}
		for id_v in p_new_order_series_ids:
			var id_i := id_v
			if seen.has(id_i):
				push_error("Dataset.reorder_series(): duplicate series id %d" % id_i)
				return
			seen[id_i] = true

		for existing_id_v in _series_ids:
			var existing_id := existing_id_v
			if not seen.has(existing_id):
				push_error("Dataset.reorder_series(): missing existing series id %d" % existing_id)
				return

		var old_ids := _series_ids
		var old_names := _series_names
		var old_y := _y_buffers
		var old_x := _x_buffers

		_series_ids = PackedInt64Array()
		_series_names = PackedStringArray()
		_y_buffers = []
		_x_buffers = [] if _mode == Mode.PER_SERIES_X else _x_buffers

		_series_ids.resize(p_new_order_series_ids.size())
		_series_names.resize(p_new_order_series_ids.size())

		var new_y: Array[Float64Buffer] = []
		new_y.resize(p_new_order_series_ids.size())

		var new_x: Array = []
		if _mode == Mode.PER_SERIES_X:
			new_x.resize(p_new_order_series_ids.size())

		for new_i in range(p_new_order_series_ids.size()):
			var id_i := p_new_order_series_ids[new_i]
			var old_i := -1
			for j in range(old_ids.size()):
				if old_ids[j] == id_i:
					old_i = j
					break
			if old_i < 0:
				push_error("Dataset.reorder_series(): internal error mapping id %d" % id_i)
				return

			_series_ids[new_i] = id_i
			_series_names[new_i] = old_names[old_i]
			new_y[new_i] = old_y[old_i]
			if _mode == Mode.PER_SERIES_X:
				new_x[new_i] = old_x[old_i]

		_y_buffers = new_y
		if _mode == Mode.PER_SERIES_X:
			_x_buffers = new_x

		var c := DatasetChange.new()
		c.type = DatasetChange.Type.SERIES_REORDERED
		c.flags = DatasetChange.Flags.SERIES_STRUCTURE_CHANGED
		c.series_ids = _series_ids.duplicate()
		c.new_order_series_ids = p_new_order_series_ids.duplicate()
		_emit_or_batch_change(c)


	func get_shared_sample_count() -> int:
		if _mode != Mode.SHARED_X:
			push_error("Dataset.get_shared_sample_count(): only meaningful in SHARED_X mode")
			return 0
		if _x_buffers.is_empty():
			return 0
		return _x_buffers[0].size()


	func get_series_sample_count(p_series_id: int) -> int:
		var idx := _require_series_exists(p_series_id)
		if idx < 0:
			return 0

		# Y buffers always define the authoritative sample count for a series.
		# In SHARED_X mode, all Y buffers have the same count as the shared X buffer.
		return _y_buffers[idx].size()


	func get_shared_capacity() -> int:
		if _mode != Mode.SHARED_X:
			push_error("Dataset.get_capacity(): only meaningful in SHARED_X mode")
			return 0
		return _shared_capacity


	func set_shared_capacity(p_capacity: int) -> void:
		if _mode != Mode.SHARED_X:
			push_error("Dataset.set_shared_capacity(): only valid in SHARED_X mode")
			return

		var new_cap := max(p_capacity, 1)
		if new_cap == _shared_capacity:
			return

		_shared_capacity = new_cap
		if _x_buffers.size() != 1:
			push_error("Dataset.set_shared_capacity(): shared-X requires exactly one X buffer")
			return

		_x_buffers[0].set_capacity(_shared_capacity)
		for yb in _y_buffers:
			yb.set_capacity(_shared_capacity)

		var c := DatasetChange.new()
		c.type = DatasetChange.Type.RESET
		c.flags = DatasetChange.Flags.X_CHANGED | DatasetChange.Flags.Y_CHANGED
		c.series_ids = _series_ids.duplicate()
		c.count_after = get_shared_sample_count()
		_emit_or_batch_change(c)


	# Returns the ring-buffer capacity for a given series, regardless of SHARED_X
	# or PER_SERIES_X mode. In SHARED_X mode this returns the shared capacity.
	# In PER_SERIES_X mode this returns the Y buffer capacity for that series.
	func get_series_capacity(p_series_id: int) -> int:
		if _mode == Mode.SHARED_X:
			return _shared_capacity

		var idx := _require_series_exists(p_series_id)
		if idx < 0:
			return 0
		return _y_buffers[idx].get_capacity()


	func set_series_capacity(p_series_id: int, p_capacity: int) -> void:
		if _mode != Mode.PER_SERIES_X:
			push_error("Dataset.set_series_capacity(): only valid in PER_SERIES_X mode")
			return

		var idx := _require_series_exists(p_series_id)
		if idx < 0:
			return

		if _x_buffers.size() != _series_ids.size():
			push_error("Dataset.set_series_capacity(): per-series-X requires one X buffer per series")
			return

		var new_cap := max(p_capacity, 1)
		var xb = _x_buffers[idx]
		var yb := _y_buffers[idx]

		if new_cap == xb.get_capacity():
			return

		xb.set_capacity(new_cap)
		yb.set_capacity(new_cap)

		var c := DatasetChange.new()
		c.type = DatasetChange.Type.RESET
		c.flags = DatasetChange.Flags.X_CHANGED | DatasetChange.Flags.Y_CHANGED
		c.series_ids = PackedInt64Array([p_series_id])
		c.count_after = yb.size()
		_emit_or_batch_change(c)


	func get_shared_x(p_logical_sample_index: int) -> Variant:
		if _mode != Mode.SHARED_X:
			push_error("Dataset.get_shared_x(): only valid in SHARED_X mode")
			return null

		if _x_buffers.size() != 1:
			push_error("Dataset.get_shared_x(): shared-X requires exactly one X buffer")
			return null

		var xb = _x_buffers[0]
		return xb.get_value(p_logical_sample_index)


	func set_shared_x(p_logical_sample_index: int, p_x: Variant) -> void:
		if _mode != Mode.SHARED_X:
			push_error("Dataset.set_shared_x(): only valid in SHARED_X mode")
			return

		if _x_buffers.size() != 1:
			push_error("Dataset.set_shared_x(): shared-X requires exactly one X buffer")
			return

		var xb = _x_buffers[0]
		xb.set_value(p_logical_sample_index, p_x)

		var c := DatasetChange.new()
		c.type = DatasetChange.Type.VALUES_CHANGED
		c.flags = DatasetChange.Flags.X_CHANGED
		c.series_ids = _series_ids.duplicate()
		c.start_index = p_logical_sample_index
		c.end_index_exclusive = p_logical_sample_index + 1
		c.count_after = get_shared_sample_count()
		_emit_or_batch_change(c)


	func get_series_x(p_series_id: int, p_logical_sample_index: int) -> Variant:
		if _mode != Mode.PER_SERIES_X:
			push_error("Dataset.get_series_x(): only valid in PER_SERIES_X mode")
			return null

		var idx := _require_series_exists(p_series_id)
		if idx < 0:
			return null

		if _x_buffers.size() != _series_ids.size():
			push_error("Dataset.get_series_x(): per-series-X requires one X buffer per series")
			return null

		var xb = _x_buffers[idx]
		return xb.get_value(p_logical_sample_index)


	func set_series_x(p_series_id: int, p_logical_sample_index: int, p_x: Variant) -> void:
		if _mode != Mode.PER_SERIES_X:
			push_error("Dataset.set_series_x(): only valid in PER_SERIES_X mode")
			return

		var idx := _require_series_exists(p_series_id)
		if idx < 0:
			return

		if _x_buffers.size() != _series_ids.size():
			push_error("Dataset.set_series_x(): per-series-X requires one X buffer per series")
			return

		var xb = _x_buffers[idx]
		xb.set_value(p_logical_sample_index, p_x)

		var c := DatasetChange.new()
		c.type = DatasetChange.Type.VALUES_CHANGED
		c.flags = DatasetChange.Flags.X_CHANGED
		c.series_ids = PackedInt64Array([p_series_id])
		c.start_index = p_logical_sample_index
		c.end_index_exclusive = p_logical_sample_index + 1
		c.count_after = xb.size()
		_emit_or_batch_change(c)


	func get_series_y(p_series_id: int, p_logical_sample_index: int) -> float:
		var idx := _require_series_exists(p_series_id)
		if idx < 0:
			return 0.0
		return _y_buffers[idx].get_value(p_logical_sample_index)


	func set_series_y(p_series_id: int, p_logical_sample_index: int, p_y: float) -> void:
		var idx := _require_series_exists(p_series_id)
		if idx < 0:
			return

		_y_buffers[idx].set_value(p_logical_sample_index, p_y)

		var c := DatasetChange.new()
		c.type = DatasetChange.Type.VALUES_CHANGED
		c.flags = DatasetChange.Flags.Y_CHANGED
		c.series_ids = PackedInt64Array([p_series_id])
		c.start_index = p_logical_sample_index
		c.end_index_exclusive = p_logical_sample_index + 1
		c.count_after = _y_buffers[idx].size()
		_emit_or_batch_change(c)


	func set_series_y_slice(p_series_id: int, p_start_index: int, p_values: PackedFloat64Array) -> void:
		var idx := _require_series_exists(p_series_id)
		if idx < 0:
			return

		var written := _y_buffers[idx].set_values(p_start_index, p_values)
		if written <= 0:
			return

		var c := DatasetChange.new()
		c.type = DatasetChange.Type.VALUES_CHANGED
		c.flags = DatasetChange.Flags.Y_CHANGED
		c.series_ids = PackedInt64Array([p_series_id])
		c.start_index = p_start_index
		c.end_index_exclusive = p_start_index + written
		c.count_after = _y_buffers[idx].size()
		_emit_or_batch_change(c)


	func append_shared_sample(p_x: Variant, p_y_values: PackedFloat64Array) -> void:
		if _mode != Mode.SHARED_X:
			push_error("Dataset.append_shared_sample(): only valid in SHARED_X mode")
			return

		if _x_buffers.size() != 1:
			push_error("Dataset.append_shared_sample(): shared-X requires exactly one X buffer")
			return

		if p_y_values.size() != _y_buffers.size():
			push_error("Dataset.append_shared_sample(): expected %d y values, got %d" % [_y_buffers.size(), p_y_values.size()])
			return

		var xb = _x_buffers[0]
		var dropped = xb.append_value(p_x)

		var dropped_y := 0
		for i in range(_y_buffers.size()):
			dropped_y = max(dropped_y, _y_buffers[i].append_value(p_y_values[i]))

		if dropped_y != dropped:
			push_error("Dataset.append_shared_sample(): X/Y overwrite mismatch (x=%d y=%d)" % [dropped, dropped_y])
			dropped = max(dropped, dropped_y)

		var c := DatasetChange.new()
		c.type = DatasetChange.Type.VALUES_APPENDED
		c.flags = DatasetChange.Flags.X_CHANGED | DatasetChange.Flags.Y_CHANGED
		c.series_ids = _series_ids.duplicate()
		c.appended_count = 1
		c.dropped_count = dropped
		c.count_after = xb.size()
		c.start_index = xb.size() - 1
		c.end_index_exclusive = xb.size()
		if dropped > 0:
			c.flags |= DatasetChange.Flags.OVERWROTE_OLD_SAMPLES
		_emit_or_batch_change(c)


	func append_sample_to_one_series(p_series_id: int, p_x: Variant, p_y: float) -> void:
		if _mode != Mode.PER_SERIES_X:
			push_error("Dataset.append_sample_to_one_series(): only valid in PER_SERIES_X mode")
			return

		var idx := _require_series_exists(p_series_id)
		if idx < 0:
			return

		if _x_buffers.size() != _series_ids.size():
			push_error("Dataset.append_sample_to_one_series(): per-series-X requires one X buffer per series")
			return

		var xb = _x_buffers[idx]
		var yb := _y_buffers[idx]

		var dropped_x = xb.append_value(p_x)
		var dropped_y := yb.append_value(p_y)

		if dropped_x != dropped_y:
			push_error("Dataset.append_sample_to_one_series(): X/Y overwrite mismatch (x=%d y=%d) series_id=%d" % [dropped_x, dropped_y, p_series_id])

		var dropped := max(dropped_x, dropped_y)

		var c := DatasetChange.new()
		c.type = DatasetChange.Type.VALUES_APPENDED
		c.flags = DatasetChange.Flags.X_CHANGED | DatasetChange.Flags.Y_CHANGED
		c.series_ids = PackedInt64Array([p_series_id])
		c.appended_count = 1
		c.dropped_count = dropped
		c.count_after = yb.size()
		c.start_index = yb.size() - 1
		c.end_index_exclusive = yb.size()
		if dropped > 0:
			c.flags |= DatasetChange.Flags.OVERWROTE_OLD_SAMPLES
		_emit_or_batch_change(c)


	func clear_samples() -> void:
		if _mode == Mode.SHARED_X:
			if _x_buffers.size() == 1:
				_x_buffers[0].clear()
			for yb in _y_buffers:
				yb.clear()
		else:
			for xb in _x_buffers:
				xb.clear()
			for yb in _y_buffers:
				yb.clear()

		var c := DatasetChange.new()
		c.type = DatasetChange.Type.RESET
		c.flags = DatasetChange.Flags.X_CHANGED | DatasetChange.Flags.Y_CHANGED
		c.series_ids = _series_ids.duplicate()
		c.count_after = get_shared_sample_count() if _mode == Mode.SHARED_X else 0
		_emit_or_batch_change(c)


	func reset() -> void:
		var previous_series_ids := _series_ids.duplicate()

		_series_ids = []
		_series_names = []
		_y_buffers = []
		_x_buffers = []

		if _mode == Mode.SHARED_X:
			match _x_element_type:
				XElementType.CATEGORY:
					_x_buffers.append(StringBuffer.new(_shared_capacity))
				XElementType.NUMERIC:
					_x_buffers.append(Float64Buffer.new(_shared_capacity))
				_:
					push_error("Dataset(): unexpected X element type")

		var c := DatasetChange.new()
		c.type = DatasetChange.Type.RESET
		c.flags = DatasetChange.Flags.SERIES_STRUCTURE_CHANGED | DatasetChange.Flags.X_CHANGED | DatasetChange.Flags.Y_CHANGED
		c.series_ids = previous_series_ids
		c.count_after = 0
		_emit_or_batch_change(c)


	####################################################################################################
	# Private
	####################################################################################################

	func _add_series_internal(p_series_name: String, p_capacity: int, p_initial_y_values: PackedFloat64Array) -> int:
		var id := _next_series_id
		_next_series_id += 1

		_series_ids.append(id)
		_series_names.append(p_series_name)

		if _mode == Mode.PER_SERIES_X:
			var cap := max(p_capacity, 1)
			match _x_element_type:
				XElementType.CATEGORY:
					_x_buffers.append(StringBuffer.new(cap))
				XElementType.NUMERIC:
					_x_buffers.append(Float64Buffer.new(cap))
				_:
					push_error("Dataset(): unexpected X element type")
			_y_buffers.append(Float64Buffer.new(cap))
		else:
			var yb := Float64Buffer.new(_shared_capacity)
			for v in p_initial_y_values:
				yb.append_value(float(v))
			_y_buffers.append(yb)

		var c := DatasetChange.new()
		c.type = DatasetChange.Type.SERIES_ADDED
		c.flags = DatasetChange.Flags.SERIES_STRUCTURE_CHANGED
		c.series_ids = PackedInt64Array([id])
		c.count_after = get_shared_sample_count() if _mode == Mode.SHARED_X else 0
		_emit_or_batch_change(c)

		return id


	func _emit_or_batch_change(p_change: DatasetChange) -> void:
		if not _is_batching:
			changed.emit(p_change)
			return

		_merge_change_into_batch(p_change)


	func _merge_change_into_batch(p_change: DatasetChange) -> void:
		if p_change == null:
			return

		_batched_change.flags |= p_change.flags

		# RESET dominates everything.
		if p_change.type == DatasetChange.Type.RESET:
			_batched_change.type = DatasetChange.Type.RESET
			_batched_change.count_after = p_change.count_after
			_batched_change.appended_count = 0
			_batched_change.dropped_count = 0
			_batched_change.start_index = 0
			_batched_change.end_index_exclusive = 0
			_batched_change.series_ids = p_change.series_ids.duplicate()
			_batched_change.new_order_series_ids = PackedInt64Array()
			return

		# Aggregate VALUES_APPENDED information.
		if p_change.type == DatasetChange.Type.VALUES_APPENDED:
			_batched_change.appended_count += p_change.appended_count
			_batched_change.dropped_count += p_change.dropped_count
			_batched_change.count_after = max(_batched_change.count_after, p_change.count_after)

		# Aggregate index range for VALUES_CHANGED and VALUES_APPENDED.
		if p_change.type == DatasetChange.Type.VALUES_CHANGED or p_change.type == DatasetChange.Type.VALUES_APPENDED:
			if _batched_change.start_index == 0 and _batched_change.end_index_exclusive == 0:
				_batched_change.start_index = p_change.start_index
				_batched_change.end_index_exclusive = p_change.end_index_exclusive
			else:
				_batched_change.start_index = min(_batched_change.start_index, p_change.start_index)
				_batched_change.end_index_exclusive = max(_batched_change.end_index_exclusive, p_change.end_index_exclusive)
			_batched_change.count_after = max(_batched_change.count_after, p_change.count_after)

		# Merge affected series ids (unique set).
		if not p_change.series_ids.is_empty():
			var set := {}
			for id_v in _batched_change.series_ids:
				set[id_v] = true
			for id_v in p_change.series_ids:
				set[id_v] = true

			var merged := PackedInt64Array()
			for k in set.keys():
				merged.append(k)
			_batched_change.series_ids = merged

		# Keep the latest reorder payload if present.
		if not p_change.new_order_series_ids.is_empty():
			_batched_change.new_order_series_ids = p_change.new_order_series_ids.duplicate()


	func _require_series_exists(p_series_id: int) -> int:
		var idx := get_series_index_by_id(p_series_id)
		if idx < 0:
			push_error("Dataset: unknown series_id %d" % p_series_id)
		return idx
