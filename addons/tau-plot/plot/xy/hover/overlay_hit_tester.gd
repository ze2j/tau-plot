const SampleHit = preload("res://addons/tau-plot/plot/xy/hover/sample_hit.gd").SampleHit
const HoverMode = preload("res://addons/tau-plot/plot/xy/hover/hover_config.gd").HoverMode


## Abstract base class that defines the hit testing contract for overlay
## renderers. Subclasses override only the methods relevant to their
## overlay type.
##
## The hover coordinator calls these methods to discover which samples
## lie under or near the pointer. Each overlay type (bar, scatter, etc.)
## provides its own implementation. The coordinator never inspects overlay
## internals directly.
@abstract class OverlayHitTester extends RefCounted:

	## Relative epsilon for comparing two x data values in X_ALIGNED mode.
	## Two values a and b are considered equal when
	##     abs(a - b) <= X_MATCH_RELATIVE_EPSILON * max(abs(a), abs(b))
	## with a special case for both values being exactly zero.
	## The tolerance is purely relative so it works at any magnitude
	## (nanoseconds, years, microvolts, gigawatts, etc.).
	const X_MATCH_RELATIVE_EPSILON: float = 1e-9


	## Returns true when two continuous x data values are close enough to
	## be considered the same position for hover grouping purposes.
	## Uses a purely relative comparison so the check works at any scale.
	static func x_values_match(p_a: float, p_b: float) -> bool:
		var diff := absf(p_a - p_b)
		var scale := maxf(absf(p_a), absf(p_b))
		if scale == 0.0:
			return true
		return diff <= X_MATCH_RELATIVE_EPSILON * scale


	## Returns true when this overlay should participate in hit testing.
	## Typically delegates to the overlay config's hoverable flag.
	@abstract func is_hoverable() -> bool

	## Returns the hover mode this overlay prefers when TauHoverConfig is AUTO.
	## Used by the coordinator to resolve AUTO: if all testers in a pane
	## agree, that mode wins. If they disagree, NEAREST wins.
	@abstract func get_preferred_hover_mode() -> HoverMode

	## NEAREST mode: return the single closest hit, or null.
	##
	## p_local_pos: pointer position in pane-local screen coordinates
	##   (x = rightward pixels, y = downward pixels from the pane origin).
	@abstract func hit_test_nearest(p_local_pos: Vector2) -> SampleHit

	## X_ALIGNED mode, categorical x. Returns all hits at the given
	## category index for this overlay.
	##
	## p_category_index: zero-based index into the category array.
	## p_x_value: the category label at that index (String).
	## p_local_pos: pointer position in pane-local screen coordinates.
	@abstract func collect_hits_at_category(p_category_index: int, p_x_value: String, p_local_pos: Vector2) -> Array[SampleHit]

	## X_ALIGNED mode, continuous x. Returns all hits whose x value
	## matches p_x_value for this overlay.
	##
	## p_x_value: the continuous x data value to match against.
	## p_local_pos: pointer position in pane-local screen coordinates.
	@abstract func collect_hits_at_continuous_x(p_x_value: float, p_local_pos: Vector2) -> Array[SampleHit]

	## X_ALIGNED mode, continuous x: return the nearest x pixel position
	## this overlay can provide, and its corresponding data value.
	## Used by the coordinator to find the globally nearest x before
	## calling collect_hits_at_continuous_x on all testers.
	##
	## p_along_x_px: pointer position projected onto the data x axis,
	##   in pixels from the pane origin along that axis direction.
	##   When x is horizontal this equals screen x. When x is vertical
	##   this equals screen y.
	##
	## Returns { "x_px": float, "x_value": float } or empty dict if
	## no data is available.
	@abstract func find_nearest_x(p_along_x_px: float) -> Dictionary
