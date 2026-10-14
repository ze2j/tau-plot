## The secondary x axis transform, read over the current primary x range.
##
## The transform maps a primary x value to a secondary x value. It is sampled
## at evenly spaced points of the primary x range, in the primary scale. The
## samples tell whether the range is valid, and bracket the primary value a
## secondary value comes from. A bisection between the two bracketing samples
## then finds that primary value, so the transform never needs an inverse.
class SecondaryXTransform extends RefCounted:
	# A transform that curves between two samples still inverts exactly, the
	# bisection takes care of it. The samples only have to be dense enough to
	# catch a transform that is not monotonic.
	const _SAMPLE_INTERVAL_COUNT: int = 64

	# Each step halves the bracket. The first bracket is one sample interval,
	# so after these steps the primary value is known far below a pixel.
	const _BISECTION_STEP_COUNT: int = 24

	var _transform: Callable
	var _primary_min: float
	var _primary_max: float
	var _primary_is_log: bool

	# One entry per sample, ordered by primary value.
	var _primary_samples := PackedFloat64Array()
	var _secondary_samples := PackedFloat64Array()

	# Optimization. Each secondary value is inverted once, then read back. The
	# same tick values are located again by every overlap check and every pane.
	var _primary_value_cache: Dictionary[float, float] = {}


	## [param p_transform] Maps a primary x value to a secondary x value.
	## [param p_primary_min] Primary x range minimum, below [param p_primary_max].
	## [param p_primary_max] Primary x range maximum.
	## [param p_primary_is_log] True when the primary x axis is logarithmic.
	func _init(p_transform: Callable, p_primary_min: float, p_primary_max: float, p_primary_is_log: bool) -> void:
		_transform = p_transform
		_primary_min = p_primary_min
		_primary_max = p_primary_max
		_primary_is_log = p_primary_is_log

		_primary_samples.resize(_SAMPLE_INTERVAL_COUNT + 1)
		_secondary_samples.resize(_SAMPLE_INTERVAL_COUNT + 1)
		for i in range(_SAMPLE_INTERVAL_COUNT + 1):
			var primary_value := _interpolate_primary(float(i) / float(_SAMPLE_INTERVAL_COUNT))
			_primary_samples[i] = primary_value
			_secondary_samples[i] = _transform.call(primary_value)


	## Returns why the secondary range is invalid, or an empty string when it
	## is valid. The range is invalid when a sample is NaN or infinite, when the
	## samples are not strictly monotonic, or when [param p_requires_positive]
	## is true and a sample is not strictly positive.
	func find_invalid_reason(p_requires_positive: bool) -> String:
		for value in _secondary_samples:
			if not is_finite(value):
				return "secondary_x_axis_transform returns NaN or infinity"

		var direction := _get_direction()
		if direction == 0.0:
			return "secondary_x_axis_transform is not monotonic"
		for i in range(1, _secondary_samples.size()):
			if signf(_secondary_samples[i] - _secondary_samples[i - 1]) != direction:
				return "secondary_x_axis_transform is not monotonic"

		if p_requires_positive and get_secondary_min() <= 0.0:
			return "the secondary range is not strictly positive while secondary_x_axis.scale is LOGARITHMIC"

		return ""


	## Returns the smallest secondary value over the primary x range.
	func get_secondary_min() -> float:
		return minf(_secondary_samples[0], _secondary_samples[_SAMPLE_INTERVAL_COUNT])


	## Returns the largest secondary value over the primary x range.
	func get_secondary_max() -> float:
		return maxf(_secondary_samples[0], _secondary_samples[_SAMPLE_INTERVAL_COUNT])


	## Returns the primary x value whose transform gives [param p_secondary_value].
	## A value outside the secondary range returns the nearest primary bound.
	## Requires a valid range.
	func find_primary_value(p_secondary_value: float) -> float:
		if _primary_value_cache.has(p_secondary_value):
			return _primary_value_cache[p_secondary_value]
		var primary_value := _invert(p_secondary_value)
		_primary_value_cache[p_secondary_value] = primary_value
		return primary_value


	## Returns where [param p_secondary_value] sits along the primary x axis,
	## in the primary scale: 0 at the primary minimum, 1 at the primary maximum.
	## Requires a valid range.
	func find_primary_fraction(p_secondary_value: float) -> float:
		var primary_value := find_primary_value(p_secondary_value)
		if _primary_is_log:
			return log(primary_value / _primary_min) / log(_primary_max / _primary_min)
		return (primary_value - _primary_min) / (_primary_max - _primary_min)


	# Returns the primary value at p_fraction of the primary x range, in the
	# primary scale.
	func _interpolate_primary(p_fraction: float) -> float:
		if _primary_is_log:
			return _primary_min * pow(_primary_max / _primary_min, p_fraction)
		return lerpf(_primary_min, _primary_max, p_fraction)


	# Returns 1 when the transform increases, -1 when it decreases, 0 when its
	# two ends are equal.
	func _get_direction() -> float:
		return signf(_secondary_samples[_SAMPLE_INTERVAL_COUNT] - _secondary_samples[0])


	func _invert(p_secondary_value: float) -> float:
		# Multiplying by the direction turns a decreasing transform into an
		# increasing one, so one comparison serves both.
		var direction := _get_direction()
		if direction * (p_secondary_value - _secondary_samples[0]) <= 0.0:
			return _primary_samples[0]
		if direction * (p_secondary_value - _secondary_samples[_SAMPLE_INTERVAL_COUNT]) >= 0.0:
			return _primary_samples[_SAMPLE_INTERVAL_COUNT]

		var upper := 1
		while direction * (_secondary_samples[upper] - p_secondary_value) < 0.0:
			upper += 1

		var low := _primary_samples[upper - 1]
		var high := _primary_samples[upper]
		for _step in range(_BISECTION_STEP_COUNT):
			var middle := (low + high) * 0.5
			if direction * (float(_transform.call(middle)) - p_secondary_value) < 0.0:
				low = middle
			else:
				high = middle
		return (low + high) * 0.5
