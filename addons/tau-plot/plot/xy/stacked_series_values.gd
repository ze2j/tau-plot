const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const StackedNormalization := preload("res://addons/tau-plot/plot/xy/stacked_normalization.gd").StackedNormalization
const StackedNegativePolicy := preload("res://addons/tau-plot/plot/xy/stacked_negative_policy.gd").StackedNegativePolicy


## Per-(series, sample) cumulative values for a stacked overlay.
##
## Built from an ordered list of stacked series sharing a SHARED_X dataset.
## Layer order matches the order of series_ids: layer 0 sits at the bottom.
##
## Values are read through [method get_y_plotted], [method get_y_baseline],
## and [method get_y_raw], all keyed by (series_local, sample_index).
## series_local matches the position of the corresponding series_id in the
## list passed at construction. NAN means the sample is dropped (NaN/Inf
## in the dataset, or removed by the active negative policy) and must be
## ignored by the caller.
class StackedSeriesValues extends RefCounted:

	var _series_count: int = 0
	var _sample_count: int = 0

	# Flat layout sidesteps the copy-on-write of nested
	# Array[PackedFloat64Array] element access in GDScript, where reading
	# an element into a local yields a copy and breaks in-place mutation.
	# Index = series_local * _sample_count + sample_index.
	var _y_plotted: PackedFloat64Array = PackedFloat64Array()
	var _y_baseline: PackedFloat64Array = PackedFloat64Array()
	var _y_raw: PackedFloat64Array = PackedFloat64Array()


	## p_series_ids must already be in stacking order (layer 0 first) and
	## refer to series of the SHARED_X p_dataset.
	func _init(p_dataset: Dataset, p_series_ids: PackedInt64Array,
				p_normalization: StackedNormalization,
				p_negative_policy: StackedNegativePolicy) -> void:
		_series_count = p_series_ids.size()
		_sample_count = p_dataset.get_shared_sample_count()

		var cell_count := _series_count * _sample_count
		_y_plotted.resize(cell_count)
		_y_plotted.fill(NAN)
		_y_baseline.resize(cell_count)
		_y_baseline.fill(NAN)
		_y_raw.resize(cell_count)
		_y_raw.fill(NAN)

		_fill_y_raw(p_dataset, p_series_ids)

		for sample_index in range(_sample_count):
			var pos_scale := 1.0
			var neg_scale := 1.0
			if p_normalization != StackedNormalization.NONE:
				var totals := _per_x_totals(sample_index, p_negative_policy)
				var pos_total: float = totals.x
				var neg_total_abs: float = totals.y
				match p_normalization:
					StackedNormalization.FRACTION:
						pos_scale = 1.0 / pos_total if pos_total > 0.0 else 0.0
						neg_scale = 1.0 / neg_total_abs if neg_total_abs > 0.0 else 0.0
					StackedNormalization.PERCENT:
						pos_scale = 100.0 / pos_total if pos_total > 0.0 else 0.0
						neg_scale = 100.0 / neg_total_abs if neg_total_abs > 0.0 else 0.0

			match p_negative_policy:
				StackedNegativePolicy.SKIP_NEGATIVES:
					_accumulate_skip_negatives(sample_index, pos_scale)
				StackedNegativePolicy.DIVERGING:
					_accumulate_diverging(sample_index, pos_scale, neg_scale)
				StackedNegativePolicy.SIGNED_SUM:
					_accumulate_signed_sum(sample_index, pos_scale)


	## Painted top of this (series, sample) in data units.
	func get_y_plotted(p_series_local: int, p_sample_index: int) -> float:
		return _y_plotted[p_series_local * _sample_count + p_sample_index]


	## Painted top of the layer below this (series, sample) in the same
	## half-stack, or 0.0 for the bottom-most contribution at this X.
	func get_y_baseline(p_series_local: int, p_sample_index: int) -> float:
		return _y_baseline[p_series_local * _sample_count + p_sample_index]


	## Original dataset value at this (series, sample), before stacking,
	## normalization, or accumulation.
	func get_y_raw(p_series_local: int, p_sample_index: int) -> float:
		return _y_raw[p_series_local * _sample_count + p_sample_index]


	####################################################################################################
	# Private
	####################################################################################################

	# Negative-policy filtering belongs to the accumulation step, so this
	# pass keeps every finite raw value regardless of sign.
	func _fill_y_raw(p_dataset: Dataset, p_series_ids: PackedInt64Array) -> void:
		for series_local in range(_series_count):
			var series_id := p_series_ids[series_local]
			var row_offset := series_local * _sample_count
			for sample_index in range(_sample_count):
				var v := p_dataset.get_series_y(series_id, sample_index)
				if is_nan(v) or is_inf(v):
					continue
				_y_raw[row_offset + sample_index] = v


	# DIVERGING is the only policy that needs the absolute negative total.
	# The other policies leave it at zero.
	func _per_x_totals(p_sample_index: int, p_policy: StackedNegativePolicy) -> Vector2:
		var pos_total := 0.0
		var neg_total_abs := 0.0
		for series_local in range(_series_count):
			var v: float = _y_raw[series_local * _sample_count + p_sample_index]
			if is_nan(v):
				continue
			match p_policy:
				StackedNegativePolicy.SKIP_NEGATIVES:
					if v >= 0.0:
						pos_total += v
				StackedNegativePolicy.DIVERGING:
					if v >= 0.0:
						pos_total += v
					else:
						neg_total_abs += -v
				StackedNegativePolicy.SIGNED_SUM:
					pos_total += v
		return Vector2(pos_total, neg_total_abs)


	func _accumulate_skip_negatives(p_sample_index: int, p_pos_scale: float) -> void:
		var accum_pos := 0.0
		for series_local in range(_series_count):
			var idx := series_local * _sample_count + p_sample_index
			var v: float = _y_raw[idx]
			if is_nan(v) or v < 0.0:
				continue
			var scaled := v * p_pos_scale
			_y_baseline[idx] = accum_pos
			accum_pos += scaled
			_y_plotted[idx] = accum_pos


	func _accumulate_diverging(p_sample_index: int, p_pos_scale: float, p_neg_scale: float) -> void:
		var accum_pos := 0.0
		var accum_neg := 0.0
		for series_local in range(_series_count):
			var idx := series_local * _sample_count + p_sample_index
			var v: float = _y_raw[idx]
			if is_nan(v):
				continue
			if v >= 0.0:
				var scaled := v * p_pos_scale
				_y_baseline[idx] = accum_pos
				accum_pos += scaled
				_y_plotted[idx] = accum_pos
			else:
				var scaled := v * p_neg_scale
				_y_baseline[idx] = accum_neg
				accum_neg += scaled
				_y_plotted[idx] = accum_neg


	# A negative contribution dips the cumulative below the previous layer,
	# producing the streamgraph pattern. The baseline of layer N is always
	# the painted top of layer N-1, even when that top went down.
	func _accumulate_signed_sum(p_sample_index: int, p_scale: float) -> void:
		var accum := 0.0
		for series_local in range(_series_count):
			var idx := series_local * _sample_count + p_sample_index
			var v: float = _y_raw[idx]
			if is_nan(v):
				continue
			var scaled := v * p_scale
			_y_baseline[idx] = accum
			accum += scaled
			_y_plotted[idx] = accum
