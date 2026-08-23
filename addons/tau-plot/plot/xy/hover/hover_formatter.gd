const SampleHit := preload("res://addons/tau-plot/plot/xy/hover/sample_hit.gd").SampleHit
const OverlayHitTester := preload("res://addons/tau-plot/plot/xy/hover/overlay_hit_tester.gd").OverlayHitTester
const XYDomain := preload("res://addons/tau-plot/plot/xy/xy_domain.gd").XYDomain
const SeriesAxisAssignment := preload("res://addons/tau-plot/plot/xy/series_axis_assignment.gd").SeriesAxisAssignment


## Produces human-readable strings from raw numeric values for tooltip display.
##
## Adapts decimal places to the visible domain span and a configurable
## precision digit count.
class HoverFormatter extends RefCounted:
	var _domain: XYDomain
	var _series_assignment: SeriesAxisAssignment
	var _precision_digits: int


	func _init(
			p_domain: XYDomain,
			p_series_assignment: SeriesAxisAssignment,
			p_precision_digits: int) -> void:
		_domain = p_domain
		_series_assignment = p_series_assignment
		_precision_digits = p_precision_digits


	## Produces the default tooltip text for the given hits.
	## Single hit: "SeriesName (x_value)\ny: y_value"
	## Multiple hits: "x_value\nSeries1: y1\nSeries2: y2\n..."
	func format_default_tooltip(p_hits: Array[SampleHit]) -> String:
		if p_hits.is_empty():
			return ""

		# Deduplicate by (series_id, sample_index) for the default formatter.
		var seen := {}  # Dictionary keyed by "series_id:sample_index"
		var unique_hits: Array[SampleHit] = []
		for hit in p_hits:
			var key := "%d:%d" % [hit.series_id, hit.sample_index]
			if key not in seen:
				seen[key] = true
				unique_hits.append(hit)

		if unique_hits.size() == 1:
			return _format_single_hit(unique_hits[0])
		return _format_multi_hit(unique_hits)


	############################################################################
	# Private
	############################################################################

	## Formats a single hit:
	## "SeriesName (x_formatted)"
	## "y: y_formatted"
	func _format_single_hit(p_hit: SampleHit) -> String:
		var x_str := _format_hit_x_value(p_hit)
		var y_str := _format_hit_y_value(p_hit)

		var line1 := p_hit.series_name
		if not x_str.is_empty():
			line1 += " (" + x_str + ")"
		return line1 + "\ny: " + y_str


	## Formats multiple hits (X_ALIGNED style). One shared x value gets a
	## heading of its own:
	## "x_value"
	## "Series1: y1"
	## "Series2: y2"
	##
	## Otherwise each line carries its own x instead:
	## "Series1 (x1): y1"
	## "Series2 (x2): y2"
	func _format_multi_hit(p_hits: Array) -> String:
		if p_hits.is_empty():
			return ""

		var lines: PackedStringArray = PackedStringArray()

		if _share_one_x_value(p_hits):
			var x_str := _format_hit_x_value(p_hits[0])
			if not x_str.is_empty():
				lines.append(x_str)
			for hit in p_hits:
				lines.append(hit.series_name + ": " + _format_hit_y_value(hit))
			return "\n".join(lines)

		for hit in p_hits:
			var x_str := _format_hit_x_value(hit)
			var label: String = hit.series_name
			if not x_str.is_empty():
				label += " (" + x_str + ")"
			lines.append(label + ": " + _format_hit_y_value(hit))

		return "\n".join(lines)


	## Returns true when every hit sits at the same x value. Categorical x
	## always does, since the hits come from one resolved category.
	func _share_one_x_value(p_hits: Array) -> bool:
		var first_hit: SampleHit = p_hits[0]
		if first_hit.x_value is String:
			return true

		for hit: SampleHit in p_hits:
			if not OverlayHitTester.x_values_match(hit.x_value, first_hit.x_value):
				return false
		return true


	func _format_hit_x_value(p_hit: SampleHit) -> String:
		if p_hit.x_value is String:
			return p_hit.x_value as String
		return _format_continuous_x_value(p_hit.x_value as float)


	func _format_hit_y_value(p_hit: SampleHit) -> String:
		return _format_value(p_hit.y_raw_value, _get_y_domain_span(p_hit), _precision_digits)


	## Formats a continuous x value for tooltip display.
	##
	## Unlike axis tick labels (which only need to distinguish adjacent ticks),
	## tooltip values must show the actual data value with enough precision to
	## be meaningful relative to the visible domain. The number of decimal
	## places is derived from the x domain span and the configured precision
	## digits.
	func _format_continuous_x_value(p_value: float) -> String:
		return _format_value(p_value, _get_x_domain_span(), _precision_digits)


	## Formats a float with precision derived from the domain span.
	##
	## The number of decimals is chosen so that the smallest displayed digit
	## represents roughly 1/(10^p_precision_digits) of the span. When values
	## are extremely small or extremely large, scientific notation is used.
	static func _format_value(p_value: float, p_domain_span: float, p_precision_digits: int) -> String:
		# Compute decimals so precision is ~span / 10^p_precision_digits.
		# The domain span is strictly positive (guaranteed by XYDomain).
		var decimals := maxi(0, -int(floor(log(p_domain_span) / log(10.0))) + p_precision_digits)

		# If we would need more than 12 decimal places, switch to scientific
		# notation. Similarly, use scientific notation for very large values
		# where fixed-point would be unwieldy.
		if decimals > 12 or (absf(p_value) >= 1e12 and decimals == 0):
			return String.num_scientific(p_value)

		return String.num(p_value, decimals)


	## Returns the visible domain span for the x axis.
	## Only called for continuous x values. XYDomain guarantees max > min.
	func _get_x_domain_span() -> float:
		var x_domain := _domain.x_axis_domain
		return x_domain.max_val - x_domain.min_val


	## Returns the y domain span for the specific axis that a hit belongs to.
	## Hit testers only produce hits for series with valid axis assignments,
	## so the axis lookup and domain are guaranteed to succeed here.
	func _get_y_domain_span(p_hit: SampleHit) -> float:
		var pane_idx := p_hit.pane_index
		var y_axis_id: int = _series_assignment.get_y_axis_id_for_series(p_hit.series_id, pane_idx)
		var pane_domain := _domain.get_pane_domain(pane_idx)
		var y_domain := pane_domain.get_y_axis_domain(y_axis_id)
		return y_domain.max_val - y_domain.min_val
