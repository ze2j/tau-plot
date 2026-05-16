## Contains theme-driven visual parameters for line overlays.
##
## Properties set on this resource take the highest priority, always winning
## over the theme and the built-in defaults.
##
## Properties left untouched fall back to the Godot theme. If the theme does
## not define them either, the built-in defaults apply.
##
## [b]Limitation:[/b] because "untouched" means "still equal to the built-in
## default", setting a property to exactly its default value has no visible
## effect. To force the default value to win over a theme, use an imperceptibly
## different value (e.g. 2.001 instead of 2.0).
class_name TauLineStyle extends Resource

## Sampling strategy for [member fill_texture]. Picks which parameter set
## drives the texture transform.
##
## [b]STRETCH[/b]: the texture is sampled once across a chosen span. Best
## for textures whose shape maps onto the fill, such as a vertical gradient
## fading toward the baseline. See [member fill_texture_stretch_axis] and
## [member fill_texture_stretch_span].
##
## [b]TILE[/b]: the texture is repeated at its native pixel size across the
## fill, with a square-pixel-correct grid that does not depend on pane shape.
## Best for seamless motifs (dots, hatching, stippling). See
## [member fill_texture_scale], [member fill_texture_rotation_deg], and
## [member fill_texture_offset_px].
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
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()`.
################################################################################################

## Per-series cycle of line widths in pixels in the normal state. Each entry
## sets the line width for one series, with the array indexed cyclically by
## series index using modulo: series [code]i[/code] reads entry
## [code]i % line_widths_px.size()[/code]. An empty array is treated as all
## series rendered at [code]2.0[/code] pixels.
const DEFAULT_LINE_WIDTHS_PX: Array[float] = [2.0]
@export var line_widths_px: Array[float] = [2.0]

## Per-series cycle of line widths in pixels for the two segments adjacent to
## the hovered sample. Each entry sets the hovered width for one series, with
## the array indexed cyclically by series index using modulo: series
## [code]i[/code] reads entry [code]i % hovered_line_widths_px.size()[/code].
## An empty array means no hover emphasis: the segments adjacent to the
## hovered sample are drawn at the resolved [member line_widths_px] value for
## that series.
##
## At draw time, the resolved per-series hovered width is clamped to be at
## least the resolved per-series base width from [member line_widths_px], so
## a thicker series never becomes thinner on hover.
const DEFAULT_HOVERED_LINE_WIDTHS_PX: Array[float] = [3.0]
@export var hovered_line_widths_px: Array[float] = [3.0]

## Per-series dash length cycle, in pixels. Each entry sets the dash length
## for one series, with the array indexed cyclically by series index using
## modulo: series [code]i[/code] reads entry
## [code]i % dash_lengths_px.size()[/code]. An entry of [code]0[/code]
## produces a solid line for that series. Any positive entry switches that
## series to dashed rendering with alternating on-off segments of that pixel
## length. An empty array is treated as all series solid.
const DEFAULT_DASH_LENGTHS_PX: Array[int] = [0]
@export var dash_lengths_px: Array[int] = [0]

## Flat color applied to the area defined by [member TauLineConfig.fill_mode].
## The sentinel [code]Color(0, 0, 0, 0)[/code] means "derive from the series
## color supplied by [member TauXYStyle.series_colors]". Any other value
## becomes a uniform flat fill shared across all series in the overlay.
## [code]Color(0, 0, 0, 0)[/code] is therefore not a valid explicit fill
## color.
##
## Overridden by [member fill_texture] when that is non-null. The resolved
## color's alpha is scaled by [member fill_alpha].
const DEFAULT_FILL_COLOR: Color = Color(0, 0, 0, 0)
@export var fill_color: Color = DEFAULT_FILL_COLOR

## Multiplier applied to the alpha of the resolved fill, whether that fill
## came from [member fill_color], from [member TauXYStyle.series_colors], or
## from [member fill_texture]. Valid range is [code][0.0, 1.0][/code].
const DEFAULT_FILL_ALPHA: float = 0.2
@export var fill_alpha: float = DEFAULT_FILL_ALPHA

## Texture sampled across the fill area. When non-null, it overrides
## [member fill_color] and the per-series color. Its alpha is scaled by
## [member fill_alpha].
##
## How the texture is mapped onto the fill is controlled by
## [member fill_texture_mode]. With the default mode [code]STRETCH[/code], a
## newly assigned texture spans from the line down to the baseline along the
## Y axis, which produces the area-chart gradient case without further
## configuration.
const DEFAULT_FILL_TEXTURE: Texture2D = null
@export var fill_texture: Texture2D = DEFAULT_FILL_TEXTURE

## Sampling strategy for [member fill_texture]. See [enum FillTextureMode]
## for the available modes. Selects which parameter set is active: the
## STRETCH parameters or the TILE parameters. Ignored when
## [member fill_texture] is [code]null[/code].
const DEFAULT_FILL_TEXTURE_MODE: FillTextureMode = FillTextureMode.STRETCH
@export var fill_texture_mode: FillTextureMode = DEFAULT_FILL_TEXTURE_MODE

## Axis along which the texture is sampled in [code]STRETCH[/code] mode.
## The non-stretch axis reads the texture at a fixed coordinate. Ignored
## outside [code]STRETCH[/code] mode and when [member fill_texture] is
## [code]null[/code].
const DEFAULT_FILL_TEXTURE_STRETCH_AXIS: FillStretchAxis = FillStretchAxis.Y
@export var fill_texture_stretch_axis: FillStretchAxis = DEFAULT_FILL_TEXTURE_STRETCH_AXIS

## What the texture endpoints are anchored to in [code]STRETCH[/code] mode.
## See [enum FillStretchSpan] for the available spans. Ignored outside
## [code]STRETCH[/code] mode and when [member fill_texture] is
## [code]null[/code].
##
## The combination [code]BASELINE[/code] + [code]FillStretchAxis.X[/code] is
## rejected at config time, since there is no "line edge" along X.
const DEFAULT_FILL_TEXTURE_STRETCH_SPAN: FillStretchSpan = FillStretchSpan.BASELINE
@export var fill_texture_stretch_span: FillStretchSpan = DEFAULT_FILL_TEXTURE_STRETCH_SPAN

## Uniform scale applied to the tile grid in [code]TILE[/code] mode.
## [code]1.0[/code] means one tile equals the texture's native pixel size on
## screen. [code]2.0[/code] doubles the tile size. The grid stays
## square-pixel correct regardless of pane shape. Ignored outside
## [code]TILE[/code] mode and when [member fill_texture] is [code]null[/code].
const DEFAULT_FILL_TEXTURE_SCALE: float = 1.0
@export var fill_texture_scale: float = DEFAULT_FILL_TEXTURE_SCALE

## Rotation in degrees applied to the texture.
##
## In [code]TILE[/code] mode, rotates the tile grid around the pane center,
## a stable point in pane coordinates that does not move as data updates.
##
## In [code]STRETCH[/code] mode, this property currently has no effect.
##
## Ignored when [member fill_texture] is [code]null[/code].
const DEFAULT_FILL_TEXTURE_ROTATION_DEG: float = 0.0
@export var fill_texture_rotation_deg: float = DEFAULT_FILL_TEXTURE_ROTATION_DEG

## Screen-space translation applied to the tile grid in [code]TILE[/code]
## mode, after rotation. Expressed in pixels, so animating one component
## moves the pattern along the corresponding screen axis regardless of
## rotation angle or [member fill_texture_scale]. Ignored outside
## [code]TILE[/code] mode and when [member fill_texture] is [code]null[/code].
const DEFAULT_FILL_TEXTURE_OFFSET_PX: Vector2 = Vector2.ZERO
@export var fill_texture_offset_px: Vector2 = DEFAULT_FILL_TEXTURE_OFFSET_PX


####################################################################################################
# Helpers
####################################################################################################

## Returns the resolved line width in pixels for the given series index.
##
## An empty [member line_widths_px] returns the default
## [constant DEFAULT_LINE_WIDTHS_PX] entry. The result is clamped to be
## non-negative.
func get_series_width_px(p_series_index: int) -> float:
	if line_widths_px.is_empty():
		return DEFAULT_LINE_WIDTHS_PX[0]
	var entry: float = line_widths_px[p_series_index % line_widths_px.size()]
	return max(entry, 0.0)


## Returns the resolved hovered line width in pixels for the given series
## index. An empty [member hovered_line_widths_px] returns [code]0.0[/code]
## as a "no hover emphasis" sentinel. The result is later clamped against
## the per-series base width from [member line_widths_px] at draw time, so
## the empty-array case falls back to the base width and never produces a
## thinner line on hover.
func get_series_hovered_width_px(p_series_index: int) -> float:
	if hovered_line_widths_px.is_empty():
		return 0.0
	var entry: float = hovered_line_widths_px[p_series_index % hovered_line_widths_px.size()]
	return max(entry, 0.0)


## Returns the resolved dash length in pixels for the given series index.
func get_series_dash_px(p_series_index: int) -> int:
	if dash_lengths_px.is_empty():
		return 0
	var entry: int = dash_lengths_px[p_series_index % dash_lengths_px.size()]
	return max(entry, 0)


## Returns the resolved fill color for the given series index.
##
## When [member fill_color] is the sentinel [code]Color(0, 0, 0, 0)[/code]
## the per-series color from [param p_xy_style] is used. Otherwise the flat
## [member fill_color] wins regardless of the series. In both cases the
## alpha channel of the returned color is multiplied by [member fill_alpha],
## clamped to [code][0.0, 1.0][/code].
func get_series_fill_color(p_series_index: int, p_xy_style: TauXYStyle) -> Color:
	var base: Color
	if fill_color == DEFAULT_FILL_COLOR:
		base = p_xy_style.get_series_color(p_series_index)
	else:
		base = fill_color
	base.a = clampf(base.a * fill_alpha, 0.0, 1.0)
	return base


####################################################################################################
# Cascade: theme loading (layer 2)
####################################################################################################

## Loads properties from the Godot theme attached to [param p_control].
##
## The per-series array properties use a two-level indexed lookup at series
## granularity:
##   1. [code]<key>_N[/code] sets the value for series N across all panes.
##   2. [code]<key>_N_P[/code] overrides series N in pane P only.
##
## Theme key prefixes for the per-series arrays:
##   - [member line_widths_px]:         [code]line_width_px[/code]
##   - [member hovered_line_widths_px]: [code]line_hovered_width_px[/code]
##   - [member dash_lengths_px]:        [code]line_dash_px[/code]
##
## The scalar fill properties use a non-indexed base key plus a per-pane
## indexed key that overwrites the base value for the matching pane:
##   - [member fill_color]: [code]line_fill_color[/code] and
##     [code]line_fill_color_P[/code].
##   - [member fill_alpha]: [code]line_fill_alpha_percent[/code] and
##     [code]line_fill_alpha_percent_P[/code]. Stored as a percentage in
##     the theme because theme constants are integers.
##   - [member fill_texture]: [code]line_fill_texture[/code] and
##     [code]line_fill_texture_P[/code]. Looked up as a theme icon.
##   - [member fill_texture_mode]: [code]line_fill_texture_mode[/code] and
##     [code]line_fill_texture_mode_P[/code]. Stored as the integer enum
##     value.
##   - [member fill_texture_stretch_axis]:
##     [code]line_fill_texture_stretch_axis[/code] and
##     [code]line_fill_texture_stretch_axis_P[/code]. Stored as the integer
##     enum value.
##   - [member fill_texture_stretch_span]:
##     [code]line_fill_texture_stretch_span[/code] and
##     [code]line_fill_texture_stretch_span_P[/code]. Stored as the integer
##     enum value.
##   - [member fill_texture_scale]:
##     [code]line_fill_texture_scale_percent[/code] and
##     [code]line_fill_texture_scale_percent_P[/code]. Stored in hundredths
##     of the float value ([code]100[/code] means [code]1.0[/code]).
##   - [member fill_texture_rotation_deg]:
##     [code]line_fill_texture_rotation_deg[/code] and
##     [code]line_fill_texture_rotation_deg_P[/code]. Stored as integer
##     degrees.
##   - [member fill_texture_offset_px]: stored as a pair of integers
##     [code]line_fill_texture_offset_px_x[/code] and
##     [code]line_fill_texture_offset_px_y[/code]. The per-pane variants
##     append [code]_P[/code].
##
## Every property is written unconditionally. Properties without a matching
## theme entry keep their current value, so this method is safe to call on
## an instance already populated with defaults.
func load_from_theme(p_control: Control, p_pane_index: int) -> void:
	if p_control == null:
		push_error("TauLineStyle.load_from_theme(): control is null")
		return

	# line_widths_px: two-level indexed lookup. Level 1 sets values across all
	# panes. Level 2 overrides per pane.
	var global_widths: Array[float] = []
	var width_index := 0
	while true:
		var key := "line_width_px_%d" % width_index
		if not p_control.has_theme_constant(key):
			break
		global_widths.append(max(float(p_control.get_theme_constant(key)), 0.0))
		width_index += 1

	if not global_widths.is_empty():
		line_widths_px = global_widths

	var pane_width_index := 0
	while true:
		var key := "line_width_px_%d_%d" % [pane_width_index, p_pane_index]
		if not p_control.has_theme_constant(key):
			break
		# Grow the array if the per-pane theme defines more width entries than
		# the global theme (or the default).
		if pane_width_index >= line_widths_px.size():
			line_widths_px.resize(pane_width_index + 1)
		line_widths_px[pane_width_index] = max(float(p_control.get_theme_constant(key)), 0.0)
		pane_width_index += 1

	# hovered_line_widths_px: two-level indexed lookup, same pattern as
	# line_widths_px.
	var global_hovered: Array[float] = []
	var hovered_index := 0
	while true:
		var key := "line_hovered_width_px_%d" % hovered_index
		if not p_control.has_theme_constant(key):
			break
		global_hovered.append(max(float(p_control.get_theme_constant(key)), 0.0))
		hovered_index += 1

	if not global_hovered.is_empty():
		hovered_line_widths_px = global_hovered

	var pane_hovered_index := 0
	while true:
		var key := "line_hovered_width_px_%d_%d" % [pane_hovered_index, p_pane_index]
		if not p_control.has_theme_constant(key):
			break
		if pane_hovered_index >= hovered_line_widths_px.size():
			hovered_line_widths_px.resize(pane_hovered_index + 1)
		hovered_line_widths_px[pane_hovered_index] = max(float(p_control.get_theme_constant(key)), 0.0)
		pane_hovered_index += 1

	# dash_lengths_px: two-level indexed lookup, same pattern as
	# line_widths_px.
	var global_dashes: Array[int] = []
	var dash_index := 0
	while true:
		var key := "line_dash_px_%d" % dash_index
		if not p_control.has_theme_constant(key):
			break
		global_dashes.append(max(int(p_control.get_theme_constant(key)), 0))
		dash_index += 1

	if not global_dashes.is_empty():
		dash_lengths_px = global_dashes

	var pane_dash_index := 0
	while true:
		var key := "line_dash_px_%d_%d" % [pane_dash_index, p_pane_index]
		if not p_control.has_theme_constant(key):
			break
		if pane_dash_index >= dash_lengths_px.size():
			dash_lengths_px.resize(pane_dash_index + 1)
		dash_lengths_px[pane_dash_index] = max(int(p_control.get_theme_constant(key)), 0)
		pane_dash_index += 1

	# Scalar fill properties. Each one uses a non-indexed base key plus a
	# per-pane key that overwrites it. Encoding details for the integer
	# theme constants live in the function docstring.

	# fill_color
	if p_control.has_theme_color(&"line_fill_color"):
		fill_color = p_control.get_theme_color(&"line_fill_color")
	var indexed_fill_color_key := StringName("line_fill_color_%d" % p_pane_index)
	if p_control.has_theme_color(indexed_fill_color_key):
		fill_color = p_control.get_theme_color(indexed_fill_color_key)

	# fill_alpha
	if p_control.has_theme_constant(&"line_fill_alpha_percent"):
		var alpha_percent := p_control.get_theme_constant(&"line_fill_alpha_percent")
		fill_alpha = clampf(float(alpha_percent) / 100.0, 0.0, 1.0)
	var indexed_fill_alpha_key := StringName("line_fill_alpha_percent_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_fill_alpha_key):
		var alpha_percent_p := p_control.get_theme_constant(indexed_fill_alpha_key)
		fill_alpha = clampf(float(alpha_percent_p) / 100.0, 0.0, 1.0)

	# fill_texture
	if p_control.has_theme_icon(&"line_fill_texture"):
		fill_texture = p_control.get_theme_icon(&"line_fill_texture")
	var indexed_fill_texture_key := StringName("line_fill_texture_%d" % p_pane_index)
	if p_control.has_theme_icon(indexed_fill_texture_key):
		fill_texture = p_control.get_theme_icon(indexed_fill_texture_key)

	# fill_texture_mode
	if p_control.has_theme_constant(&"line_fill_texture_mode"):
		fill_texture_mode = p_control.get_theme_constant(&"line_fill_texture_mode") as FillTextureMode
	var indexed_mode_key := StringName("line_fill_texture_mode_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_mode_key):
		fill_texture_mode = p_control.get_theme_constant(indexed_mode_key) as FillTextureMode

	# fill_texture_stretch_axis
	if p_control.has_theme_constant(&"line_fill_texture_stretch_axis"):
		fill_texture_stretch_axis = p_control.get_theme_constant(&"line_fill_texture_stretch_axis") as FillStretchAxis
	var indexed_axis_key := StringName("line_fill_texture_stretch_axis_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_axis_key):
		fill_texture_stretch_axis = p_control.get_theme_constant(indexed_axis_key) as FillStretchAxis

	# fill_texture_stretch_span
	if p_control.has_theme_constant(&"line_fill_texture_stretch_span"):
		fill_texture_stretch_span = p_control.get_theme_constant(&"line_fill_texture_stretch_span") as FillStretchSpan
	var indexed_span_key := StringName("line_fill_texture_stretch_span_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_span_key):
		fill_texture_stretch_span = p_control.get_theme_constant(indexed_span_key) as FillStretchSpan

	# fill_texture_scale
	if p_control.has_theme_constant(&"line_fill_texture_scale_percent"):
		fill_texture_scale = float(p_control.get_theme_constant(&"line_fill_texture_scale_percent")) / 100.0
	var indexed_scale_key := StringName("line_fill_texture_scale_percent_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_scale_key):
		fill_texture_scale = float(p_control.get_theme_constant(indexed_scale_key)) / 100.0

	# fill_texture_rotation_deg
	if p_control.has_theme_constant(&"line_fill_texture_rotation_deg"):
		fill_texture_rotation_deg = float(p_control.get_theme_constant(&"line_fill_texture_rotation_deg"))
	var indexed_rotation_key := StringName("line_fill_texture_rotation_deg_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_rotation_key):
		fill_texture_rotation_deg = float(p_control.get_theme_constant(indexed_rotation_key))

	# fill_texture_offset_px
	var offset_px := fill_texture_offset_px
	if p_control.has_theme_constant(&"line_fill_texture_offset_px_x"):
		offset_px.x = float(p_control.get_theme_constant(&"line_fill_texture_offset_px_x"))
	if p_control.has_theme_constant(&"line_fill_texture_offset_px_y"):
		offset_px.y = float(p_control.get_theme_constant(&"line_fill_texture_offset_px_y"))
	var indexed_offset_x_key := StringName("line_fill_texture_offset_px_x_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_offset_x_key):
		offset_px.x = float(p_control.get_theme_constant(indexed_offset_x_key))
	var indexed_offset_y_key := StringName("line_fill_texture_offset_px_y_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_offset_y_key):
		offset_px.y = float(p_control.get_theme_constant(indexed_offset_y_key))
	fill_texture_offset_px = offset_px


####################################################################################################
# Cascade: user overrides (layer 3)
####################################################################################################

## Applies overridden properties from [param p_user_style] onto this resolved
## instance. A property is considered overridden when its value on the user
## resource differs from the matching DEFAULT_* constant.
func apply_overrides_from(p_user_style: TauLineStyle) -> void:
	if p_user_style == null:
		return

	if _is_line_widths_overridden(p_user_style.line_widths_px):
		line_widths_px = p_user_style.line_widths_px.duplicate()
	if _is_hovered_line_widths_overridden(p_user_style.hovered_line_widths_px):
		hovered_line_widths_px = p_user_style.hovered_line_widths_px.duplicate()
	if _is_dash_lengths_overridden(p_user_style.dash_lengths_px):
		dash_lengths_px = p_user_style.dash_lengths_px.duplicate()

	if p_user_style.fill_color != DEFAULT_FILL_COLOR:
		fill_color = p_user_style.fill_color
	if p_user_style.fill_alpha != DEFAULT_FILL_ALPHA:
		fill_alpha = clampf(p_user_style.fill_alpha, 0.0, 1.0)
	if p_user_style.fill_texture != DEFAULT_FILL_TEXTURE:
		fill_texture = p_user_style.fill_texture
	if p_user_style.fill_texture_mode != DEFAULT_FILL_TEXTURE_MODE:
		fill_texture_mode = p_user_style.fill_texture_mode
	if p_user_style.fill_texture_stretch_axis != DEFAULT_FILL_TEXTURE_STRETCH_AXIS:
		fill_texture_stretch_axis = p_user_style.fill_texture_stretch_axis
	if p_user_style.fill_texture_stretch_span != DEFAULT_FILL_TEXTURE_STRETCH_SPAN:
		fill_texture_stretch_span = p_user_style.fill_texture_stretch_span
	if p_user_style.fill_texture_scale != DEFAULT_FILL_TEXTURE_SCALE:
		fill_texture_scale = p_user_style.fill_texture_scale
	if p_user_style.fill_texture_rotation_deg != DEFAULT_FILL_TEXTURE_ROTATION_DEG:
		fill_texture_rotation_deg = p_user_style.fill_texture_rotation_deg
	if p_user_style.fill_texture_offset_px != DEFAULT_FILL_TEXTURE_OFFSET_PX:
		fill_texture_offset_px = p_user_style.fill_texture_offset_px


####################################################################################################
# Full cascade resolution
####################################################################################################

## Produces a fully resolved TauLineStyle by applying all three cascade layers:
##   1. Start from defaults (a fresh TauLineStyle instance).
##   2. Load theme values (non-indexed, then indexed for this pane).
##   3. Apply user overrides from [param p_user_style] (may be null).
##
## The returned instance is a new TauLineStyle owned by the caller.
## [param p_user_style] is never mutated.
static func resolve(
	p_control: Control,
	p_pane_index: int,
	p_user_style: TauLineStyle
) -> TauLineStyle:
	var resolved := TauLineStyle.new()
	resolved.load_from_theme(p_control, p_pane_index)
	resolved.apply_overrides_from(p_user_style)
	return resolved


####################################################################################################
# Change detection
####################################################################################################

## Deep equality between this instance and [param p_other]. Compares every
## public property value-for-value, including the per-series arrays.
func is_equal_to(p_other: TauLineStyle) -> bool:
	if p_other == null:
		return false
	if line_widths_px.size() != p_other.line_widths_px.size():
		return false
	for i in range(line_widths_px.size()):
		if line_widths_px[i] != p_other.line_widths_px[i]:
			return false
	if hovered_line_widths_px.size() != p_other.hovered_line_widths_px.size():
		return false
	for i in range(hovered_line_widths_px.size()):
		if hovered_line_widths_px[i] != p_other.hovered_line_widths_px[i]:
			return false
	if dash_lengths_px.size() != p_other.dash_lengths_px.size():
		return false
	for i in range(dash_lengths_px.size()):
		if dash_lengths_px[i] != p_other.dash_lengths_px[i]:
			return false
	if fill_color != p_other.fill_color:
		return false
	if fill_alpha != p_other.fill_alpha:
		return false
	if fill_texture != p_other.fill_texture:
		return false
	if fill_texture_mode != p_other.fill_texture_mode:
		return false
	if fill_texture_stretch_axis != p_other.fill_texture_stretch_axis:
		return false
	if fill_texture_stretch_span != p_other.fill_texture_stretch_span:
		return false
	if fill_texture_scale != p_other.fill_texture_scale:
		return false
	if fill_texture_rotation_deg != p_other.fill_texture_rotation_deg:
		return false
	if fill_texture_offset_px != p_other.fill_texture_offset_px:
		return false
	return true


## Returns true if a change from [param p_other] to this instance would
## require the surrounding layout (domain, ticks, pane rect) to be
## recomputed. Always false: TauLineStyle properties only affect how lines
## are drawn within a fixed domain.
func has_layout_affecting_change(p_other: TauLineStyle) -> bool:
	return false


####################################################################################################
# Private
####################################################################################################

# Element-wise inequality between p_widths and DEFAULT_LINE_WIDTHS_PX. Typed
# arrays in GDScript do not have a reliable equality operator against module
# constants, so the comparison runs through size and indices.
static func _is_line_widths_overridden(p_widths: Array[float]) -> bool:
	if p_widths.size() != DEFAULT_LINE_WIDTHS_PX.size():
		return true
	for i in range(p_widths.size()):
		if p_widths[i] != DEFAULT_LINE_WIDTHS_PX[i]:
			return true
	return false


# Element-wise inequality between p_widths and DEFAULT_HOVERED_LINE_WIDTHS_PX.
static func _is_hovered_line_widths_overridden(p_widths: Array[float]) -> bool:
	if p_widths.size() != DEFAULT_HOVERED_LINE_WIDTHS_PX.size():
		return true
	for i in range(p_widths.size()):
		if p_widths[i] != DEFAULT_HOVERED_LINE_WIDTHS_PX[i]:
			return true
	return false


# Element-wise inequality between p_dashes and DEFAULT_DASH_LENGTHS_PX.
static func _is_dash_lengths_overridden(p_dashes: Array[int]) -> bool:
	if p_dashes.size() != DEFAULT_DASH_LENGTHS_PX.size():
		return true
	for i in range(p_dashes.size()):
		if p_dashes[i] != DEFAULT_DASH_LENGTHS_PX[i]:
			return true
	return false
