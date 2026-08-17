@tool

## Visual style for the legend.
##
## Properties are resolved from the built-in defaults, the theme, and the values
## set here, in that order. TauLegendStyle covers the whole plot, so its theme
## keys carry no pane index. See [TauStyle] for the details.
##
## Assign a new [Font] or [StyleBox] rather than mutating the one already
## assigned. An in-place change is not detected.
##
## Theme type variation: TauLegend
class_name TauLegendStyle extends TauStyle

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()` and `validate_resolved()`.
################################################################################################


## Font of the series names. Left at [code]null[/code], the series names are
## drawn in the font Godot uses by default.
@export var font: Font = null:
	set(value):
		font = value
		_mark(&"font")

## Size in pixels of the series names. The theme's default font size applies
## unless the theme sets [code]font_size[/code] on the [code]TauLegend[/code]
## type variation.
@export var font_size: int = 16:
	set(value):
		font_size = maxi(value, 1)
		_mark(&"font_size")

## Color of the series names.
@export var font_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		font_color = value
		_mark(&"font_color")

## Height in pixels of one legend key, the small picture standing for a
## series in one overlay. A key that asks for a wider box than it is tall
## keeps that proportion as this value changes.
@export var key_size_px: int = 12:
	set(value):
		key_size_px = maxi(value, 1)
		_mark(&"key_size_px")

## Gap in pixels between two keys of the same entry. A series drawn by
## several overlays gets one key per overlay, side by side.
@export var key_gap_px: int = 2:
	set(value):
		key_gap_px = maxi(value, 0)
		_mark(&"key_gap_px")

## Gap in pixels between the keys of an entry and its series name.
@export var key_label_gap_px: int = 6:
	set(value):
		key_label_gap_px = maxi(value, 0)
		_mark(&"key_label_gap_px")

## Gap in pixels between two legend entries, along the flow direction and
## between wrapped rows or columns alike.
@export var item_gap_px: int = 8:
	set(value):
		item_gap_px = maxi(value, 0)
		_mark(&"item_gap_px")

## StyleBox drawn behind the legend. Its content margins set the padding
## between the border and the entries.
##
## Left at [code]null[/code], the cascade supplies a transparent
## [StyleBoxFlat] with an 8 pixel content margin on all sides.
@export var background: StyleBox = null:
	set(value):
		background = value
		_mark(&"background")

## Distance in pixels between the legend and the edges of the data area.
## Only read for the [code]INSIDE_*[/code] positions of
## [member TauLegendConfig.position], where the legend floats over the data
## area.
@export var margin_px: int = 8:
	set(value):
		margin_px = maxi(value, 0)
		_mark(&"margin_px")

## Cap in pixels on the legend across its flow direction: the height of a
## legend flowing horizontally, the width of one flowing vertically. Entries
## past the cap are reachable by scrolling. [code]0[/code] applies no cap.
@export var max_size_px: int = 0:
	set(value):
		max_size_px = maxi(value, 0)
		_mark(&"max_size_px")


#region Internal, not public API, may change without notice.

# Loads properties from the Godot theme attached to p_control.
#
# TauLegendStyle is plot-wide, so there is no pane indexing. Values are
# written without consulting the override marks, because this runs on the
# resolved instance, not on the user-provided resource.
func load_from_theme(p_control: Control) -> void:
	if p_control == null:
		push_error("TauLegendStyle.load_from_theme(): control is null")
		return

	# Fonts and font sizes always resolve through the theme chain down to the
	# engine defaults, so neither needs a guard.
	font = p_control.get_theme_font(&"font")
	font_size = p_control.get_theme_font_size(&"font_size")
	if p_control.has_theme_color(&"font_color"):
		font_color = p_control.get_theme_color(&"font_color")

	if p_control.has_theme_constant(&"legend_key_size_px"):
		key_size_px = p_control.get_theme_constant(&"legend_key_size_px")
	if p_control.has_theme_constant(&"legend_key_gap_px"):
		key_gap_px = p_control.get_theme_constant(&"legend_key_gap_px")
	if p_control.has_theme_constant(&"legend_key_label_gap_px"):
		key_label_gap_px = p_control.get_theme_constant(&"legend_key_label_gap_px")

	if p_control.has_theme_constant(&"legend_item_gap_px"):
		item_gap_px = p_control.get_theme_constant(&"legend_item_gap_px")

	if p_control.has_theme_stylebox(&"legend_background"):
		background = p_control.get_theme_stylebox(&"legend_background")
	else:
		var default_background := StyleBoxFlat.new()
		default_background.bg_color = Color(0, 0, 0, 0)
		default_background.content_margin_left = 8
		default_background.content_margin_right = 8
		default_background.content_margin_top = 8
		default_background.content_margin_bottom = 8
		background = default_background

	if p_control.has_theme_constant(&"legend_margin_px"):
		margin_px = p_control.get_theme_constant(&"legend_margin_px")

	if p_control.has_theme_constant(&"legend_max_size_px"):
		max_size_px = p_control.get_theme_constant(&"legend_max_size_px")


# Applies overridden properties from p_user_style onto this resolved
# instance.
func apply_overrides_from(p_user_style: TauLegendStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.is_overridden(&"font"):
		font = p_user_style.font
	if p_user_style.is_overridden(&"font_size"):
		font_size = p_user_style.font_size
	if p_user_style.is_overridden(&"font_color"):
		font_color = p_user_style.font_color

	if p_user_style.is_overridden(&"key_size_px"):
		key_size_px = p_user_style.key_size_px
	if p_user_style.is_overridden(&"key_gap_px"):
		key_gap_px = p_user_style.key_gap_px
	if p_user_style.is_overridden(&"key_label_gap_px"):
		key_label_gap_px = p_user_style.key_label_gap_px

	if p_user_style.is_overridden(&"item_gap_px"):
		item_gap_px = p_user_style.item_gap_px

	if p_user_style.is_overridden(&"background"):
		background = p_user_style.background

	if p_user_style.is_overridden(&"margin_px"):
		margin_px = p_user_style.margin_px

	if p_user_style.is_overridden(&"max_size_px"):
		max_size_px = p_user_style.max_size_px


# Produces a fully resolved TauLegendStyle by applying all three cascade
# layers:
#   1. Start from defaults (a fresh TauLegendStyle instance).
#   2. Load theme values from the control.
#   3. Apply user overrides from p_user_style (may be null).
#   4. Report what the resolved combination cannot draw.
#
# The returned instance is a new TauLegendStyle owned by the caller. It is
# separate from p_user_style, which is never mutated.
static func resolve(p_control: Control, p_user_style: TauLegendStyle) -> TauLegendStyle:
	# Layer 1: defaults.
	var resolved := TauLegendStyle.new()
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


# Returns a copy of this resource carrying the property values and the
# override flags. The flags are copied explicitly because
# Resource.duplicate() only copies stored properties.
func make_snapshot() -> TauLegendStyle:
	var copy := duplicate() as TauLegendStyle
	copy._copy_overrides_from(self)
	return copy


func is_equal_to(p_other: TauStyle) -> bool:
	var other := p_other as TauLegendStyle
	if other == null:
		return false
	if not super.is_equal_to(other):
		return false
	if font != other.font:
		return false
	if font_size != other.font_size:
		return false
	if font_color != other.font_color:
		return false
	if key_size_px != other.key_size_px:
		return false
	if key_gap_px != other.key_gap_px:
		return false
	if key_label_gap_px != other.key_label_gap_px:
		return false
	if item_gap_px != other.item_gap_px:
		return false
	if background != other.background:
		return false
	if margin_px != other.margin_px:
		return false
	if max_size_px != other.max_size_px:
		return false
	return true


# All TauLegendStyle properties affect layout (key sizes, gaps, margins, font
# size all influence the legend's measured size and internal item
# arrangement).
func has_layout_affecting_change(p_other: TauLegendStyle) -> bool:
	if p_other == null:
		return true
	# Every property except font_color affects layout.
	if font != p_other.font:
		return true
	if font_size != p_other.font_size:
		return true
	if key_size_px != p_other.key_size_px:
		return true
	if key_gap_px != p_other.key_gap_px:
		return true
	if key_label_gap_px != p_other.key_label_gap_px:
		return true
	if item_gap_px != p_other.item_gap_px:
		return true
	if background != p_other.background:
		return true
	if margin_px != p_other.margin_px:
		return true
	if max_size_px != p_other.max_size_px:
		return true
	return false


# Returns the font the series names are drawn with, never null.
func get_font() -> Font:
	if font == null:
		return ThemeDB.fallback_font
	return font

#endregion
