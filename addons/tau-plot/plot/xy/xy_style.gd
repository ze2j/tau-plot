## Contains theme-driven visual and spacing parameters for the XY plot.
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
## different value (e.g. 17 instead of 16).
class_name TauXYStyle extends Resource

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()`.
################################################################################################

const DEFAULT_AXIS_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var axis_color: Color = DEFAULT_AXIS_COLOR

const DEFAULT_LABEL_FONT: Font = null
@export var label_font: Font = DEFAULT_LABEL_FONT

const DEFAULT_LABEL_FONT_SIZE: int = 16
@export var label_font_size: int = DEFAULT_LABEL_FONT_SIZE

const DEFAULT_LABEL_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var label_color: Color = DEFAULT_LABEL_COLOR

## Tick mark dimensions for the x axis and y axis respectively.
## "x" and "y" refer to the logical axis, not screen direction. These values
## are orientation-independent: they work the same regardless of whether the
## axis is placed on a horizontal or vertical edge.
## - length: how far the tick protrudes from the axis line (perpendicular to it).
## - thickness: stroke width of the tick mark (passed to draw_line).
const DEFAULT_X_MAJOR_TICK_LENGTH_PX: int = 4
@export var x_major_tick_length_px: int = DEFAULT_X_MAJOR_TICK_LENGTH_PX

const DEFAULT_X_MAJOR_TICK_THICKNESS_PX: int = 1
@export var x_major_tick_thickness_px: int = DEFAULT_X_MAJOR_TICK_THICKNESS_PX

const DEFAULT_Y_MAJOR_TICK_LENGTH_PX: int = 4
@export var y_major_tick_length_px: int = DEFAULT_Y_MAJOR_TICK_LENGTH_PX

const DEFAULT_Y_MAJOR_TICK_THICKNESS_PX: int = 1
@export var y_major_tick_thickness_px: int = DEFAULT_Y_MAJOR_TICK_THICKNESS_PX

## Minor tick dimensions. The length is derived from the major tick length by
## multiplying it with minor_tick_length_ratio (shared across both axes).
## Thickness is independent per axis.
const DEFAULT_MINOR_TICK_LENGTH_RATIO: float = 0.5
@export var minor_tick_length_ratio: float = DEFAULT_MINOR_TICK_LENGTH_RATIO

const DEFAULT_X_MINOR_TICK_THICKNESS_PX: int = 1
@export var x_minor_tick_thickness_px: int = DEFAULT_X_MINOR_TICK_THICKNESS_PX

const DEFAULT_Y_MINOR_TICK_THICKNESS_PX: int = 1
@export var y_minor_tick_thickness_px: int = DEFAULT_Y_MINOR_TICK_THICKNESS_PX

const DEFAULT_X_TICK_X_LABEL_GAP_PX: int = 4
@export var x_tick_x_label_gap_px: int = DEFAULT_X_TICK_X_LABEL_GAP_PX

const DEFAULT_Y_TICK_Y_LABEL_GAP_PX: int = 4
@export var y_tick_y_label_gap_px: int = DEFAULT_Y_TICK_Y_LABEL_GAP_PX

const DEFAULT_PADDING_LEFT_PX: int = 4
@export var padding_left_px: int = DEFAULT_PADDING_LEFT_PX

const DEFAULT_PADDING_RIGHT_PX: int = 4
@export var padding_right_px: int = DEFAULT_PADDING_RIGHT_PX

const DEFAULT_PADDING_TOP_PX: int = 4
@export var padding_top_px: int = DEFAULT_PADDING_TOP_PX

const DEFAULT_PADDING_BOTTOM_PX: int = 4
@export var padding_bottom_px: int = DEFAULT_PADDING_BOTTOM_PX

const DEFAULT_PANE_GAP_PX: int = 4
@export var pane_gap_px: int = DEFAULT_PANE_GAP_PX

## Plot-wide series color palette.
const DEFAULT_SERIES_COLORS: Array[Color] = [
	Color(0.306, 0.475, 0.655),
	Color(0.882, 0.341, 0.349),
	Color(0.349, 0.631, 0.31),
	Color(0.949, 0.557, 0.169),
	Color(0.729, 0.69, 0.675),
	Color(0.5, 0.416, 0.955),
	Color(0.612, 0.459, 0.373),
	Color(0.929, 0.888, 0.282),
]
@export var series_colors: Array[Color] = [
	Color(0.306, 0.475, 0.655),
	Color(0.882, 0.341, 0.349),
	Color(0.349, 0.631, 0.31),
	Color(0.949, 0.557, 0.169),
	Color(0.729, 0.69, 0.675),
	Color(0.5, 0.416, 0.955),
	Color(0.612, 0.459, 0.373),
	Color(0.929, 0.888, 0.282),
]

## Plot-wide series alpha (0.0-1.0).
const DEFAULT_SERIES_ALPHA: float = 1.0
@export var series_alpha: float = DEFAULT_SERIES_ALPHA


####################################################################################################
# Cascade: theme loading (layer 2)
####################################################################################################

## Loads properties from the Godot theme attached to [param p_control].
##
## TauXYStyle is plot-wide, so there is no pane indexing. This method writes every
## property unconditionally because it is called on the resolved instance, not
## on the user-provided resource.
func load_from_theme(p_control: Control) -> void:
	if p_control == null:
		push_error("TauXYStyle.load_from_theme(): control is null")
		return

	if p_control.has_theme_color(&"xy_axis_color"):
		axis_color = p_control.get_theme_color(&"xy_axis_color")

	if p_control.has_theme_font(&"font"):
		label_font = p_control.get_theme_font(&"font")
	if p_control.has_theme_font_size(&"font_size"):
		label_font_size = p_control.get_theme_font_size(&"font_size")
	if p_control.has_theme_color(&"font_color"):
		label_color = p_control.get_theme_color(&"font_color")

	if p_control.has_theme_constant(&"xy_padding_bottom"):
		padding_bottom_px = p_control.get_theme_constant(&"xy_padding_bottom")
	if p_control.has_theme_constant(&"xy_padding_left"):
		padding_left_px = p_control.get_theme_constant(&"xy_padding_left")
	if p_control.has_theme_constant(&"xy_padding_right"):
		padding_right_px = p_control.get_theme_constant(&"xy_padding_right")
	if p_control.has_theme_constant(&"xy_padding_top"):
		padding_top_px = p_control.get_theme_constant(&"xy_padding_top")

	if p_control.has_theme_constant(&"xy_pane_gap"):
		pane_gap_px = p_control.get_theme_constant(&"xy_pane_gap")

	if p_control.has_theme_constant(&"xy_x_tick_x_label_gap"):
		x_tick_x_label_gap_px = p_control.get_theme_constant(&"xy_x_tick_x_label_gap")
	if p_control.has_theme_constant(&"xy_y_tick_y_label_gap"):
		y_tick_y_label_gap_px = p_control.get_theme_constant(&"xy_y_tick_y_label_gap")

	if p_control.has_theme_constant(&"xy_x_major_tick_length"):
		x_major_tick_length_px = p_control.get_theme_constant(&"xy_x_major_tick_length")
	if p_control.has_theme_constant(&"xy_x_major_tick_thickness"):
		x_major_tick_thickness_px = p_control.get_theme_constant(&"xy_x_major_tick_thickness")

	if p_control.has_theme_constant(&"xy_y_major_tick_length"):
		y_major_tick_length_px = p_control.get_theme_constant(&"xy_y_major_tick_length")
	if p_control.has_theme_constant(&"xy_y_major_tick_thickness"):
		y_major_tick_thickness_px = p_control.get_theme_constant(&"xy_y_major_tick_thickness")

	# Minor tick theme constants. The ratio is stored as a percentage (integer)
	# because Godot theme constants only support integers.
	if p_control.has_theme_constant(&"xy_minor_tick_length_ratio_percent"):
		var ratio_percent := p_control.get_theme_constant(&"xy_minor_tick_length_ratio_percent")
		minor_tick_length_ratio = clampf(float(ratio_percent) / 100.0, 0.0, 1.0)
	if p_control.has_theme_constant(&"xy_x_minor_tick_thickness"):
		x_minor_tick_thickness_px = p_control.get_theme_constant(&"xy_x_minor_tick_thickness")
	if p_control.has_theme_constant(&"xy_y_minor_tick_thickness"):
		y_minor_tick_thickness_px = p_control.get_theme_constant(&"xy_y_minor_tick_thickness")

	# Series colors: unlimited number, keyed series_color_0, series_color_1, ...
	var theme_series_colors: Array[Color]
	var color_index := 0
	while true:
		var key := "series_color_%d" % color_index
		if not p_control.has_theme_color(key):
			break
		theme_series_colors.append(p_control.get_theme_color(key))
		color_index += 1
	if not theme_series_colors.is_empty():
		series_colors.resize(max(series_colors.size(), theme_series_colors.size()))
		for i in range(theme_series_colors.size()):
			series_colors[i] = theme_series_colors[i]

	# Series alpha is stored as a percentage in theme resources (only integers are supported).
	if p_control.has_theme_constant(&"series_alpha_percent"):
		var alpha_percent := p_control.get_theme_constant(&"series_alpha_percent")
		series_alpha = clampf(float(alpha_percent) / 100.0, 0.0, 1.0)


####################################################################################################
# Cascade: user overrides (layer 3)
####################################################################################################

## Applies overridden properties from [param p_user_style] onto this resolved
## instance. A property is considered overridden when its value on the user
## resource differs from the matching DEFAULT_* constant.
func apply_overrides_from(p_user_style: TauXYStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.axis_color != DEFAULT_AXIS_COLOR:
		axis_color = p_user_style.axis_color

	if p_user_style.label_font != DEFAULT_LABEL_FONT:
		label_font = p_user_style.label_font
	if p_user_style.label_font_size != DEFAULT_LABEL_FONT_SIZE:
		label_font_size = p_user_style.label_font_size
	if p_user_style.label_color != DEFAULT_LABEL_COLOR:
		label_color = p_user_style.label_color

	if p_user_style.x_major_tick_length_px != DEFAULT_X_MAJOR_TICK_LENGTH_PX:
		x_major_tick_length_px = p_user_style.x_major_tick_length_px
	if p_user_style.x_major_tick_thickness_px != DEFAULT_X_MAJOR_TICK_THICKNESS_PX:
		x_major_tick_thickness_px = p_user_style.x_major_tick_thickness_px
	if p_user_style.y_major_tick_length_px != DEFAULT_Y_MAJOR_TICK_LENGTH_PX:
		y_major_tick_length_px = p_user_style.y_major_tick_length_px
	if p_user_style.y_major_tick_thickness_px != DEFAULT_Y_MAJOR_TICK_THICKNESS_PX:
		y_major_tick_thickness_px = p_user_style.y_major_tick_thickness_px

	if p_user_style.minor_tick_length_ratio != DEFAULT_MINOR_TICK_LENGTH_RATIO:
		minor_tick_length_ratio = p_user_style.minor_tick_length_ratio
	if p_user_style.x_minor_tick_thickness_px != DEFAULT_X_MINOR_TICK_THICKNESS_PX:
		x_minor_tick_thickness_px = p_user_style.x_minor_tick_thickness_px
	if p_user_style.y_minor_tick_thickness_px != DEFAULT_Y_MINOR_TICK_THICKNESS_PX:
		y_minor_tick_thickness_px = p_user_style.y_minor_tick_thickness_px

	if p_user_style.x_tick_x_label_gap_px != DEFAULT_X_TICK_X_LABEL_GAP_PX:
		x_tick_x_label_gap_px = p_user_style.x_tick_x_label_gap_px
	if p_user_style.y_tick_y_label_gap_px != DEFAULT_Y_TICK_Y_LABEL_GAP_PX:
		y_tick_y_label_gap_px = p_user_style.y_tick_y_label_gap_px

	if p_user_style.padding_left_px != DEFAULT_PADDING_LEFT_PX:
		padding_left_px = p_user_style.padding_left_px
	if p_user_style.padding_right_px != DEFAULT_PADDING_RIGHT_PX:
		padding_right_px = p_user_style.padding_right_px
	if p_user_style.padding_top_px != DEFAULT_PADDING_TOP_PX:
		padding_top_px = p_user_style.padding_top_px
	if p_user_style.padding_bottom_px != DEFAULT_PADDING_BOTTOM_PX:
		padding_bottom_px = p_user_style.padding_bottom_px

	if p_user_style.pane_gap_px != DEFAULT_PANE_GAP_PX:
		pane_gap_px = p_user_style.pane_gap_px

	if p_user_style.series_alpha != DEFAULT_SERIES_ALPHA:
		series_alpha = p_user_style.series_alpha

	# Array comparison: use size + element loop (safest).
	var colors_overridden := false
	if p_user_style.series_colors.size() != DEFAULT_SERIES_COLORS.size():
		colors_overridden = true
	else:
		for i in range(p_user_style.series_colors.size()):
			if p_user_style.series_colors[i] != DEFAULT_SERIES_COLORS[i]:
				colors_overridden = true
				break
	if colors_overridden:
		series_colors = p_user_style.series_colors.duplicate()


####################################################################################################
# Full cascade resolution
####################################################################################################

## Produces a fully resolved TauXYStyle by applying all three cascade layers:
##   1. Start from defaults (a fresh TauXYStyle instance).
##   2. Load theme values (TauXYStyle is plot-wide, no pane indexing).
##   3. Apply user overrides from [param p_user_style] (may be null).
##
## The returned instance is a new TauXYStyle owned by the caller. It is separate
## from [param p_user_style] which is never mutated.
static func resolve(
	p_control: Control,
	p_user_style: TauXYStyle
) -> TauXYStyle:
	# Layer 1: defaults.
	var resolved := TauXYStyle.new()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	return resolved


####################################################################################################
# Change detection
####################################################################################################

func is_equal_to(p_other: TauXYStyle) -> bool:
	if p_other == null:
		return false
	if axis_color != p_other.axis_color:
		return false
	if label_font != p_other.label_font:
		return false
	if label_font_size != p_other.label_font_size:
		return false
	if label_color != p_other.label_color:
		return false
	if x_major_tick_length_px != p_other.x_major_tick_length_px:
		return false
	if x_major_tick_thickness_px != p_other.x_major_tick_thickness_px:
		return false
	if y_major_tick_length_px != p_other.y_major_tick_length_px:
		return false
	if y_major_tick_thickness_px != p_other.y_major_tick_thickness_px:
		return false
	if minor_tick_length_ratio != p_other.minor_tick_length_ratio:
		return false
	if x_minor_tick_thickness_px != p_other.x_minor_tick_thickness_px:
		return false
	if y_minor_tick_thickness_px != p_other.y_minor_tick_thickness_px:
		return false
	if x_tick_x_label_gap_px != p_other.x_tick_x_label_gap_px:
		return false
	if y_tick_y_label_gap_px != p_other.y_tick_y_label_gap_px:
		return false
	if padding_left_px != p_other.padding_left_px:
		return false
	if padding_right_px != p_other.padding_right_px:
		return false
	if padding_top_px != p_other.padding_top_px:
		return false
	if padding_bottom_px != p_other.padding_bottom_px:
		return false
	if pane_gap_px != p_other.pane_gap_px:
		return false
	if series_alpha != p_other.series_alpha:
		return false
	if series_colors.size() != p_other.series_colors.size():
		return false
	for i in range(series_colors.size()):
		if series_colors[i] != p_other.series_colors[i]:
			return false
	return true


# Layout-affecting: label_font, label_font_size, tick sizes, tick-label gaps,
# all four paddings, pane_gap_px. These feed into XYLayout.update() which
# computes pane rects and tick positions.
# Visual-only: axis_color, series_colors, series_alpha.
func has_layout_affecting_change(p_other: TauXYStyle) -> bool:
	if p_other == null:
		return true
	if label_font != p_other.label_font:
		return true
	if label_font_size != p_other.label_font_size:
		return true
	if x_major_tick_length_px != p_other.x_major_tick_length_px:
		return true
	if x_major_tick_thickness_px != p_other.x_major_tick_thickness_px:
		return true
	if y_major_tick_length_px != p_other.y_major_tick_length_px:
		return true
	if y_major_tick_thickness_px != p_other.y_major_tick_thickness_px:
		return true
	if x_tick_x_label_gap_px != p_other.x_tick_x_label_gap_px:
		return true
	if y_tick_y_label_gap_px != p_other.y_tick_y_label_gap_px:
		return true
	if padding_left_px != p_other.padding_left_px:
		return true
	if padding_right_px != p_other.padding_right_px:
		return true
	if padding_top_px != p_other.padding_top_px:
		return true
	if padding_bottom_px != p_other.padding_bottom_px:
		return true
	if pane_gap_px != p_other.pane_gap_px:
		return true
	return false


####################################################################################################
# Helpers
####################################################################################################

func get_series_color(p_series_index: int) -> Color:
	if p_series_index < 0 or p_series_index >= series_colors.size():
		push_error("TauXYStyle.get_series_color(): out of range series index: %d not in [0, %d]" % [p_series_index, series_colors.size()])
		return Color()
	return series_colors[p_series_index]
