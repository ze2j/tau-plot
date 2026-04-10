## Visual styling for the hover tooltip popup.
##
## Resolved through the same three-layer cascade (defaults, theme, user
## overrides) as TauBarStyle, TauScatterStyle, TauPaneStyle.
##
## Theme type variation: TauTooltip
class_name TauTooltipStyle extends Resource

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`.
################################################################################################

## Background for the transient (non-pinned) tooltip.
## Can be StyleBoxFlat or StyleBoxTexture.
@export var style_box: StyleBox = null

## Background for the pinned tooltip. Allows a visual distinction
## between pinned and transient tooltips (for example a slightly more
## opaque background or a different border).
## When null, falls back to the normal style_box.
@export var pinned_style_box: StyleBox = null

## Tooltip text font. Falls back to TauXYStyle.label_font if null.
@export var font: Font = null

const DEFAULT_FONT_SIZE: int = 14
## Tooltip text font size.
@export var font_size: int = DEFAULT_FONT_SIZE

const DEFAULT_FONT_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
## Tooltip text color.
@export var font_color: Color = DEFAULT_FONT_COLOR

const DEFAULT_PADDING_PX: int = 8
## Padding inside the tooltip popup (px).
@export var padding_px: int = DEFAULT_PADDING_PX

const DEFAULT_OFFSET_PX: Vector2i = Vector2i(12, -12)
## Offset from the anchor point (data point or cursor) in pixels.
@export var offset_px: Vector2i = DEFAULT_OFFSET_PX

const DEFAULT_MAX_WIDTH_PX: int = 300
## Maximum tooltip width before text wraps (px). 0 = no limit.
@export var max_width_px: int = DEFAULT_MAX_WIDTH_PX


####################################################################################################
# Cascade: built-in default (layer 1)
####################################################################################################

static func _create_default_style_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	return sb


static func _create_default_pinned_style_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.border_width_bottom = 1
	sb.border_width_top = 1
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_color = Color(1.0, 1.0, 1.0, 0.3)
	return sb


####################################################################################################
# Cascade: theme loading (layer 2)
####################################################################################################

func load_from_theme(p_control: Control) -> void:
	if p_control == null:
		push_error("TauTooltipStyle.load_from_theme(): control is null")
		return

	if p_control.has_theme_stylebox(&"tooltip_style_box"):
		style_box = p_control.get_theme_stylebox(&"tooltip_style_box")

	if p_control.has_theme_stylebox(&"tooltip_pinned_style_box"):
		pinned_style_box = p_control.get_theme_stylebox(&"tooltip_pinned_style_box")

	if p_control.has_theme_font(&"font"):
		font = p_control.get_theme_font(&"font")

	if p_control.has_theme_font_size(&"font_size"):
		font_size = max(p_control.get_theme_font_size(&"font_size"), 1)

	if p_control.has_theme_color(&"font_color"):
		font_color = p_control.get_theme_color(&"font_color")

	if p_control.has_theme_constant(&"tooltip_padding"):
		padding_px = max(p_control.get_theme_constant(&"tooltip_padding"), 0)

	if p_control.has_theme_constant(&"tooltip_offset_x"):
		offset_px.x = p_control.get_theme_constant(&"tooltip_offset_x")

	if p_control.has_theme_constant(&"tooltip_offset_y"):
		offset_px.y = p_control.get_theme_constant(&"tooltip_offset_y")

	if p_control.has_theme_constant(&"tooltip_max_width"):
		max_width_px = max(p_control.get_theme_constant(&"tooltip_max_width"), 0)


####################################################################################################
# Cascade: user overrides (layer 3)
####################################################################################################

func apply_overrides_from(p_user_style: TauTooltipStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.style_box != null:
		style_box = p_user_style.style_box
	if p_user_style.pinned_style_box != null:
		pinned_style_box = p_user_style.pinned_style_box
	if p_user_style.font != null:
		font = p_user_style.font
	if p_user_style.font_size != DEFAULT_FONT_SIZE:
		font_size = p_user_style.font_size
	if p_user_style.font_color != DEFAULT_FONT_COLOR:
		font_color = p_user_style.font_color
	if p_user_style.padding_px != DEFAULT_PADDING_PX:
		padding_px = p_user_style.padding_px
	if p_user_style.offset_px != DEFAULT_OFFSET_PX:
		offset_px = p_user_style.offset_px
	if p_user_style.max_width_px != DEFAULT_MAX_WIDTH_PX:
		max_width_px = p_user_style.max_width_px


####################################################################################################
# Full cascade resolution
####################################################################################################

static func resolve(p_control: Control, p_user_style: TauTooltipStyle) -> TauTooltipStyle:
	# Layer 1: defaults.
	var resolved := TauTooltipStyle.new()
	resolved.style_box = _create_default_style_box()
	resolved.pinned_style_box = _create_default_pinned_style_box()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	return resolved


####################################################################################################
# Change detection
####################################################################################################

func is_equal_to(p_other: TauTooltipStyle) -> bool:
	if p_other == null:
		return false
	if font_size != p_other.font_size:
		return false
	if font_color != p_other.font_color:
		return false
	if padding_px != p_other.padding_px:
		return false
	if offset_px != p_other.offset_px:
		return false
	if max_width_px != p_other.max_width_px:
		return false
	# StyleBox and font comparisons are reference-based (mutations are
	# picked up via the Resource.changed signal).
	if style_box != p_other.style_box:
		return false
	if pinned_style_box != p_other.pinned_style_box:
		return false
	if font != p_other.font:
		return false
	return true
