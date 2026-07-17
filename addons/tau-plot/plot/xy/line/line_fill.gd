## Visual parameters for one series' line-chart fill.
class_name TauLineFill extends Resource

## Sampling strategy for [member texture]. Picks which parameter set
## drives the texture transform.
##
## [b]STRETCH[/b]: the texture is sampled once across a chosen span. Best
## for textures whose shape maps onto the fill, such as a vertical gradient
## fading toward the baseline. See [member stretch_axis] and
## [member stretch_span].
##
## [b]TILE[/b]: the texture is repeated at its native pixel size across the
## fill, with a square-pixel-correct grid that does not depend on pane shape.
## Best for seamless motifs (dots, hatching, stippling). See
## [member tile_scale], [member tile_rotation_deg], and
## [member tile_offset_px].
enum FillTextureMode
{
	STRETCH,
	TILE
}

## Direction along which a STRETCH texture is sampled.
enum FillStretchAxis
{
	X,
	Y
}

## What the endpoints of a STRETCH texture are anchored to.
##
## [b]PANE[/b]: the texture spans the whole pane in the stretch direction.
## Endpoints stay glued to the pane edges as data updates, so the texture
## feels like a property of the chart background. The portion that ends up
## visible inside the fill depends on how much of the pane the polygon
## covers.
##
## [b]POLYGON[/b]: the texture spans the fill polygon's axis-aligned
## bounding box in the stretch direction. The full texture is always
## visible inside the fill, at the cost of rescaling whenever the polygon's
## extent changes.
##
## [b]BASELINE[/b]: the texture spans from the line to the opposite edge of
## the fill polygon in the stretch direction. One endpoint is glued to the
## line, the other to the closing edge: the horizontal [member
## TauLineConfig.fill_baseline] for [code]TO_BASELINE[/code], or the
## layer-below curve for [code]STACKED[/code]. Only valid with
## [code]FillStretchAxis.Y[/code].
enum FillStretchSpan
{
	PANE,
	POLYGON,
	BASELINE
}

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()` and
#          `apply_overrides_from()`.
################################################################################################

## Sentinel value for [member color] meaning "derive from the per-series
## color supplied by [member TauXYStyle.series_colors]". As a consequence,
## [code]Color(0, 0, 0, 0)[/code] is not a valid explicit fill color.
const NO_COLOR: Color = Color(0, 0, 0, 0)

const DEFAULT_COLOR: Color = NO_COLOR
## Flat fill color applied to the area defined by
## [member TauLineConfig.fill_mode]. The sentinel [constant NO_COLOR] means
## "derive from the per-series color supplied by
## [member TauXYStyle.series_colors]".
##
## Overridden by [member texture] when it is non-null. The resolved color's
## alpha is scaled by [member alpha].
@export var color: Color = DEFAULT_COLOR

const DEFAULT_ALPHA: float = 0.5
## Multiplier applied to the alpha of the resolved fill, whether that fill
## came from [member color], from [member TauXYStyle.series_colors], or
## from [member texture]. Valid range is [code][0.0, 1.0][/code].
@export var alpha: float = DEFAULT_ALPHA

## Texture sampled across the fill area. When non-null, overrides
## [member color] and the per-series color. The texture's alpha is scaled
## by [member alpha].
##
## How the texture is mapped onto the fill is controlled by [member
## texture_mode]. With the default mode [code]STRETCH[/code], a newly
## assigned texture spans from the line down to the baseline along the Y
## axis, which produces the area-chart gradient case without further
## configuration.
@export var texture: Texture2D = null

const DEFAULT_TEXTURE_MODE: FillTextureMode = FillTextureMode.STRETCH
## Sampling strategy for [member texture]. See [enum FillTextureMode] for
## the available modes. Selects which parameter set is active: the STRETCH
## parameters or the TILE parameters. Ignored when [member texture] is
## [code]null[/code].
@export var texture_mode: FillTextureMode = DEFAULT_TEXTURE_MODE


const DEFAULT_STRETCH_AXIS: FillStretchAxis = FillStretchAxis.Y
## Axis along which the texture is sampled in [code]STRETCH[/code] mode.
## The non-stretch axis reads the texture at a fixed coordinate. Ignored
## outside [code]STRETCH[/code] mode and when [member texture] is
## [code]null[/code].
@export var stretch_axis: FillStretchAxis = DEFAULT_STRETCH_AXIS

const DEFAULT_STRETCH_SPAN: FillStretchSpan = FillStretchSpan.BASELINE
## What the texture endpoints are anchored to in [code]STRETCH[/code] mode.
## See [enum FillStretchSpan] for the available spans. Ignored outside
## [code]STRETCH[/code] mode and when [member texture] is [code]null[/code].
##
## The combination [code]BASELINE[/code] + [code]FillStretchAxis.X[/code] is
## rejected at config time, since there is no "line edge" along X.
@export var stretch_span: FillStretchSpan = DEFAULT_STRETCH_SPAN


const DEFAULT_TILE_SCALE: float = 1.0
## Uniform scale applied to the tile grid in [code]TILE[/code] mode.
## [code]1.0[/code] means one tile equals the texture's native pixel size on
## screen. [code]2.0[/code] doubles the tile size. The grid stays
## square-pixel correct regardless of pane shape. Ignored outside
## [code]TILE[/code] mode and when [member texture] is [code]null[/code].
@export var tile_scale: float = DEFAULT_TILE_SCALE

const DEFAULT_TILE_ROTATION_DEG: float = 0.0
## Rotation in degrees applied to the texture.
##
## In [code]TILE[/code] mode, rotates the tile grid around the pane center,
## a stable point in pane coordinates that does not move as data updates.
##
## In [code]STRETCH[/code] mode, this property currently has no effect.
##
## Ignored when [member texture] is [code]null[/code].
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

	if p_user_fill.color != DEFAULT_COLOR:
		color = p_user_fill.color
	if p_user_fill.alpha != DEFAULT_ALPHA:
		alpha = clampf(p_user_fill.alpha, 0.0, 1.0)
	if p_user_fill.texture != null:
		texture = p_user_fill.texture
	if p_user_fill.texture_mode != DEFAULT_TEXTURE_MODE:
		texture_mode = p_user_fill.texture_mode
	if p_user_fill.stretch_axis != DEFAULT_STRETCH_AXIS:
		stretch_axis = p_user_fill.stretch_axis
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
	if color != p_other.color:
		return false
	if alpha != p_other.alpha:
		return false
	if texture != p_other.texture:
		return false
	if texture_mode != p_other.texture_mode:
		return false
	if stretch_axis != p_other.stretch_axis:
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
