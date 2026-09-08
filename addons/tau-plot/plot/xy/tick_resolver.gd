# Dependencies
const TickSequence := preload("res://addons/tau-plot/plot/xy/tick_sequence.gd").TickSequence

# Resolves tick positions and label visibility for axes.
# Handles both continuous (numeric) and categorical (string) axes.
class TickResolver extends RefCounted:

	const _NICE_STEP_MULTIPLIERS: Array[float] = [1.0, 2.0, 2.5, 5.0]
	const _MAX_DECIMALS: int = 12

	# Log scale constants
	const _LOG_MINOR_TICKS: Array[float] = [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
	const _MIN_PIXELS_PER_MINOR_TICK: float = 2.0

	################################################################################################
	# Continuous Axes
	################################################################################################

	static func compute_ticks_for_continuous_axis(p_axis_min: float,
			p_axis_max: float,
			p_scale: TauAxisConfig.Scale,
			p_count_preferred: int,
			p_overlap_strategy: TauAxisConfig.OverlapStrategy,
			p_available_pixels: float,
			p_min_spacing_px: float,
			p_measure_label_func: Callable) -> TickSequence:

		match p_scale:
			TauAxisConfig.Scale.LOGARITHMIC:
				return _compute_log_ticks_with_overlap_handling(
					p_axis_min, p_axis_max, p_count_preferred, p_overlap_strategy,
					p_available_pixels, p_min_spacing_px, p_measure_label_func
				)

			TauAxisConfig.Scale.LINEAR:
				return _compute_linear_ticks_with_overlap_handling(
					p_axis_min, p_axis_max, p_count_preferred,
					p_overlap_strategy, p_available_pixels, p_min_spacing_px, p_measure_label_func
				)

			_:
				push_error("TickResolver: Unknown scale type %d" % p_scale)
				return TickSequence.new()

	################################################################################################
	# Categorical Axes
	################################################################################################

	static func compute_categorical_label_visibility(p_categories: PackedStringArray,
			p_overlap_strategy: TauAxisConfig.OverlapStrategy,
			p_available_pixels: float,
			p_min_spacing_px: float,
			p_measure_label_func: Callable) -> PackedInt32Array:

		var category_count := p_categories.size()
		if category_count == 0:
			return PackedInt32Array()

		match p_overlap_strategy:
			TauAxisConfig.OverlapStrategy.REDUCE_COUNT:
				push_warning("TickResolver: REDUCE_COUNT invalid for categorical axes. Using SKIP_LABELS.")
				p_overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

			TauAxisConfig.OverlapStrategy.NONE:
				return PackedInt32Array()

			TauAxisConfig.OverlapStrategy.SKIP_LABELS:
				pass

			_:
				push_warning("TickResolver: Strategy not implemented for categorical, using NONE")
				return PackedInt32Array()

		var would_pair_overlap := _make_category_pair_overlap_func(
			p_categories, p_available_pixels, p_min_spacing_px, p_measure_label_func
		)

		if not _would_any_labeled_pair_overlap(_make_all_indices(category_count), would_pair_overlap):
			return PackedInt32Array()

		var skip_factor := 2
		while skip_factor <= category_count:
			var visible_indices := _compute_labeled_indices_with_skip(category_count, skip_factor, would_pair_overlap)

			if not _would_any_labeled_pair_overlap(visible_indices, would_pair_overlap):
				return visible_indices

			skip_factor += 1

		if category_count >= 2:
			return PackedInt32Array([0, category_count - 1])
		return PackedInt32Array([0])

	################################################################################################
	# Linear Scales
	################################################################################################

	static func _compute_linear_ticks_with_overlap_handling(p_axis_min: float,
			p_axis_max: float,
			p_count_preferred: int,
			p_overlap_strategy: TauAxisConfig.OverlapStrategy,
			p_available_pixels: float,
			p_min_spacing_px: float,
			p_measure_label_func: Callable) -> TickSequence:

		var tick_info := _compute_nice_linear_ticks(p_axis_min, p_axis_max, p_count_preferred)
		if tick_info == null:
			return TickSequence.new()

		match p_overlap_strategy:
			TauAxisConfig.OverlapStrategy.NONE:
				return _make_ticks_all_labeled(tick_info.ticks, tick_info, false)

			TauAxisConfig.OverlapStrategy.REDUCE_COUNT:
				return _resolve_overlap_by_reducing_count(
					tick_info, p_axis_min, p_axis_max,
					p_available_pixels, p_min_spacing_px, p_measure_label_func
				)

			TauAxisConfig.OverlapStrategy.SKIP_LABELS:
				return _resolve_overlap_by_skipping_labels(
					tick_info, p_axis_min, p_axis_max, false,
					p_available_pixels, p_min_spacing_px, p_measure_label_func
				)

			_:
				push_warning("TickResolver: Strategy not implemented, using NONE")
				return _make_ticks_all_labeled(tick_info.ticks, tick_info, false)


	static func _resolve_overlap_by_reducing_count(p_initial_tick_info: _TickInfo,
			p_axis_min: float,
			p_axis_max: float,
			p_available_pixels: float,
			p_min_spacing_px: float,
			p_measure_label_func: Callable) -> TickSequence:

		var axis_ruler := _AxisRuler.new(p_axis_min, p_axis_max, p_available_pixels, false)
		var current_preferred := p_initial_tick_info.ticks.size()

		while current_preferred >= 2:
			var tick_info := _compute_nice_linear_ticks(p_axis_min, p_axis_max, current_preferred)
			if tick_info == null:
				break

			# The step drives the decimals, so a new tick set formats differently.
			var measure_tick_label := _make_tick_label_measure_func(tick_info.decimals, false, p_measure_label_func)
			var would_pair_overlap := _make_tick_pair_overlap_func(
				tick_info.ticks, axis_ruler, p_min_spacing_px, measure_tick_label
			)
			var all_indices := _make_all_indices(tick_info.ticks.size())

			if not _would_any_labeled_pair_overlap(all_indices, would_pair_overlap):
				return _make_ticks_all_labeled(tick_info.ticks, tick_info, false)

			current_preferred -= 1

		return TickSequence.new()


	# Keeps every tick and removes labels until no two of them overlap.
	static func _resolve_overlap_by_skipping_labels(p_tick_info: _TickInfo,
			p_axis_min: float,
			p_axis_max: float,
			p_is_log_axis: bool,
			p_available_pixels: float,
			p_min_spacing_px: float,
			p_measure_label_func: Callable) -> TickSequence:

		var all_ticks := p_tick_info.ticks
		var decimals := p_tick_info.decimals
		var axis_ruler := _AxisRuler.new(p_axis_min, p_axis_max, p_available_pixels, p_is_log_axis)
		var measure_tick_label := _make_tick_label_measure_func(decimals, false, p_measure_label_func)
		var would_pair_overlap := _make_tick_pair_overlap_func(
			all_ticks, axis_ruler, p_min_spacing_px, measure_tick_label
		)
		var skip_factor := 1

		while skip_factor < all_ticks.size():
			var labeled_indices := _compute_labeled_indices_with_skip(all_ticks.size(), skip_factor, would_pair_overlap)

			if not _would_any_labeled_pair_overlap(labeled_indices, would_pair_overlap):
				return TickSequence.new(all_ticks, [], labeled_indices, PackedInt32Array(), decimals, false, false)

			skip_factor += 1

		if all_ticks.size() >= 2:
			return TickSequence.new(all_ticks, [], PackedInt32Array([0, all_ticks.size() - 1]), PackedInt32Array(), decimals, false, false)

		return TickSequence.new(all_ticks, [], PackedInt32Array([0]), PackedInt32Array(), decimals, false, false)

	################################################################################################
	# Logarithmic Scales
	################################################################################################

	static func _compute_log_ticks_with_overlap_handling(p_axis_min: float,
			p_axis_max: float,
			p_count_preferred: int,
			p_overlap_strategy: TauAxisConfig.OverlapStrategy,
			p_available_pixels: float,
			p_min_spacing_px: float,
			p_measure_label_func: Callable) -> TickSequence:

		if p_axis_min <= 0.0 or p_axis_max <= 0.0 or p_axis_min >= p_axis_max:
			push_error("TickResolver: Invalid log domain")
			return TickSequence.new()

		# A logarithmic axis takes its ticks from the powers of ten, so it has no
		# tick count to reduce.
		if p_overlap_strategy == TauAxisConfig.OverlapStrategy.REDUCE_COUNT:
			push_warning("TickResolver: REDUCE_COUNT invalid for logarithmic axes. Using SKIP_LABELS.")
			p_overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

		var major_ticks := _compute_log_major_ticks(p_axis_min, p_axis_max)
		var minor_ticks := _compute_log_minor_ticks(p_axis_min, p_axis_max, p_available_pixels)

		# A domain such as [1.01, 1.05] holds no power of ten and no coefficient
		# position either. Fewer than two ticks read as an empty axis, so round
		# values replace the logarithmic tick set.
		if major_ticks.size() + minor_ticks.size() < 2:
			return _compute_round_value_fallback_ticks(
				p_axis_min, p_axis_max, p_count_preferred, p_overlap_strategy,
				p_available_pixels, p_min_spacing_px, p_measure_label_func
			)

		# A domain narrower than one decade holds no power of ten. The minor
		# ticks then carry the labels, and keep their rank and their style.
		var labels_sit_on_minor := major_ticks.is_empty()
		var candidate_ticks: Array[float] = minor_ticks if labels_sit_on_minor else major_ticks

		var labeled_indices: PackedInt32Array

		match p_overlap_strategy:
			TauAxisConfig.OverlapStrategy.NONE:
				labeled_indices = _make_all_indices(candidate_ticks.size())

			_:
				labeled_indices = _determine_labeled_log_ticks(
					candidate_ticks, p_axis_min, p_axis_max,
					p_available_pixels, p_min_spacing_px, p_measure_label_func
				)

		var labeled_major_indices: PackedInt32Array = PackedInt32Array() if labels_sit_on_minor else labeled_indices
		var labeled_minor_indices: PackedInt32Array = labeled_indices if labels_sit_on_minor else PackedInt32Array()

		return TickSequence.new(
			major_ticks, minor_ticks,
			labeled_major_indices, labeled_minor_indices,
			0, false, true
		)


	# Returns round value ticks for a logarithmic domain too narrow to hold two
	# logarithmic ticks.
	#
	# The axis stays logarithmic. Only the way the tick values are picked
	# changes. The renderer still places them through the logarithmic
	# transform, so they are evenly spaced in value but not in pixels.
	#
	# The ticks are all major and all label candidates. Their text comes from
	# the linear formatter, so the step decides the decimals.
	static func _compute_round_value_fallback_ticks(p_axis_min: float,
			p_axis_max: float,
			p_count_preferred: int,
			p_overlap_strategy: TauAxisConfig.OverlapStrategy,
			p_available_pixels: float,
			p_min_spacing_px: float,
			p_measure_label_func: Callable) -> TickSequence:

		var tick_info := _compute_nice_linear_ticks(p_axis_min, p_axis_max, p_count_preferred)
		if tick_info == null:
			return TickSequence.new()

		match p_overlap_strategy:
			TauAxisConfig.OverlapStrategy.NONE:
				return _make_ticks_all_labeled(tick_info.ticks, tick_info, false)

			_:
				return _resolve_overlap_by_skipping_labels(
					tick_info, p_axis_min, p_axis_max, true,
					p_available_pixels, p_min_spacing_px, p_measure_label_func
				)


	static func _compute_log_major_ticks(p_min: float, p_max: float) -> Array[float]:
		var log_min := log(p_min) / log(10.0)
		var log_max := log(p_max) / log(10.0)
		var first_exp := int(ceil(log_min))
		var last_exp := int(floor(log_max))

		var major_ticks: Array[float] = []
		for exp in range(first_exp, last_exp + 1):
			var tick_val := pow(10.0, float(exp))
			if tick_val >= p_min and tick_val <= p_max:
				major_ticks.append(tick_val)

		return major_ticks


	static func _compute_log_minor_ticks(p_min: float,  p_max: float, p_available_pixels: float) -> Array[float]:
		var first_exp := int(floor(log(p_min) / log(10.0)))
		var last_exp := int(floor(log(p_max) / log(10.0)))

		# Ascending by construction: 9 * 10^k stays below 2 * 10^(k+1).
		var all_ticks: Array[float] = []
		for exp in range(first_exp, last_exp + 1):
			var decade := pow(10.0, float(exp))
			for minor_mult in _LOG_MINOR_TICKS:
				var tick_val: float = decade * minor_mult
				if tick_val >= p_min and tick_val <= p_max:
					all_ticks.append(tick_val)

		var pixels_per_tick: float = p_available_pixels / max(float(all_ticks.size()), 1.0)
		if pixels_per_tick < _MIN_PIXELS_PER_MINOR_TICK:
			return []

		return all_ticks


	# Returns the indices of the candidates that carry a label. The candidates
	# are the ticks of one rank, so the returned indices point into that rank.
	static func _determine_labeled_log_ticks(p_candidate_ticks: Array[float],
			p_axis_min: float,
			p_axis_max: float,
			p_available_pixels: float,
			p_min_spacing_px: float,
			p_measure_label_func: Callable) -> PackedInt32Array:

		var axis_ruler := _AxisRuler.new(p_axis_min, p_axis_max, p_available_pixels, true)
		var measure_tick_label := _make_tick_label_measure_func(0, true, p_measure_label_func)
		var would_pair_overlap := _make_tick_pair_overlap_func(
			p_candidate_ticks, axis_ruler, p_min_spacing_px, measure_tick_label
		)
		var skip_factor := 1

		while skip_factor < p_candidate_ticks.size():
			var labeled_indices := _compute_labeled_indices_with_skip(p_candidate_ticks.size(), skip_factor, would_pair_overlap)

			if not _would_any_labeled_pair_overlap(labeled_indices, would_pair_overlap):
				return labeled_indices

			skip_factor += 1

		if p_candidate_ticks.size() >= 2:
			return PackedInt32Array([0, p_candidate_ticks.size() - 1])
		return _make_all_indices(p_candidate_ticks.size())

	################################################################################################
	# Categorical
	################################################################################################

	# Returns a function that tells whether the labels of two categories
	# overlap, given their positions in the category array.
	#
	# A categorical axis gives one slot to each category, so the category index
	# is the axis value and the domain runs from 0 to the category count.
	static func _make_category_pair_overlap_func(p_categories: PackedStringArray,
			p_available_pixels: float,
			p_min_spacing_px: float,
			p_measure_label_func: Callable) -> Callable:

		var axis_ruler := _AxisRuler.new(0.0, float(p_categories.size()), p_available_pixels, false)
		var measure_category_label := func(p_position: float) -> Vector2:
			return p_measure_label_func.call(p_categories[int(p_position)])

		return func(p_first_index: int, p_second_index: int) -> bool:
			return _would_label_pair_overlap(
				float(p_first_index), float(p_second_index),
				axis_ruler, p_min_spacing_px, measure_category_label
			)

	################################################################################################
	# Overlap Detection
	################################################################################################

	# Measures the pixel distance between two values of one axis.
	#
	# The distance comes from the axis domain and the pixel length of the axis,
	# which is the ratio the renderer uses to place a value. The axis origin and
	# [member TauAxisConfig.inverted] are left out because neither changes a
	# distance.
	class _AxisRuler extends RefCounted:
		var _is_log_scale: bool = false
		var _pixels_per_unit: float = 0.0

		func _init(p_axis_min: float,
				p_axis_max: float,
				p_available_pixels: float,
				p_is_log_scale: bool) -> void:
			_is_log_scale = p_is_log_scale
			var domain_span := _convert_value_to_axis_unit(p_axis_max) - _convert_value_to_axis_unit(p_axis_min)
			_pixels_per_unit = p_available_pixels / domain_span

		## Returns the pixel distance between two axis values. Never negative.
		func measure_distance_px(p_first_value: float, p_second_value: float) -> float:
			var unit_span := _convert_value_to_axis_unit(p_second_value) - _convert_value_to_axis_unit(p_first_value)
			return absf(unit_span) * _pixels_per_unit

		# A logarithmic axis is linear in the logarithm of the value, which is
		# where the renderer places it. The base cancels in the ratio, so the raw
		# log() is used.
		func _convert_value_to_axis_unit(p_value: float) -> float:
			return log(p_value) if _is_log_scale else p_value


	# Tells whether the labels of two ticks overlap. They overlap when the space
	# the two labels need is wider than the pixel distance between the ticks.
	static func _would_label_pair_overlap(p_first_value: float,
			p_second_value: float,
			p_axis_ruler: _AxisRuler,
			p_min_spacing_px: float,
			p_measure_tick_label_func: Callable) -> bool:

		var first_size: Vector2 = p_measure_tick_label_func.call(p_first_value)
		var second_size: Vector2 = p_measure_tick_label_func.call(p_second_value)
		var needed_px := (first_size.x * 0.5) + (second_size.x * 0.5) + p_min_spacing_px
		return needed_px > p_axis_ruler.measure_distance_px(p_first_value, p_second_value)


	# Tells whether any two neighbouring labels overlap.
	#
	# The indices point into the candidate array, in axis order.
	static func _would_any_labeled_pair_overlap(p_labeled_indices: PackedInt32Array,
			p_would_pair_overlap_func: Callable) -> bool:

		for i in range(p_labeled_indices.size() - 1):
			if p_would_pair_overlap_func.call(p_labeled_indices[i], p_labeled_indices[i + 1]):
				return true

		return false


	# Returns a function that tells whether the labels of two ticks overlap,
	# given their positions in the tick array. It holds the ruler and the label
	# measurement, so the label selection works on indices alone.
	static func _make_tick_pair_overlap_func(p_ticks: Array[float],
			p_axis_ruler: _AxisRuler,
			p_min_spacing_px: float,
			p_measure_tick_label_func: Callable) -> Callable:

		return func(p_first_index: int, p_second_index: int) -> bool:
			return _would_label_pair_overlap(
				p_ticks[p_first_index], p_ticks[p_second_index],
				p_axis_ruler, p_min_spacing_px, p_measure_tick_label_func
			)


	# Returns a function that measures the drawn label of a tick value. It holds
	# the formatter, so the overlap test works on values and stays free of
	# formatting concerns.
	static func _make_tick_label_measure_func(p_decimals: int, p_is_log_scale: bool, p_measure_label_func: Callable) -> Callable:
		var formatter := TickSequence.new([], [], PackedInt32Array(), PackedInt32Array(), p_decimals, false, p_is_log_scale)
		return func(p_value: float) -> Vector2:
			return p_measure_label_func.call(formatter.format_value(p_value))

	################################################################################################
	# Utilities
	################################################################################################

	# Returns the candidate indices that carry a label, one candidate out of
	# p_skip_factor.
	#
	# The last candidate always carries a label. When it is off the stride, the
	# strided label before it is dropped instead of kept beside it. Those two sit
	# one candidate apart, so they overlap where the stride does not, and keeping
	# both makes the caller grow the stride for no reason.
	#
	# The first candidate is never dropped. A first and last pair is already the
	# sparsest label set.
	static func _compute_labeled_indices_with_skip(p_candidate_count: int,
			p_skip_factor: int,
			p_would_pair_overlap_func: Callable) -> PackedInt32Array:

		var indices := PackedInt32Array()
		for i in range(p_candidate_count):
			if i % p_skip_factor == 0:
				indices.append(i)

		var last_index := p_candidate_count - 1
		if last_index % p_skip_factor == 0:
			return indices

		var last_strided_position := indices.size() - 1
		if last_strided_position > 0 and p_would_pair_overlap_func.call(indices[last_strided_position], last_index):
			indices[last_strided_position] = last_index
			return indices

		indices.append(last_index)
		return indices


	static func _make_all_indices(p_count: int) -> PackedInt32Array:
		var indices := PackedInt32Array()
		indices.resize(p_count)
		for i in range(p_count):
			indices[i] = i
		return indices


	static func _make_ticks_all_labeled(p_ticks: Array[float], p_tick_info: _TickInfo, p_is_log: bool) -> TickSequence:
		return TickSequence.new(
			p_ticks, [],
			_make_all_indices(p_ticks.size()), PackedInt32Array(),
			p_tick_info.decimals, false, p_is_log
		)

	################################################################################################
	# Nice Linear Ticks
	################################################################################################

	class _TickInfo:
		var step: float
		var first: float
		var last: float
		var ticks: Array[float]
		var decimals: int
		func _init(p_step: float, p_first: float, p_last: float, p_ticks: Array[float]) -> void:
			step = p_step
			first = p_first
			last = p_last
			ticks = p_ticks
			decimals = TickResolver._infer_decimals_from_step(p_step)


	static func _compute_nice_linear_ticks(p_min: float, p_max: float, p_tick_count_preferred: int) -> _TickInfo:
		var preferred := max(p_tick_count_preferred, 2)
		if p_min >= p_max:
			return null

		var span := p_max - p_min
		var rough_step := span / float(max(preferred - 1, 1))
		if rough_step <= 0.0:
			return null

		var rough_k := int(floor(log(rough_step) / log(10.0)))
		var base := pow(10.0, float(rough_k))
		var normalized := rough_step / base

		var m_index := 0
		var best_diff := INF
		for i in range(_NICE_STEP_MULTIPLIERS.size()):
			var d := abs(_NICE_STEP_MULTIPLIERS[i] - normalized)
			if d < best_diff:
				best_diff = d
				m_index = i

		var k := rough_k
		var magnitude := max(max(abs(p_min), abs(p_max)), 1.0)
		var min_step: float = magnitude * 1e-12

		# Track best candidate without allocating its tick array yet.
		var best_step := 0.0
		var best_first := 0.0
		var best_last := 0.0
		var best_count := 0
		var best_distance := INF

		for _iter in range(256):
			var step := _NICE_STEP_MULTIPLIERS[m_index] * pow(10.0, float(k))
			if step <= 0.0 or step < min_step:
				break

			var eps := step * 1e-6
			var first: float = ceil((p_min - eps) / step) * step
			var last: float = floor((p_max + eps) / step) * step

			if last >= first:
				var count := int(floor((last - first) / step + 0.5)) + 1
				if count >= 2:
					var distance := abs(float(count) - float(preferred))
					if distance < best_distance:
						best_distance = distance
						best_step = step
						best_first = first
						best_last = last
						best_count = count

					if count <= preferred:
						# Ideal candidate found: build the tick array once and return.
						var ticks: Array[float] = []
						ticks.resize(count)
						for i in range(count):
							ticks[i] = first + float(i) * step
						return _TickInfo.new(step, first, last, ticks)

					if m_index == _NICE_STEP_MULTIPLIERS.size() - 1:
						m_index = 0
						k += 1
					else:
						m_index += 1
					continue

				if m_index == 0:
					m_index = _NICE_STEP_MULTIPLIERS.size() - 1
					k -= 1
				else:
					m_index -= 1
				continue

			if m_index == 0:
				m_index = _NICE_STEP_MULTIPLIERS.size() - 1
				k -= 1
			else:
				m_index -= 1

		# Build the best candidate's tick array only now, at most once.
		if best_count >= 2:
			var ticks: Array[float] = []
			ticks.resize(best_count)
			for i in range(best_count):
				ticks[i] = best_first + float(i) * best_step
			return _TickInfo.new(best_step, best_first, best_last, ticks)

		return null


	static func _infer_decimals_from_step(p_step: float) -> int:
		var step := abs(p_step)
		if step <= 0.0:
			return 0

		var eps: float = max(step, 1.0) * 1e-9
		for i in range(_MAX_DECIMALS + 1):
			var scaled: float = step * pow(10.0, float(i))
			if abs(scaled - round(scaled)) <= eps:
				return i

		return _MAX_DECIMALS
