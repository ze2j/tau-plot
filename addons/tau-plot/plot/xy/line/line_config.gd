## Line-overlay specific rendering config.
class_name TauLineConfig extends TauPaneOverlayConfig

const LineVisualCallbacks := preload("res://addons/tau-plot/plot/xy/line/line_visual_callbacks.gd").LineVisualCallbacks

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`
#          and, if applicable, in `has_layout_affecting_change()`.
################################################################################################

## Theme-driven visual parameters for lines.
## Never null. Modify properties directly: line_config.style.line_widths_px = [3.0].
## Properties set this way are automatically guarded from theme overwriting.
@export var style: TauLineStyle = TauLineStyle.new()

enum LineMode
{
	INDEPENDENT,   ## Each series is drawn independently.
	STACKED        ## Values at the same X are summed across series.
}
@export var mode: LineMode = LineMode.INDEPENDENT

const StackedNormalization = preload("res://addons/tau-plot/plot/xy/stacked_normalization.gd").StackedNormalization
@export var stacked_normalization: StackedNormalization = StackedNormalization.NONE

const StackedNegativePolicy = preload("res://addons/tau-plot/plot/xy/stacked_negative_policy.gd").StackedNegativePolicy

## How negative values are handled in STACKED mode.
## SIGNED_SUM (default) folds negative values into the cumulative as a downward
## dip, the streamgraph behavior. DIVERGING splits each X into an upper stack
## of positive values and a lower stack of negative values, both anchored at
## zero. SKIP_NEGATIVES drops negative samples entirely from the stack.
@export var stacked_negative_policy: StackedNegativePolicy = StackedNegativePolicy.SIGNED_SUM

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
##
## This property is visual-only and does not affect layout or domain.
enum GapPolicy
{
	SKIP,    ## Break the polyline at invalid samples.
	BRIDGE   ## Drop invalid samples and connect the surrounding valid samples.
}
@export var gap_policy: GapPolicy = GapPolicy.SKIP

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
##
## This property is visual-only and does not affect layout or domain.
enum InterpolationMode
{
	LINEAR,            ## Straight segment between consecutive samples.
	STEP_BEFORE,       ## Vertical jump first at the previous sample's X, then horizontal.
	STEP_AFTER,        ## Horizontal first, then vertical jump at the next sample's X.
	STEP_MIDDLE,       ## Horizontal, vertical jump at the pixel midpoint, horizontal.
	SMOOTH_MONOTONE    ## Fritsch-Carlson monotone piecewise cubic Hermite curve.
}
@export var interpolation_mode: InterpolationMode = InterpolationMode.LINEAR

## Which area around the line is filled. The look of the fill, its color and
## texture, lives in [TauLineFill].
##
## This property is visual-only and does not affect layout or domain.
enum FillMode
{
	## Leave the area unfilled.
	NONE,

	## Fill between the line and the constant level [member fill_baseline].
	TO_BASELINE,

	## Fill the band between each layer's top and the top of the layer directly
	## below, so a stacked line overlay reads as a stacked area chart. Requires
	## [member mode] STACKED.
	STACKED
}
@export var fill_mode: FillMode = FillMode.NONE

## Reference y level for the TO_BASELINE fill, in data units on the series
## y-axis. The fill is drawn between the line and this level. Ignored by other
## [member fill_mode] values.
##
## The MAGNITUDE stretch span measures its distance from this level. See
## [enum TauLineFill.FillStretchSpan].
##
## This property is visual-only and does not affect layout or domain.
@export var fill_baseline: float = 0.0

## Where a value stretch span reads its low and high ends. See
## [member TauLineFill.stretch_span].
##
## This property is visual-only and does not affect layout or domain.
enum StretchRangePolicy
{
	DOMAIN,   ## Span the whole series, from its lowest value to its highest.
	CUSTOM    ## Use the fixed window set in [member stretch_range].
}
@export var stretch_range_policy: StretchRangePolicy = StretchRangePolicy.DOMAIN

## Fixed low and high window for a stretch fill, read only when
## [member stretch_range_policy] is CUSTOM. [code].x[/code] is the low end and
## [code].y[/code] the high end, and swapping them reverses the gradient.
##
## What each end means follows the span that reads it:
## - VALUE_Y: a value on the series y axis.
## - VALUE_X: a value on the x axis. Not available on a categorical x axis,
##   use DOMAIN there.
## - MAGNITUDE: a distance from [member fill_baseline], so keep both at or
##   above zero.
##
## The LINE span never reads this window. See [member TauLineFill.stretch_span].
##
## This property is visual-only and does not affect layout or domain.
@export var stretch_range: Vector2 = Vector2.ZERO

## Maximum pixel distance from the cursor to a sample position for the sample
## to be considered a hover hit.
##
## In NEAREST mode, this is a 2D Euclidean distance gate. Samples farther
## than this value from the cursor are excluded entirely.
##
## In X_ALIGNED mode, this is an x-axis-only pixel gate. Samples whose x
## screen position differs from the target x by more than this value are
## excluded. The same threshold sets [member SampleHit.contains_pointer]
## on included hits.
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


####################################################################################################
# Helpers
####################################################################################################

func _init() -> void:
	overlay_type = PaneOverlayType.LINE


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
	if interpolation_mode != other.interpolation_mode:
		return false
	if fill_mode != other.fill_mode:
		return false
	if fill_baseline != other.fill_baseline:
		return false
	if stretch_range_policy != other.stretch_range_policy:
		return false
	if stretch_range != other.stretch_range:
		return false
	if hover_max_distance_px != other.hover_max_distance_px:
		return false

	return true


# Returns true if the change between this and p_other affects layout/domain.
# Returns false if the change only affects visual appearance.
#
# mode, stacked_normalization, and stacked_negative_policy affect the domain:
# stacking changes Y bounds, normalization pins the range, and the negative
# policy decides whether the lower half-axis exists. Hover distance is a pure
# hit-test parameter with no layout effect.
func has_layout_affecting_change(p_other: TauPaneOverlayConfig) -> bool:
	var other := p_other as TauLineConfig
	if other == null:
		return false

	if not super.has_layout_affecting_change(other):
		return false

	if mode != other.mode:
		return true

	if mode == LineMode.STACKED and stacked_normalization != other.stacked_normalization:
		return true

	if mode == LineMode.STACKED and stacked_negative_policy != other.stacked_negative_policy:
		return true

	return false
