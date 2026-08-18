@tool

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
## - Fill with no outline: any of the above with the series entry in
## [member TauLineStyle.line_widths_px] set to [code]0[/code].
##
## A field counts as set as soon as it is assigned, whatever the value. See
## [TauStyle] for the details.
##
## Assign a new [Texture2D] rather than mutating the one already assigned. An
## in-place change is not detected.
##
## Theme type variation: TauLine
class_name TauLineFill extends TauStyle

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in `validate_resolved()`.
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
## Which area around this series' line is painted. NONE, the default, leaves
## the series unfilled.
@export var fill_mode: FillMode = FillMode.NONE:
	set(value):
		fill_mode = value
		_mark(&"fill_mode")


## Reference y level for a TO_BASELINE fill, in data units on the series
## y-axis. The fill is drawn between the line and this level. Ignored by the
## other [member fill_mode] values.
##
## The MAGNITUDE stretch span measures its distance from this level. See
## [enum FillStretchSpan].
@export var fill_baseline: float = 0.0:
	set(value):
		fill_baseline = value
		_mark(&"fill_baseline")


## Where a value stretch span reads its low and high ends. See
## [member stretch_span].
enum StretchRangePolicy
{
	DOMAIN,   ## Span the whole series, from its lowest value to its highest.
	CUSTOM    ## Use the fixed window set in [member stretch_range].
}
## Where a value stretch span reads its low and high ends. See
## [enum StretchRangePolicy].
@export var stretch_range_policy: StretchRangePolicy = StretchRangePolicy.DOMAIN:
	set(value):
		stretch_range_policy = value
		_mark(&"stretch_range_policy")

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
@export var stretch_range: Vector2 = Vector2.ZERO:
	set(value):
		stretch_range = value
		_mark(&"stretch_range")


## Sentinel value for [member color] meaning "derive from the per-series
## color supplied by [member TauXYStyle.series_colors]". As a consequence,
## [code]Color(0, 0, 0, 0)[/code] is not a valid explicit fill color.
const NO_COLOR: Color = Color(0, 0, 0, 0)
## Flat fill color applied to the area defined by [member fill_mode]. The
## sentinel [constant NO_COLOR] means "derive from the per-series color
## supplied by [member TauXYStyle.series_colors]".
##
## Overridden by [member texture] when it is non-null. The resolved color's
## alpha is scaled by [member alpha].
@export var color: Color = NO_COLOR:
	set(value):
		color = value
		_mark(&"color")


## Multiplier applied to the alpha of the resolved fill, whether that fill
## came from [member color], from [member TauXYStyle.series_colors], or
## from [member texture]. Valid range is [code][0.0, 1.0][/code].
@export var alpha: float = 0.5:
	set(value):
		alpha = clampf(value, 0.0, 1.0)
		_mark(&"alpha")


## Texture painted over the fill area. When set, it takes the place of
## [member color] and the per-series color. Its own alpha is scaled by
## [member alpha].
##
## [member texture_mode] decides how it is painted. Out of the box, a freshly
## assigned texture fades from the line to the baseline, the ready-made
## area-chart gradient, with nothing else to set.
@export var texture: Texture2D = null:
	set(value):
		texture = value
		_mark(&"texture")


## How [member texture] is painted across the fill.
enum FillTextureMode
{
	STRETCH,   ## Fit the texture across the fill once, so it reads as a single gradient or band. What it maps to is set by [member stretch_span].
	TILE       ## Repeat the texture at its native pixel size, for a seamless motif like dots or hatching.
}
## How [member texture] is painted, stretched once or tiled. See
## [enum FillTextureMode]. Ignored when [member texture] is [code]null[/code].
@export var texture_mode: FillTextureMode = FillTextureMode.STRETCH:
	set(value):
		texture_mode = value
		_mark(&"texture_mode")


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
## In STRETCH mode, what the texture's color stands for. See
## [enum FillStretchSpan]. Ignored outside STRETCH mode and when
## [member texture] is [code]null[/code].
@export var stretch_span: FillStretchSpan = FillStretchSpan.LINE:
	set(value):
		stretch_span = value
		_mark(&"stretch_span")


## Uniform scale applied to the tile grid in [code]TILE[/code] mode.
## [code]1.0[/code] means one tile equals the texture's native pixel size on
## screen. [code]2.0[/code] doubles the tile size. The grid stays
## square-pixel correct regardless of pane shape. Ignored outside
## [code]TILE[/code] mode and when [member texture] is [code]null[/code].
@export var tile_scale: float = 1.0:
	set(value):
		tile_scale = value
		_mark(&"tile_scale")


## Rotation in degrees of the tile grid in TILE mode, turned around the pane
## center so it stays put as data updates. Ignored outside TILE mode and when
## [member texture] is [code]null[/code].
@export var tile_rotation_deg: float = 0.0:
	set(value):
		tile_rotation_deg = value
		_mark(&"tile_rotation_deg")


