## Visual style for the legend.
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
## different value (e.g. 15 instead of 14).
class_name TauLegendStyle extends Resource

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()`.
################################################################################################


const DEFAULT_FONT: Font = null
@export var font: Font = DEFAULT_FONT

const DEFAULT_FONT_SIZE: int = 14
@export var font_size: int = DEFAULT_FONT_SIZE

const DEFAULT_FONT_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var font_color: Color = DEFAULT_FONT_COLOR

const DEFAULT_KEY_SIZE_PX: int = 12
@export var key_size_px: int = DEFAULT_KEY_SIZE_PX

const DEFAULT_KEY_GAP_PX: int = 2
@export var key_gap_px: int = DEFAULT_KEY_GAP_PX

const DEFAULT_KEY_LABEL_GAP_PX: int = 6
@export var key_label_gap_px: int = DEFAULT_KEY_LABEL_GAP_PX

const DEFAULT_ITEM_GAP_PX: int = 8
@export var item_gap_px: int = DEFAULT_ITEM_GAP_PX

const DEFAULT_BACKGROUND: StyleBox = null
@export var background: StyleBox = DEFAULT_BACKGROUND

const DEFAULT_MARGIN_PX: int = 8
@export var margin_px: int = DEFAULT_MARGIN_PX

const DEFAULT_MAX_SIZE_PX: int = 0  # 0 means no constraint
@export var max_size_px: int = DEFAULT_MAX_SIZE_PX


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
## instance. A property is considered overridden when its value on the user
## resource differs from the matching DEFAULT_* constant.
func apply_overrides_from(p_user_style: TauLegendStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.font != DEFAULT_FONT:
		font = p_user_style.font
	if p_user_style.font_size != DEFAULT_FONT_SIZE:
		font_size = p_user_style.font_size
	if p_user_style.font_color != DEFAULT_FONT_COLOR:
		font_color = p_user_style.font_color

	if p_user_style.key_size_px != DEFAULT_KEY_SIZE_PX:
		key_size_px = p_user_style.key_size_px
	if p_user_style.key_gap_px != DEFAULT_KEY_GAP_PX:
		key_gap_px = p_user_style.key_gap_px
	if p_user_style.key_label_gap_px != DEFAULT_KEY_LABEL_GAP_PX:
		key_label_gap_px = p_user_style.key_label_gap_px

	if p_user_style.item_gap_px != DEFAULT_ITEM_GAP_PX:
		item_gap_px = p_user_style.item_gap_px

	if p_user_style.background != DEFAULT_BACKGROUND:
		background = p_user_style.background

	if p_user_style.margin_px != DEFAULT_MARGIN_PX:
		margin_px = p_user_style.margin_px

	if p_user_style.max_size_px != DEFAULT_MAX_SIZE_PX:
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

func is_equal_to(p_other: TauLegendStyle) -> bool:
	if p_other == null:
		return false
	if font != p_other.font:
		return false
	if font_size != p_other.font_size:
		return false
	if font_color != p_other.font_color:
		return false
	if key_size_px != p_other.key_size_px:
		return false
	if key_gap_px != p_other.key_gap_px:
		return false
	if key_label_gap_px != p_other.key_label_gap_px:
		return false
	if item_gap_px != p_other.item_gap_px:
		return false
	if background != p_other.background:
		return false
	if margin_px != p_other.margin_px:
		return false
	if max_size_px != p_other.max_size_px:
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
