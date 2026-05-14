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

## Reference frame that anchors [member fill_texture] in the pane. Picks how
## the texture moves as the data pans and zooms.
##
## [b]PANE_RECT[/b]: anchored to the pane rectangle. The texture stays
## stationary on screen.
##
## [b]FILL_BOUNDS[/b]: anchored to the bounding box of the filled area. The
## texture follows the fill as it pans and stretches as it zooms.
##
## [b]DATA_DOMAIN[/b]: anchored to the visible data domain. The U axis
## follows the data x direction and the V axis follows the data y direction,
## so axis inversion flips the texture along the matching axis.
enum FillAnchor
{
	PANE_RECT,
	FILL_BOUNDS,
	DATA_DOMAIN
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

## Reference frame that anchors [member fill_texture] in the pane. See
## [enum FillAnchor] for the available frames. Ignored when
## [member fill_texture] is [code]null[/code].
const DEFAULT_FILL_ANCHOR: FillAnchor = FillAnchor.PANE_RECT
@export var fill_anchor: FillAnchor = DEFAULT_FILL_ANCHOR

## Texture sampled across the fill area. When non-null, it overrides
## [member fill_color] and the per-series color. Its alpha is scaled by
## [member fill_alpha].
const DEFAULT_FILL_TEXTURE: Texture2D = null
@export var fill_texture: Texture2D = DEFAULT_FILL_TEXTURE

## Number of times [member fill_texture] repeats across the reference frame
## set by [member fill_anchor]. [code]Vector2(1, 1)[/code] fits the texture
## exactly once across the frame. [code]Vector2(10, 10)[/code] repeats it ten
## times in each direction. Ignored when [member fill_texture] is
## [code]null[/code].
const DEFAULT_FILL_TEXTURE_TILING: Vector2 = Vector2(1, 1)
@export var fill_texture_tiling: Vector2 = DEFAULT_FILL_TEXTURE_TILING

## UV translation applied to [member fill_texture] after tiling. Expressed in
## UV units where [code]1.0[/code] equals the texture's own span, so
## [code]Vector2(0.5, 0)[/code] shifts the texture by half its tile. Ignored
## when [member fill_texture] is [code]null[/code].
const DEFAULT_FILL_TEXTURE_OFFSET: Vector2 = Vector2(0, 0)
@export var fill_texture_offset: Vector2 = DEFAULT_FILL_TEXTURE_OFFSET

## Rotation in degrees applied to [member fill_texture] around the center
## of the reference frame, so a motif placed at the center rotates in place.
## Ignored when [member fill_texture] is [code]null[/code].
const DEFAULT_FILL_TEXTURE_ROTATION_DEG: float = 0.0
@export var fill_texture_rotation_deg: float = DEFAULT_FILL_TEXTURE_ROTATION_DEG


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
##   - [member fill_anchor]: [code]line_fill_anchor[/code] and
##     [code]line_fill_anchor_P[/code]. Stored as the integer enum value.
##   - [member fill_texture]: [code]line_fill_texture[/code] and
##     [code]line_fill_texture_P[/code]. Looked up as a theme icon.
##   - [member fill_texture_tiling]: stored as a pair of integers
##     [code]line_fill_texture_tiling_x_percent[/code] and
##     [code]line_fill_texture_tiling_y_percent[/code], each in hundredths
##     of the float value (so [code]100[/code] means [code]1.0[/code]).
##     The per-pane variants append [code]_P[/code].
##   - [member fill_texture_offset]: stored as a pair of integers
##     [code]line_fill_texture_offset_x_percent[/code] and
##     [code]line_fill_texture_offset_y_percent[/code], with the same
##     hundredths-of-float encoding. The per-pane variants append
##     [code]_P[/code].
##   - [member fill_texture_rotation_deg]:
##     [code]line_fill_texture_rotation_deg[/code] and
##     [code]line_fill_texture_rotation_deg_P[/code]. Stored as integer
##     degrees.
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

