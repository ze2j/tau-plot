## Line-overlay specific rendering config.
class_name TauLineConfig extends TauPaneOverlayConfig

const LineVisualCallbacks := preload("res://addons/tau-plot/plot/xy/line/line_visual_callbacks.gd").LineVisualCallbacks

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`
#          and, if applicable, in `has_layout_affecting_change()`. `style` is the
#          one exception, see the note above `is_equal_to()`.
################################################################################################

## Theme-driven visual parameters for lines.
## Never null. Modify properties directly: line_config.style.line_widths_px = [3.0].
## Properties set this way are automatically guarded from theme overwriting.
@export var style: TauLineStyle = TauLineStyle.new()

## How the curves of several series relate to one another.
enum LineMode
{
	## Each series is drawn on its own, straight from its values.
	INDEPENDENT,

	## Each series is drawn on top of the ones before it, so its curve carries
	## the running total at every x rather than its own value.
	STACKED
}

## Relation between the curves of the series in the overlay. See
## [enum LineMode].
@export var mode: LineMode = LineMode.INDEPENDENT


## How consecutive samples are interpolated.
##
## LINEAR draws a straight segment between consecutive samples.
##
## The three step modes interpolate as a staircase between consecutive
## samples: only horizontal or vertical motion, with the modes differing by
## when the vertical jump happens. STEP_BEFORE jumps as early as possible (at
## the previous sample's X position), STEP_AFTER as late as possible (at the
## next sample's X position), and STEP_MIDDLE jumps at the pixel midpoint
## between the two X positions.
##
## SMOOTH_MONOTONE draws a piecewise cubic Hermite curve through the samples,
## using Fritsch-Carlson tangent selection. The curve is C1 continuous,
## interpolates every sample exactly, and preserves local monotonicity, so
## no overshoot or local extrema are introduced between samples.
enum InterpolationMode
{
	LINEAR,            ## Straight segment between consecutive samples.
	STEP_BEFORE,       ## Vertical jump first at the previous sample's X, then horizontal.
	STEP_AFTER,        ## Horizontal first, then vertical jump at the next sample's X.
	STEP_MIDDLE,       ## Horizontal, vertical jump at the pixel midpoint, horizontal.
	SMOOTH_MONOTONE    ## Fritsch-Carlson monotone piecewise cubic Hermite curve.
}

## Per-series cycle of interpolation modes. See [TauStyle] for how a cycle is
## indexed. An empty array is treated as all series drawn
## [constant InterpolationMode.LINEAR].
##
## Mixing modes within one overlay is the point: a raw stepped series can sit
## under a smoothed trend.
##
## This property is visual-only and does not affect layout or domain.
@export var interpolation_modes: Array[InterpolationMode] = [InterpolationMode.LINEAR]


## Strategy applied when the curve encounters a sample with a NaN or infinite
## X or Y value (or a value forbidden by the active axis scale, such as a
## non-positive value on a logarithmic axis).
##
## SKIP breaks the polyline at the invalid sample. The runs on each side of
## the gap are drawn as independent contiguous polylines.
##
## BRIDGE drops the invalid sample from the sequence and connects the valid
## sample before it directly to the valid sample after it, so the polyline
## stays continuous across the gap.
enum GapPolicy
{
	SKIP,    ## Break the polyline at invalid samples.
	BRIDGE   ## Drop invalid samples and connect the surrounding valid samples.
}

## Strategy applied to invalid samples, for every series in the overlay.
## See [enum GapPolicy].
##
## This property is visual-only and does not affect layout or domain.
@export var gap_policy: GapPolicy = GapPolicy.SKIP


const StackedNormalization := preload("res://addons/tau-plot/plot/xy/stacked_normalization.gd").StackedNormalization

## What each stack is scaled to in [constant LineMode.STACKED]. See
## [enum StackedNormalization]. Ignored in
## [constant LineMode.INDEPENDENT].
@export var stacked_normalization: StackedNormalization = StackedNormalization.NONE

const StackedNegativePolicy := preload("res://addons/tau-plot/plot/xy/stacked_negative_policy.gd").StackedNegativePolicy

## How negative values are handled in STACKED mode.
## SIGNED_SUM (default) folds negative values into the cumulative as a downward
## dip, the streamgraph behavior. DIVERGING splits each X into an upper stack
## of positive values and a lower stack of negative values, both anchored at
## zero. SKIP_NEGATIVES drops negative samples entirely from the stack.
@export var stacked_negative_policy: StackedNegativePolicy = StackedNegativePolicy.SIGNED_SUM


## Maximum pixel distance from the cursor to a sample position
## for the sample to be considered a hit.
##
## In NEAREST mode, this is a 2D Euclidean distance gate. Samples farther
## than this value from the cursor are excluded entirely.
##
## In X_ALIGNED mode with a continuous x axis, this is an x-axis-only pixel
## gate. Samples whose x screen position differs from the target x by more
## than this value are excluded. The same threshold sets [member SampleHit.contains_pointer]
## on included hits.
##
## In X_ALIGNED mode with a categorical x axis, this property does not gate
## which samples are returned. All samples at the matching category are
## included. The distance is still compared against this threshold to set
## [member SampleHit.contains_pointer], which controls whether the sample
## receives the visual hover highlight.
@export var hover_max_distance_px: int = 10


####################################################################################################
# Typed visual_callbacks accessor
####################################################################################################

## Typed accessor for line-specific visual callbacks.
## Shadows the base [member TauPaneOverlayConfig.visual_callbacks] with the concrete type.
var line_visual_callbacks: LineVisualCallbacks:
	get:
		return visual_callbacks as LineVisualCallbacks
	set(value):
		visual_callbacks = value


#region Internal, not public API, may change without notice.

func _init() -> void:
	overlay_type = PaneOverlayType.LINE


# Returns the resolved interpolation mode for the given series index.
func get_series_interpolation_mode(p_series_index: int) -> InterpolationMode:
	if interpolation_modes.is_empty():
		return InterpolationMode.LINEAR
	return interpolation_modes[p_series_index % interpolation_modes.size()]


# `style` is left out on purpose. A style resource carries its own equality and
# emits `changed` when mutated, so style changes are diffed and re-resolved on
# their own. Comparing it here would only repeat that work.
func is_equal_to(p_other: TauPaneOverlayConfig) -> bool:
	var other := p_other as TauLineConfig
	if other == null:
		return false

	if not super.is_equal_to(other):
		return false

	if mode != other.mode:
		return false
	if stacked_normalization != other.stacked_normalization:
		return false
	if stacked_negative_policy != other.stacked_negative_policy:
		return false
	if gap_policy != other.gap_policy:
		return false
	if interpolation_modes != other.interpolation_modes:
		return false
	if hover_max_distance_px != other.hover_max_distance_px:
		return false

	return true


# Returns true if the change between this and p_other affects layout/domain.
# Returns false if the change only affects visual appearance.
#
# mode, stacked_normalization, and stacked_negative_policy affect the domain:
# stacking changes Y bounds, normalization pins the range, and the negative
# policy decides whether the lower half-axis exists. The hover distance is a
# pure hit-test parameter with no layout effect.
func has_layout_affecting_change(p_other: TauPaneOverlayConfig) -> bool:
	var other := p_other as TauLineConfig

	if super.has_layout_affecting_change(other):
		return true

	if mode != other.mode:
		return true

	if mode == LineMode.STACKED and stacked_normalization != other.stacked_normalization:
		return true

	if mode == LineMode.STACKED and stacked_negative_policy != other.stacked_negative_policy:
		return true

	return false

#endregion
