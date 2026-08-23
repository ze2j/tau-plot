@tool

## Visual styling for the hover tooltip popup.
##
## Properties are resolved from the built-in defaults, the theme, and the values
## set here, in that order. See [TauStyle] for the details.
##
## Assign a new [StyleBox] or [Font] rather than mutating the one already
## assigned. An in-place change is not detected.
##
## Theme type variation: TauTooltip
class_name TauTooltipStyle extends TauStyle

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in `validate_resolved()`.
################################################################################################

## Background for the transient (non-pinned) tooltip.
## Can be StyleBoxFlat or StyleBoxTexture.
@export var style_box: StyleBox = null:
	set(value):
		style_box = value
		_mark(&"style_box")

## Background for the pinned tooltip. Allows a visual distinction
## between pinned and transient tooltips (for example a slightly more
## opaque background or a different border).
## When null, falls back to the normal style_box.
@export var pinned_style_box: StyleBox = null:
	set(value):
		pinned_style_box = value
		_mark(&"pinned_style_box")

## Font of the tooltip text. Left at [code]null[/code], the text is drawn in
## the font Godot uses by default.
@export var font: Font = null:
	set(value):
		font = value
		_mark(&"font")

## Size in pixels of the tooltip text. The theme's default font size applies
## unless the theme sets [code]font_size[/code] on the [code]TauTooltip[/code]
## type variation.
@export var font_size: int = 16:
	set(value):
		font_size = maxi(value, 1)
		_mark(&"font_size")

## Tooltip text color.
@export var font_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		font_color = value
		_mark(&"font_color")

## Padding inside the tooltip popup (px).
@export var padding_px: int = 8:
	set(value):
		padding_px = maxi(value, 0)
		_mark(&"padding_px")

## Offset from the anchor point (data point or cursor) in pixels.
@export var offset_px: Vector2i = Vector2i(12, -12):
	set(value):
		offset_px = value
		_mark(&"offset_px")

## Maximum tooltip width before text wraps (px). 0 = no limit.
@export var max_width_px: int = 300:
	set(value):
		max_width_px = maxi(value, 0)
		_mark(&"max_width_px")


#region Internal, not public API, may change without notice.

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


func load_from_theme(p_control: Control) -> void:
	if p_control == null:
		push_error("TauTooltipStyle.load_from_theme(): control is null")
		return

	if p_control.has_theme_stylebox(&"tooltip_style_box"):
		style_box = p_control.get_theme_stylebox(&"tooltip_style_box")

	if p_control.has_theme_stylebox(&"tooltip_pinned_style_box"):
		pinned_style_box = p_control.get_theme_stylebox(&"tooltip_pinned_style_box")

	# Fonts and font sizes always resolve through the theme chain down to the
	# engine defaults, so neither needs a guard.
	font = p_control.get_theme_font(&"font")
	font_size = p_control.get_theme_font_size(&"font_size")

	if p_control.has_theme_color(&"font_color"):
		font_color = p_control.get_theme_color(&"font_color")

	if p_control.has_theme_constant(&"tooltip_padding"):
		padding_px = p_control.get_theme_constant(&"tooltip_padding")

	var offset := offset_px
	if p_control.has_theme_constant(&"tooltip_offset_x"):
		offset.x = p_control.get_theme_constant(&"tooltip_offset_x")
	if p_control.has_theme_constant(&"tooltip_offset_y"):
		offset.y = p_control.get_theme_constant(&"tooltip_offset_y")
	offset_px = offset

	if p_control.has_theme_constant(&"tooltip_max_width"):
		max_width_px = p_control.get_theme_constant(&"tooltip_max_width")


func apply_overrides_from(p_user_style: TauTooltipStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.is_overridden(&"style_box"):
		style_box = p_user_style.style_box
	if p_user_style.is_overridden(&"pinned_style_box"):
		pinned_style_box = p_user_style.pinned_style_box
	if p_user_style.is_overridden(&"font"):
		font = p_user_style.font
	if p_user_style.is_overridden(&"font_size"):
		font_size = p_user_style.font_size
	if p_user_style.is_overridden(&"font_color"):
		font_color = p_user_style.font_color
	if p_user_style.is_overridden(&"padding_px"):
		padding_px = p_user_style.padding_px
	if p_user_style.is_overridden(&"offset_px"):
		offset_px = p_user_style.offset_px
	if p_user_style.is_overridden(&"max_width_px"):
		max_width_px = p_user_style.max_width_px


static func resolve(p_control: Control, p_user_style: TauTooltipStyle) -> TauTooltipStyle:
	# Layer 1: defaults.
	var resolved := TauTooltipStyle.new()
	resolved.style_box = _create_default_style_box()
	resolved.pinned_style_box = _create_default_pinned_style_box()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	# Layer 4: report what the resolved combination cannot draw.
	resolved.validate_resolved()
	return resolved


# Nothing spans two properties here. Every property stands on its own and its
# range is enforced on assignment.
func validate_resolved() -> void:
	pass


func is_equal_to(p_other: TauStyle) -> bool:
	var other := p_other as TauTooltipStyle
	if other == null:
		return false
	if not super.is_equal_to(other):
		return false
	if font_size != other.font_size:
		return false
	if font_color != other.font_color:
		return false
	if padding_px != other.padding_px:
		return false
	if offset_px != other.offset_px:
		return false
	if max_width_px != other.max_width_px:
		return false
	# StyleBox and font comparisons are reference-based (mutations are
	# picked up via the Resource.changed signal).
	if style_box != other.style_box:
		return false
	if pinned_style_box != other.pinned_style_box:
		return false
	if font != other.font:
		return false
	return true


# Returns the font the tooltip text is drawn with, never null.
func get_font() -> Font:
	if font == null:
		return ThemeDB.fallback_font
	return font

#endregion
