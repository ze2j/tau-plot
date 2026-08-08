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
#          `has_layout_affecting_change()`.
################################################################################################


@export var font: Font = null:
	set(value):
		font = value
		_overridden[&"font"] = true

@export var font_size: int = 14:
	set(value):
		font_size = value
		_overridden[&"font_size"] = true

@export var font_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		font_color = value
		_overridden[&"font_color"] = true

@export var key_size_px: int = 12:
	set(value):
		key_size_px = value
		_overridden[&"key_size_px"] = true

@export var key_gap_px: int = 2:
	set(value):
		key_gap_px = value
		_overridden[&"key_gap_px"] = true

@export var key_label_gap_px: int = 6:
	set(value):
		key_label_gap_px = value
		_overridden[&"key_label_gap_px"] = true

@export var item_gap_px: int = 8:
	set(value):
		item_gap_px = value
		_overridden[&"item_gap_px"] = true

@export var background: StyleBox = null:
	set(value):
		background = value
		_overridden[&"background"] = true

@export var margin_px: int = 8:
	set(value):
		margin_px = value
		_overridden[&"margin_px"] = true

@export var max_size_px: int = 0:  # 0 means no constraint
	set(value):
		max_size_px = value
		_overridden[&"max_size_px"] = true


####################################################################################################
# Cascade: theme loading (layer 2)
####################################################################################################

## Loads properties from the Godot theme attached to [param p_control].
##
## TauLegendStyle is plot-wide, so there is no pane indexing. This method writes
## every property unconditionally because it is called on the resolved instance,
## not on the user-provided resource.
func load_from_theme(p_control: Control) -> void:
	if p_control == null:
		push_error("TauLegendStyle.load_from_theme(): control is null")
		return

	if p_control.has_theme_font(&"font"):
		font = p_control.get_theme_font(&"font")
	if p_control.has_theme_font_size(&"font_size"):
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


####################################################################################################
# Cascade: user overrides (layer 3)
####################################################################################################

## Applies overridden properties from [param p_user_style] onto this resolved
## instance.
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


####################################################################################################
# Full cascade resolution
####################################################################################################

## Produces a fully resolved TauLegendStyle by applying all three cascade layers:
##   1. Start from defaults (a fresh TauLegendStyle instance).
##   2. Load theme values from the control.
##   3. Apply user overrides from [param p_user_style] (may be null).
##
## The returned instance is a new TauLegendStyle owned by the caller. It is separate
## from [param p_user_style] which is never mutated.
static func resolve(
	p_control: Control,
	p_user_style: TauLegendStyle
) -> TauLegendStyle:
	# Layer 1: defaults.
	var resolved := TauLegendStyle.new()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	return resolved


####################################################################################################
# Change detection
####################################################################################################

## Returns a copy of this resource carrying the property values and the
## override flags. The flags are copied explicitly because
## [method Resource.duplicate] only copies stored properties.
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


## All TauLegendStyle properties affect layout (key sizes, gaps, margins, font
## size all influence the legend's measured size and internal item arrangement).
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