## Screen-space translation applied to the tile grid in [code]TILE[/code]
## mode, after rotation. Expressed in pixels, so animating one component
## moves the pattern along the corresponding screen axis regardless of
## rotation angle or [member tile_scale]. Ignored outside [code]TILE[/code]
## mode and when [member texture] is [code]null[/code].
@export var tile_offset_px: Vector2 = Vector2.ZERO:
	set(value):
		tile_offset_px = value
		_mark(&"tile_offset_px")


#region Internal, not public API, may change without notice.

# Applies the overridden fields of p_user_fill on top of this instance, field
# by field. A no-op when p_user_fill is null.
func apply_overrides_from(p_user_fill: TauLineFill) -> void:
	if p_user_fill == null:
		return

	if p_user_fill.is_overridden(&"fill_mode"):
		fill_mode = p_user_fill.fill_mode
	if p_user_fill.is_overridden(&"fill_baseline"):
		fill_baseline = p_user_fill.fill_baseline
	if p_user_fill.is_overridden(&"stretch_range_policy"):
		stretch_range_policy = p_user_fill.stretch_range_policy
	if p_user_fill.is_overridden(&"stretch_range"):
		stretch_range = p_user_fill.stretch_range
	if p_user_fill.is_overridden(&"color"):
		color = p_user_fill.color
	if p_user_fill.is_overridden(&"alpha"):
		alpha = p_user_fill.alpha
	if p_user_fill.is_overridden(&"texture"):
		texture = p_user_fill.texture
	if p_user_fill.is_overridden(&"texture_mode"):
		texture_mode = p_user_fill.texture_mode
	if p_user_fill.is_overridden(&"stretch_span"):
		stretch_span = p_user_fill.stretch_span
	if p_user_fill.is_overridden(&"tile_scale"):
		tile_scale = p_user_fill.tile_scale
	if p_user_fill.is_overridden(&"tile_rotation_deg"):
		tile_rotation_deg = p_user_fill.tile_rotation_deg
	if p_user_fill.is_overridden(&"tile_offset_px"):
		tile_offset_px = p_user_fill.tile_offset_px


# Reports the resolved field combinations that cannot be drawn as configured.
# Each rule reads this fill alone, so it holds wherever the fill ends up in the
# cycle. Nothing here stops the fill from being drawn.
func validate_resolved() -> void:
	if stretch_range_policy == StretchRangePolicy.CUSTOM:
		if texture_mode != FillTextureMode.STRETCH or stretch_span == FillStretchSpan.LINE:
			push_warning("TauLineFill: CUSTOM stretch_range_policy is set but this fill never reads it, use DOMAIN or give the fill a VALUE_X, VALUE_Y or MAGNITUDE span")
		elif stretch_range.x == stretch_range.y:
			push_error("TauLineFill: CUSTOM stretch_range is zero width (stretch_range.x == stretch_range.y), no gradient to draw")
		elif stretch_span == FillStretchSpan.MAGNITUDE and (stretch_range.x < 0.0 or stretch_range.y < 0.0):
			push_warning("TauLineFill: MAGNITUDE stretch_span measures a distance from fill_baseline, so a negative stretch_range end reads as its absolute value, got %s" % stretch_range)

	if texture_mode == FillTextureMode.TILE and texture != null and tile_scale <= 0.0:
		push_warning("TauLineFill: tile_scale is %s, the tiled texture is not painted" % tile_scale)

	if fill_mode != FillMode.NONE and texture == null and color == NO_COLOR and alpha == 0.0:
		push_warning("TauLineFill: an area is filled but alpha is 0, the fill is invisible")


# Returns a copy of this fill carrying the field values and the override
# flags. The flags are copied explicitly because Resource.duplicate() only
# copies stored properties.
func make_snapshot() -> TauLineFill:
	var copy := duplicate() as TauLineFill
	copy._copy_overrides_from(self)
	return copy


# Deep equality between this instance and p_other. Compares every field
# value-for-value, plus the set of overridden field names.
func is_equal_to(p_other: TauStyle) -> bool:
	var other := p_other as TauLineFill
	if other == null:
		return false
	if not super.is_equal_to(other):
		return false
	if fill_mode != other.fill_mode:
		return false
	if fill_baseline != other.fill_baseline:
		return false
	if stretch_range_policy != other.stretch_range_policy:
		return false
	if stretch_range != other.stretch_range:
		return false
	if color != other.color:
		return false
	if alpha != other.alpha:
		return false
	if texture != other.texture:
		return false
	if texture_mode != other.texture_mode:
		return false
	if stretch_span != other.stretch_span:
		return false
	if tile_scale != other.tile_scale:
		return false
	if tile_rotation_deg != other.tile_rotation_deg:
		return false
	if tile_offset_px != other.tile_offset_px:
		return false
	return true

#endregion
