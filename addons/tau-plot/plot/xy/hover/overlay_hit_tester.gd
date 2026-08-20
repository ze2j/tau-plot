const SampleHit := preload("res://addons/tau-plot/plot/xy/hover/sample_hit.gd").SampleHit
const HoverMode := preload("res://addons/tau-plot/plot/xy/hover/hover_config.gd").HoverMode


## Abstract base class that defines the hit testing contract for overlay
## renderers. Subclasses override only the methods relevant to their
## overlay type.
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

	## Returns the mode this overlay prefers. The pane runs on that mode
	## when all its testers return the same one, and on NEAREST when they
	## disagree.
	@abstract func get_preferred_hover_mode() -> HoverMode

	## NEAREST mode.
	##
	## Returns the closest hit of this overlay, or null when no sample
	## qualifies.
	##
	## p_local_pos: pointer position in pane-local screen coordinates
	##   (x = rightward pixels, y = downward pixels from the pane origin).
	@abstract func hit_test_nearest(p_local_pos: Vector2) -> SampleHit

	## X_ALIGNED mode, categorical x.
	##
	## Returns the hits of this overlay at the given category.
	##
	## p_category_index: zero-based index into the category array.
	## p_x_value: the category label at that index (String).
	## p_local_pos: pointer position in pane-local screen coordinates.
	@abstract func collect_hits_at_category(p_category_index: int, p_x_value: String, p_local_pos: Vector2) -> Array[SampleHit]

	## X_ALIGNED mode, continuous x.
	##
	## Returns the hits of this overlay at one x position. Among the x
	## positions where this overlay has samples, that position is the one
	## closest to the anchor. Each overlay sets its own limit on how far
	## from the anchor it still answers, and returns an empty array beyond
	## that limit.
	##
	## The anchor is a single x value resolved for the whole pane. It is the
	## x position of the sample nearest the pointer, across every overlay of
	## the pane. It therefore belongs to one overlay, and the others rarely
	## have a sample at that exact value. Requiring an exact match would
	## leave them unreachable, so each overlay answers at its closest
	## position instead.
	##
	## p_anchor_x_value: the anchor, as a continuous x data value.
	## p_local_pos: pointer position in pane-local screen coordinates.
	@abstract func collect_hits_at_continuous_x(p_anchor_x_value: float, p_local_pos: Vector2) -> Array[SampleHit]

	## X_ALIGNED mode, continuous x.
	##
	## Returns the x position of this overlay closest to the given one, as
	## { "x_px": float, "x_value": float }. Returns an empty dictionary when
	## this overlay holds no sample.
	##
	## p_along_x_px: position projected onto the data x axis, in pixels from
	##   the pane origin along that axis direction. When x is horizontal
	##   this equals screen x. When x is vertical this equals screen y.
	@abstract func find_nearest_x(p_along_x_px: float) -> Dictionary
