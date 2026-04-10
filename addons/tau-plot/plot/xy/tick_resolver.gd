# Dependencies
const TickSequence := preload("res://addons/tau-plot/plot/xy/tick_sequence.gd").TickSequence

# Resolves tick positions and label visibility for axes.
# Handles both continuous (numeric) and categorical (string) axes.
class TickResolver extends RefCounted:

	const _NICE_STEP_MULTIPLIERS: Array[float] = [1.0, 2.0, 2.5, 5.0]
	const _MAX_DECIMALS: int = 12

	# Log scale constants
	const _LOG_MINOR_TICKS: Array[float] = [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
	const _MIN_PIXELS_PER_MAJOR_TICK: float = 10.0
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
					p_axis_min, p_axis_max, p_overlap_strategy,
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

		var pixels_per_category := p_available_pixels / float(category_count)

		if not _would_categorical_labels_overlap(p_categories, pixels_per_category, p_min_spacing_px, p_measure_label_func):
			return PackedInt32Array()

		var skip_factor := 2
		while skip_factor <= category_count:
			var visible_indices := _compute_categorical_visible_indices(category_count, skip_factor)

			if not _would_categorical_subset_overlap(p_categories, visible_indices, pixels_per_category, p_min_spacing_px, p_measure_label_func):
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
					tick_info, p_available_pixels, p_min_spacing_px, p_measure_label_func
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

		var current_preferred := p_initial_tick_info.ticks.size()

		while current_preferred >= 2:
			var tick_info := _compute_nice_linear_ticks(p_axis_min, p_axis_max, current_preferred)
			if tick_info == null:
				break

			if not _would_labels_overlap(tick_info.ticks, tick_info.decimals, p_available_pixels, p_min_spacing_px, p_measure_label_func):
				return _make_ticks_all_labeled(tick_info.ticks, tick_info, false)

			current_preferred -= 1

		return TickSequence.new()


	static func _resolve_overlap_by_skipping_labels(p_tick_info: _TickInfo,
													p_available_pixels: float,
													p_min_spacing_px: float,
													p_measure_label_func: Callable) -> TickSequence:

		var all_ticks := p_tick_info.ticks
		var decimals := p_tick_info.decimals
		var skip_factor := 1

		while skip_factor < all_ticks.size():
			var labeled_indices := _compute_labeled_indices_with_skip(all_ticks.size(), skip_factor)

			if not _would_labeled_ticks_overlap(all_ticks, labeled_indices, decimals, p_available_pixels, p_min_spacing_px, p_measure_label_func):
				return TickSequence.new(all_ticks, [], labeled_indices, decimals, false, false)

			skip_factor += 1

		if all_ticks.size() >= 2:
			return TickSequence.new(all_ticks, [], PackedInt32Array([0, all_ticks.size() - 1]), decimals, false, false)

		return TickSequence.new(all_ticks, [], PackedInt32Array([0]), decimals, false, false)

	################################################################################################
	# Logarithmic Scales
	################################################################################################

	static func _compute_log_ticks_with_overlap_handling(p_axis_min: float,
														 p_axis_max: float,
														 p_overlap_strategy: TauAxisConfig.OverlapStrategy,
														 p_available_pixels: float,
														 p_min_spacing_px: float,
														 p_measure_label_func: Callable) -> TickSequence:

		if p_axis_min <= 0.0 or p_axis_max <= 0.0 or p_axis_min >= p_axis_max:
			push_error("TickResolver: Invalid log domain")
			return TickSequence.new()

		var major_ticks := _compute_log_major_ticks(p_axis_min, p_axis_max)
		var minor_ticks := _compute_log_minor_ticks(p_axis_min, p_axis_max, major_ticks, p_available_pixels)

		var labeled_indices: PackedInt32Array

		match p_overlap_strategy:
			TauAxisConfig.OverlapStrategy.NONE:
				labeled_indices = _make_all_indices(major_ticks.size())

			_:
				labeled_indices = _determine_labeled_log_ticks(
					major_ticks, p_available_pixels, p_min_spacing_px, p_measure_label_func
				)

		return TickSequence.new(major_ticks, minor_ticks, labeled_indices, 0, false, true)


	static func _compute_log_major_ticks(p_min: float,
										 p_max: float) -> Array[float]:
		var log_min := log(p_min) / log(10.0)
		var log_max := log(p_max) / log(10.0)
		var first_exp := int(ceil(log_min))
		var last_exp := int(floor(log_max))

		var major_ticks: Array[float] = []
		for exp in range(first_exp, last_exp + 1):
			var tick_val := pow(10.0, float(exp))
			if tick_val >= p_min and tick_val <= p_max:
				major_ticks.append(tick_val)

		if major_ticks.is_empty():
			var mid_log := (log_min + log_max) / 2.0
			major_ticks.append(pow(10.0, round(mid_log)))

		return major_ticks


	static func _compute_log_minor_ticks(p_min: float,
										 p_max: float,
										 p_major_ticks: Array[float],
										 p_available_pixels: float) -> Array[float]:
		if p_major_ticks.is_empty():
			return []

		var pixels_per_major: float = p_available_pixels / max(float(p_major_ticks.size()), 1.0)
		if pixels_per_major < _MIN_PIXELS_PER_MAJOR_TICK * 2.0:
			return []

		var all_ticks: Array[float] = []

		if not p_major_ticks.is_empty():
			var first_major := p_major_ticks[0]
			var decade_below := first_major / 10.0
			for minor_mult in _LOG_MINOR_TICKS:
				var tick_val := decade_below * minor_mult
				if tick_val >= p_min and tick_val < first_major:
					all_ticks.append(tick_val)

		for i in range(p_major_ticks.size()):
			var major := p_major_ticks[i]
			for minor_mult in _LOG_MINOR_TICKS:
				var tick_val := major * minor_mult
				if tick_val <= p_max:
					if i + 1 < p_major_ticks.size():
						if tick_val < p_major_ticks[i + 1]:
							all_ticks.append(tick_val)
					else:
						all_ticks.append(tick_val)

		var pixels_per_tick: float = p_available_pixels / max(float(all_ticks.size()), 1.0)
		if pixels_per_tick < _MIN_PIXELS_PER_MINOR_TICK:
			return []

		all_ticks.sort()
		return all_ticks


	static func _determine_labeled_log_ticks(p_major_ticks: Array[float],
											 p_available_pixels: float,
											 p_min_spacing_px: float,
											 p_measure_label_func: Callable) -> PackedInt32Array:

		if not _would_log_labels_overlap(p_major_ticks, _make_all_indices(p_major_ticks.size()), p_available_pixels, p_min_spacing_px, p_measure_label_func):
			return _make_all_indices(p_major_ticks.size())

		var skip_factor := 2
		while skip_factor < p_major_ticks.size():
			var labeled_indices := _compute_labeled_indices_with_skip(p_major_ticks.size(), skip_factor)
			if not _would_log_labels_overlap(p_major_ticks, labeled_indices, p_available_pixels, p_min_spacing_px, p_measure_label_func):
				return labeled_indices
			skip_factor += 1

		if p_major_ticks.size() >= 2:
			return PackedInt32Array([0, p_major_ticks.size() - 1])
		return _make_all_indices(p_major_ticks.size())

	################################################################################################
	# Categorical
	################################################################################################

	static func _would_categorical_labels_overlap(p_categories: PackedStringArray,
												  p_pixels_per_category: float,
												  p_min_spacing_px: float,
												  p_measure_label_func: Callable) -> bool:

		var max_label_width := 0.0
		for category in p_categories:
			var label_size: Vector2 = p_measure_label_func.call(category)
			max_label_width = max(max_label_width, label_size.x)

		return (max_label_width + p_min_spacing_px) > p_pixels_per_category


	static func _would_categorical_subset_overlap(p_categories: PackedStringArray,
												  p_visible_indices: PackedInt32Array,
												  p_pixels_per_category: float,
												  p_min_spacing_px: float,
												  p_measure_label_func: Callable) -> bool:

		if p_visible_indices.size() <= 1:
			return false

		for i in range(p_visible_indices.size() - 1):
			var idx1 := p_visible_indices[i]
			var idx2 := p_visible_indices[i + 1]
			var label1 := p_categories[idx1]
			var label2 := p_categories[idx2]
			var size1: Vector2 = p_measure_label_func.call(label1)
			var size2: Vector2 = p_measure_label_func.call(label2)
			var category_span := float(idx2 - idx1)
			var pixel_span := p_pixels_per_category * category_span
			var label_extent := (size1.x * 0.5) + (size2.x * 0.5) + p_min_spacing_px
			if label_extent > pixel_span:
				return true

		return false


	static func _compute_categorical_visible_indices(p_count: int,
													 p_skip_factor: int) -> PackedInt32Array:
		var indices := PackedInt32Array()
		for i in range(p_count):
			if i % p_skip_factor == 0:
				indices.append(i)
		if p_count > 0 and (p_count - 1) % p_skip_factor != 0:
			indices.append(p_count - 1)
		return indices

	################################################################################################
	# Overlap Detection
	################################################################################################

	static func _would_labels_overlap(p_ticks: Array[float],
									p_decimals: int,
									p_available_pixels: float,
									p_min_spacing_px: float,
									p_measure_label_func: Callable) -> bool:

		if p_ticks.size() <= 1:
			return false

		var pixels_per_tick := p_available_pixels / float(p_ticks.size() - 1)
		var shared_ticks := TickSequence.new(p_ticks, [], _make_all_indices(p_ticks.size()), p_decimals, false, false)
		var max_label_width := 0.0

		for tick_val in p_ticks:
			var label_size: Vector2 = p_measure_label_func.call(shared_ticks.format_value(tick_val))
			if label_size.x > max_label_width:
				max_label_width = label_size.x

		return (max_label_width + p_min_spacing_px) > pixels_per_tick


	static func _would_labeled_ticks_overlap(p_ticks: Array[float],
											p_labeled_indices: PackedInt32Array,
											p_decimals: int,
											p_available_pixels: float,
											p_min_spacing_px: float,
											p_measure_label_func: Callable) -> bool:

		if p_labeled_indices.size() <= 1:
			return false

		var shared_ticks := TickSequence.new(p_ticks, [], _make_all_indices(p_ticks.size()), p_decimals, false, false)
		var pixels_per_tick := p_available_pixels / float(p_ticks.size() - 1) if p_ticks.size() > 1 else p_available_pixels

		for i in range(p_labeled_indices.size() - 1):
			var idx1 := p_labeled_indices[i]
			var idx2 := p_labeled_indices[i + 1]

			var size1: Vector2 = p_measure_label_func.call(shared_ticks.format_value(p_ticks[idx1]))
			var size2: Vector2 = p_measure_label_func.call(shared_ticks.format_value(p_ticks[idx2]))

			var pixel_span := pixels_per_tick * float(idx2 - idx1)
			if (size1.x * 0.5) + (size2.x * 0.5) + p_min_spacing_px > pixel_span:
				return true

		return false


	static func _would_log_labels_overlap(p_major_ticks: Array[float],
										p_labeled_indices: PackedInt32Array,
										p_available_pixels: float,
										p_min_spacing_px: float,
										p_measure_label_func: Callable) -> bool:

		if p_labeled_indices.size() <= 1 or p_major_ticks.size() < 2:
			return false

		var shared_ticks := TickSequence.new(p_major_ticks, [], _make_all_indices(p_major_ticks.size()), 0, false, true)
		var log_total_range := log(p_major_ticks[p_major_ticks.size() - 1] / p_major_ticks[0])

		for i in range(p_labeled_indices.size() - 1):
			var idx1 := p_labeled_indices[i]
			var idx2 := p_labeled_indices[i + 1]
			var tick1 := p_major_ticks[idx1]
			var tick2 := p_major_ticks[idx2]

			var size1: Vector2 = p_measure_label_func.call(shared_ticks.format_value(tick1))
			var size2: Vector2 = p_measure_label_func.call(shared_ticks.format_value(tick2))

			var pixel_span := p_available_pixels * (log(tick2 / tick1) / log_total_range)
			if (size1.x * 0.5) + (size2.x * 0.5) + p_min_spacing_px > pixel_span:
				return true

		return false

	################################################################################################
	# Utilities
	################################################################################################

	static func _compute_labeled_indices_with_skip(p_tick_count: int,
												   p_skip_factor: int) -> PackedInt32Array:
		var indices := PackedInt32Array()
		for i in range(p_tick_count):
			if i % p_skip_factor == 0:
				indices.append(i)
		if p_tick_count > 0 and (p_tick_count - 1) % p_skip_factor != 0:
			indices.append(p_tick_count - 1)
		return indices


	static func _make_all_indices(p_count: int) -> PackedInt32Array:
		var indices := PackedInt32Array()
		indices.resize(p_count)
		for i in range(p_count):
			indices[i] = i
		return indices


	static func _make_ticks_all_labeled(p_ticks: Array[float],
											p_tick_info: _TickInfo,
											p_is_log: bool) -> TickSequence:
		return TickSequence.new(p_ticks, [], _make_all_indices(p_ticks.size()), p_tick_info.decimals, false, p_is_log)

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


	static func _compute_nice_linear_ticks(p_min: float,
									   p_max: float,
									   p_tick_count_preferred: int) -> _TickInfo:
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
