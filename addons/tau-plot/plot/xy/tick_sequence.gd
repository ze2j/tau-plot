# Represents a computed tick sequence with major/minor distinction and label visibility.
# For linear scales: only major ticks exist, some may be unlabeled.
# For logarithmic scales: major ticks (powers of 10) + minor ticks (2-9 between decades).
class TickSequence extends RefCounted:

	## Major tick values (positions where tick marks are drawn)
	## For linear scales: all ticks are "major" (minor ticks array will be empty)
	## For log scales: these are powers of 10 (1, 10, 100, etc.)
	var major_ticks: Array[float] = []

	## Minor tick values (only used for logarithmic scales)
	## For linear scales: this array is always empty
	## For log scales: these are intermediate values (2, 3, 4, 5, 6, 7, 8, 9) between powers of 10
	var minor_ticks: Array[float] = []

	## Indices into major_ticks array indicating which ticks should display labels.
	## All indices must be valid (< major_ticks.size()).
	## Empty array means no labels are shown (though ticks are still drawn).
	var labeled_major_indices: PackedInt32Array = PackedInt32Array()

	## Number of decimal digits for fixed-point formatting (when use_scientific is false)
	var decimals: int = 0

	## If true, labels use scientific notation; otherwise fixed-point
	var use_scientific: bool = false

	## If true, these ticks were generated for a logarithmic scale
	var is_log_scale: bool = false


	func _init(
		p_major_ticks: Array[float] = [],
		p_minor_ticks: Array[float] = [],
		p_labeled_indices: PackedInt32Array = PackedInt32Array(),
		p_decimals: int = 0,
		p_use_scientific: bool = false,
		p_is_log_scale: bool = false
	) -> void:
		major_ticks = p_major_ticks
		minor_ticks = p_minor_ticks
		labeled_major_indices = p_labeled_indices
		decimals = max(p_decimals, 0)
		use_scientific = p_use_scientific
		is_log_scale = p_is_log_scale


	## Returns true if the major tick at the given index should display a label
	func should_show_label(p_major_tick_index: int) -> bool:
		for idx in labeled_major_indices:
			if idx == p_major_tick_index:
				return true
		return false


	## Format a tick value as a string
	func format_value(p_value: float) -> String:
		if is_log_scale:
			return _format_log_value(p_value)

		if use_scientific:
			return String.num_scientific(p_value)
		return String.num(p_value, decimals)


	func _format_log_value(p_value: float) -> String:
		if p_value <= 0.0:
			return "0"

		var log_val := log(p_value) / log(10.0)
		var exponent := round(log_val)

		# Check if this is a clean power of 10
		if is_equal_approx(log_val, exponent):
			var exp_int := int(exponent)
			if exp_int == 0:
				return "1"
			elif exp_int == 1:
				return "10"
			elif exp_int == -1:
				return "0.1"
			elif exp_int == 2:
				return "100"
			elif exp_int == -2:
				return "0.01"
			else:
				# Use superscript notation: 10^n
				return "10" + _get_superscript(exp_int)

		# Not a clean power of 10, show the actual value
		# Determine appropriate precision based on magnitude
		var abs_val := abs(p_value)
		if abs_val >= 100.0:
			return String.num(p_value, 0)
		elif abs_val >= 10.0:
			return String.num(p_value, 1)
		elif abs_val >= 1.0:
			return String.num(p_value, 2)
		elif abs_val >= 0.1:
			return String.num(p_value, 3)
		else:
			return String.num(p_value, 4)


	func _get_superscript(p_exponent: int) -> String:
		var superscripts := {
			'0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
			'5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
			'-': '⁻'
		}

		var exp_str := str(p_exponent)
		var result := ""
		for c in exp_str:
			if superscripts.has(c):
				result += superscripts[c]
			else:
				result += c
		return result