	# fill_anchor
	if p_control.has_theme_constant(&"line_fill_anchor"):
		fill_anchor = p_control.get_theme_constant(&"line_fill_anchor") as FillAnchor
	var indexed_fill_anchor_key := StringName("line_fill_anchor_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_fill_anchor_key):
		fill_anchor = p_control.get_theme_constant(indexed_fill_anchor_key) as FillAnchor

	# fill_texture
	if p_control.has_theme_icon(&"line_fill_texture"):
		fill_texture = p_control.get_theme_icon(&"line_fill_texture")
	var indexed_fill_texture_key := StringName("line_fill_texture_%d" % p_pane_index)
	if p_control.has_theme_icon(indexed_fill_texture_key):
		fill_texture = p_control.get_theme_icon(indexed_fill_texture_key)

	# fill_texture_tiling
	var tiling := fill_texture_tiling
	if p_control.has_theme_constant(&"line_fill_texture_tiling_x_percent"):
		tiling.x = float(p_control.get_theme_constant(&"line_fill_texture_tiling_x_percent")) / 100.0
	if p_control.has_theme_constant(&"line_fill_texture_tiling_y_percent"):
		tiling.y = float(p_control.get_theme_constant(&"line_fill_texture_tiling_y_percent")) / 100.0
	var indexed_tiling_x_key := StringName("line_fill_texture_tiling_x_percent_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_tiling_x_key):
		tiling.x = float(p_control.get_theme_constant(indexed_tiling_x_key)) / 100.0
	var indexed_tiling_y_key := StringName("line_fill_texture_tiling_y_percent_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_tiling_y_key):
		tiling.y = float(p_control.get_theme_constant(indexed_tiling_y_key)) / 100.0
	fill_texture_tiling = tiling

	# fill_texture_offset
	var offset := fill_texture_offset
	if p_control.has_theme_constant(&"line_fill_texture_offset_x_percent"):
		offset.x = float(p_control.get_theme_constant(&"line_fill_texture_offset_x_percent")) / 100.0
	if p_control.has_theme_constant(&"line_fill_texture_offset_y_percent"):
		offset.y = float(p_control.get_theme_constant(&"line_fill_texture_offset_y_percent")) / 100.0
	var indexed_offset_x_key := StringName("line_fill_texture_offset_x_percent_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_offset_x_key):
		offset.x = float(p_control.get_theme_constant(indexed_offset_x_key)) / 100.0
	var indexed_offset_y_key := StringName("line_fill_texture_offset_y_percent_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_offset_y_key):
		offset.y = float(p_control.get_theme_constant(indexed_offset_y_key)) / 100.0
	fill_texture_offset = offset

	# fill_texture_rotation_deg
	if p_control.has_theme_constant(&"line_fill_texture_rotation_deg"):
		fill_texture_rotation_deg = float(p_control.get_theme_constant(&"line_fill_texture_rotation_deg"))
	var indexed_rotation_key := StringName("line_fill_texture_rotation_deg_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_rotation_key):
		fill_texture_rotation_deg = float(p_control.get_theme_constant(indexed_rotation_key))


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
	if p_user_style.fill_anchor != DEFAULT_FILL_ANCHOR:
		fill_anchor = p_user_style.fill_anchor
	if p_user_style.fill_texture != DEFAULT_FILL_TEXTURE:
		fill_texture = p_user_style.fill_texture
	if p_user_style.fill_texture_tiling != DEFAULT_FILL_TEXTURE_TILING:
		fill_texture_tiling = p_user_style.fill_texture_tiling
	if p_user_style.fill_texture_offset != DEFAULT_FILL_TEXTURE_OFFSET:
		fill_texture_offset = p_user_style.fill_texture_offset
	if p_user_style.fill_texture_rotation_deg != DEFAULT_FILL_TEXTURE_ROTATION_DEG:
		fill_texture_rotation_deg = p_user_style.fill_texture_rotation_deg


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
	if fill_anchor != p_other.fill_anchor:
		return false
	if fill_texture != p_other.fill_texture:
		return false
	if fill_texture_tiling != p_other.fill_texture_tiling:
		return false
	if fill_texture_offset != p_other.fill_texture_offset:
		return false
	if fill_texture_rotation_deg != p_other.fill_texture_rotation_deg:
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
