## One series' line-chart fill: which area is filled, and how that area looks.
##
## Common setups:
## - Area-chart gradient: [member fill_mode] TO_BASELINE with a [member texture]
## assigned and everything else left alone. It fades from the line down to the
## baseline.
## - Value band: [member texture_mode] STRETCH, [member stretch_span]
## VALUE_Y, spanning the series data or a fixed [member stretch_range].
## - Recency fade on a live chart: [member stretch_span] VALUE_X.
## - Repeating motif like dots or hatching: [member texture_mode] TILE.
## - Scrolling pattern: animate [member tile_offset_px].
class_name TauLineFill extends Resource

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()` and
#          `apply_overrides_from()`.
################################################################################################

## Which area around the line is filled.
enum FillMode
{
	## Leave the area unfilled.
	NONE,

	## Fill between the line and the constant level [member fill_baseline].
	TO_BASELINE,

	## Fill the band between this series' top and the top of the layer directly
	## below, so a stacked line overlay reads as a stacked area chart. Requires
	## the overlay to stack its series.
	STACKED
}
const DEFAULT_FILL_MODE: FillMode = FillMode.NONE
## Which area around this series' line is painted. NONE, the default, leaves
## the series unfilled.
@export var fill_mode: FillMode = DEFAULT_FILL_MODE


const DEFAULT_FILL_BASELINE: float = 0.0
## Reference y level for a TO_BASELINE fill, in data units on the series
## y-axis. The fill is drawn between the line and this level. Ignored by the
## other [member fill_mode] values.
##
## The MAGNITUDE stretch span measures its distance from this level. See
## [enum FillStretchSpan].
@export var fill_baseline: float = DEFAULT_FILL_BASELINE


## Where a value stretch span reads its low and high ends. See
## [member stretch_span].
enum StretchRangePolicy
{
	DOMAIN,   ## Span the whole series, from its lowest value to its highest.
	CUSTOM    ## Use the fixed window set in [member stretch_range].
}
const DEFAULT_STRETCH_RANGE_POLICY: StretchRangePolicy = StretchRangePolicy.DOMAIN
## Where a value stretch span reads its low and high ends. See
## [enum StretchRangePolicy].
@export var stretch_range_policy: StretchRangePolicy = DEFAULT_STRETCH_RANGE_POLICY

const DEFAULT_STRETCH_RANGE: Vector2 = Vector2.ZERO
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
## The LINE span never reads this window. See [member stretch_span].
@export var stretch_range: Vector2 = DEFAULT_STRETCH_RANGE


## Sentinel value for [member color] meaning "derive from the per-series
## color supplied by [member TauXYStyle.series_colors]". As a consequence,
## [code]Color(0, 0, 0, 0)[/code] is not a valid explicit fill color.
const NO_COLOR: Color = Color(0, 0, 0, 0)
const DEFAULT_COLOR: Color = NO_COLOR
## Flat fill color applied to the area defined by [member fill_mode]. The
## sentinel [constant NO_COLOR] means "derive from the per-series color
## supplied by [member TauXYStyle.series_colors]".
##
## Overridden by [member texture] when it is non-null. The resolved color's
## alpha is scaled by [member alpha].
@export var color: Color = DEFAULT_COLOR


const DEFAULT_ALPHA: float = 0.5
## Multiplier applied to the alpha of the resolved fill, whether that fill
## came from [member color], from [member TauXYStyle.series_colors], or
## from [member texture]. Valid range is [code][0.0, 1.0][/code].
@export var alpha: float = DEFAULT_ALPHA


## Texture painted over the fill area. When set, it takes the place of
## [member color] and the per-series color. Its own alpha is scaled by
## [member alpha].
##
## [member texture_mode] decides how it is painted. Out of the box, a freshly
## assigned texture fades from the line to the baseline, the ready-made
## area-chart gradient, with nothing else to set.
@export var texture: Texture2D = null


## How [member texture] is painted across the fill.
enum FillTextureMode
{
	STRETCH,   ## Fit the texture across the fill once, so it reads as a single gradient or band. What it maps to is set by [member stretch_span].
	TILE       ## Repeat the texture at its native pixel size, for a seamless motif like dots or hatching.
}
const DEFAULT_TEXTURE_MODE: FillTextureMode = FillTextureMode.STRETCH
## How [member texture] is painted, stretched once or tiled. See
## [enum FillTextureMode]. Ignored when [member texture] is [code]null[/code].
@export var texture_mode: FillTextureMode = DEFAULT_TEXTURE_MODE


## Chooses which measured value picks a stretched texture's color. The texture
## is read as a color scale between its two edges. At every point of the fill,
## the span measures one value, and that value chooses a color along the scale.
## Each span measures a different thing, so the same texture can read as an area
## fade, a value band, or a deviation map.
##
## The low end of the measured range maps to one texture edge, the high end to
## the other.
##
## VALUE_Y, VALUE_X and MAGNITUDE read their low and high ends from a value
## window: the series data by default, or a fixed [member stretch_range]. See
## [member stretch_range_policy]. LINE needs no window, it always runs from the
## line to the baseline.
##
## Only a thin strip of the texture is read: the middle column for the vertical
## spans (VALUE_Y and MAGNITUDE), the middle row for VALUE_X. A gradient can
## therefore be authored a single pixel wide.
enum FillStretchSpan
{
	## Where the point sits inside the fill band, from the line to the
	## baseline, as a fraction. It looks only at the band, never at the data
	## values, so the colors stay the same when the chart is zoomed or
	## scrolled. Example: an area fade, opaque at the line and clear at the
	## baseline.
	LINE,

	## The y value of the point. The color follows the height: two points at
	## the same height always share a color, and points higher or lower get
	## different colors. The range covers the data (or
	## [member stretch_range]), so a color stays tied to its value even when
	## the chart is zoomed. Example: a heat band, warm tints on high values
	## and cool tints on low.
	VALUE_Y,

	## The x value of the point. Same idea as VALUE_Y, but measured along the
	## x axis instead of the height. Example: a live chart that dims its
	## oldest samples and keeps the leading edge bright.
	VALUE_X,

	## The distance from [member fill_baseline], no matter which side the
	## point is on. Unlike VALUE_Y, a point above the baseline and a point the
	## same distance below share a color, and the baseline itself always takes
	## the low end of the range. The color grows stronger as the line moves
	## further from the baseline, above or below. Example: a deviation fill,
	## matching above and below. Not available when [member fill_mode] is
	## STACKED.
	MAGNITUDE
}
const DEFAULT_STRETCH_SPAN: FillStretchSpan = FillStretchSpan.LINE
## In STRETCH mode, what the texture's color stands for. See
## [enum FillStretchSpan]. Ignored outside STRETCH mode and when
## [member texture] is [code]null[/code].
@export var stretch_span: FillStretchSpan = DEFAULT_STRETCH_SPAN


const DEFAULT_TILE_SCALE: float = 1.0
## Uniform scale applied to the tile grid in [code]TILE[/code] mode.
## [code]1.0[/code] means one tile equals the texture's native pixel size on
## screen. [code]2.0[/code] doubles the tile size. The grid stays
## square-pixel correct regardless of pane shape. Ignored outside
## [code]TILE[/code] mode and when [member texture] is [code]null[/code].
@export var tile_scale: float = DEFAULT_TILE_SCALE


const DEFAULT_TILE_ROTATION_DEG: float = 0.0
## Rotation in degrees of the tile grid in TILE mode, turned around the pane
## center so it stays put as data updates. Ignored outside TILE mode and when
## [member texture] is [code]null[/code].
@export var tile_rotation_deg: float = DEFAULT_TILE_ROTATION_DEG


const DEFAULT_TILE_OFFSET_PX: Vector2 = Vector2.ZERO
## Screen-space translation applied to the tile grid in [code]TILE[/code]
## mode, after rotation. Expressed in pixels, so animating one component
## moves the pattern along the corresponding screen axis regardless of
## rotation angle or [member tile_scale]. Ignored outside [code]TILE[/code]
## mode and when [member texture] is [code]null[/code].
@export var tile_offset_px: Vector2 = DEFAULT_TILE_OFFSET_PX


####################################################################################################
# Cascade: user overrides
####################################################################################################

## Applies [param p_user_fill] on top of this instance, field by field,
## wherever the user value differs from the built-in default. A no-op when
## [param p_user_fill] is [code]null[/code].
func apply_overrides_from(p_user_fill: TauLineFill) -> void:
	if p_user_fill == null:
		return

	if p_user_fill.fill_mode != DEFAULT_FILL_MODE:
		fill_mode = p_user_fill.fill_mode
	if p_user_fill.fill_baseline != DEFAULT_FILL_BASELINE:
		fill_baseline = p_user_fill.fill_baseline
	if p_user_fill.stretch_range_policy != DEFAULT_STRETCH_RANGE_POLICY:
		stretch_range_policy = p_user_fill.stretch_range_policy
	if p_user_fill.stretch_range != DEFAULT_STRETCH_RANGE:
		stretch_range = p_user_fill.stretch_range
	if p_user_fill.color != DEFAULT_COLOR:
		color = p_user_fill.color
	if p_user_fill.alpha != DEFAULT_ALPHA:
		alpha = clampf(p_user_fill.alpha, 0.0, 1.0)
	if p_user_fill.texture != null:
		texture = p_user_fill.texture
	if p_user_fill.texture_mode != DEFAULT_TEXTURE_MODE:
		texture_mode = p_user_fill.texture_mode
	if p_user_fill.stretch_span != DEFAULT_STRETCH_SPAN:
		stretch_span = p_user_fill.stretch_span
	if p_user_fill.tile_scale != DEFAULT_TILE_SCALE:
		tile_scale = p_user_fill.tile_scale
	if p_user_fill.tile_rotation_deg != DEFAULT_TILE_ROTATION_DEG:
		tile_rotation_deg = p_user_fill.tile_rotation_deg
	if p_user_fill.tile_offset_px != DEFAULT_TILE_OFFSET_PX:
		tile_offset_px = p_user_fill.tile_offset_px


####################################################################################################
# Change detection
####################################################################################################

## Deep equality between this instance and [param p_other].
func is_equal_to(p_other: TauLineFill) -> bool:
	if p_other == null:
		return false
	if fill_mode != p_other.fill_mode:
		return false
	if fill_baseline != p_other.fill_baseline:
		return false
	if stretch_range_policy != p_other.stretch_range_policy:
		return false
	if stretch_range != p_other.stretch_range:
		return false
	if color != p_other.color:
		return false
	if alpha != p_other.alpha:
		return false
	if texture != p_other.texture:
		return false
	if texture_mode != p_other.texture_mode:
		return false
	if stretch_span != p_other.stretch_span:
		return false
	if tile_scale != p_other.tile_scale:
		return false
	if tile_rotation_deg != p_other.tile_rotation_deg:
		return false
	if tile_offset_px != p_other.tile_offset_px:
		return false
	return true
