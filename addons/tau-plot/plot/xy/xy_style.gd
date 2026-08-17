@tool

## Contains theme-driven visual and spacing parameters for the XY plot.
##
## Properties are resolved from the built-in defaults, the theme, and the values
## set here, in that order. The per-series arrays are read as cycles. TauXYStyle
## covers the whole plot, so its theme keys carry no pane index. See [TauStyle]
## for the details.
##
## Assign a new [Font] rather than mutating the one already assigned. An
## in-place change is not detected.
##
## Theme type variation: TauPlot
class_name TauXYStyle extends TauStyle

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()` and `validate_resolved()`.
################################################################################################

## Color of the axis lines and of the tick marks on every axis.
@export var axis_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		axis_color = value
		_mark(&"axis_color")

## Font of the tick labels. Left at [code]null[/code], the tick labels are
## drawn in the font Godot uses by default.
@export var label_font: Font = null:
	set(value):
		label_font = value
		_mark(&"label_font")

## Size in pixels of the tick labels. The theme's default font size applies
## unless the theme sets [code]font_size[/code] on the [code]TauPlot[/code]
## type variation.
@export var label_font_size: int = 16:
	set(value):
		label_font_size = maxi(value, 1)
		_mark(&"label_font_size")

## Color of the tick labels.
@export var label_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		label_color = value
		_mark(&"label_color")

## How far a major tick on the x axis protrudes from the axis line, in
## pixels, measured perpendicular to that line.
##
## [code]x[/code] names the logical axis, not a screen direction, so this
## reads the same whether the x axis sits on a horizontal or a vertical edge.
@export var x_major_tick_length_px: int = 4:
	set(value):
		x_major_tick_length_px = maxi(value, 0)
		_mark(&"x_major_tick_length_px")

## Stroke width in pixels of a major tick on the x axis.
@export var x_major_tick_thickness_px: int = 1:
	set(value):
		x_major_tick_thickness_px = maxi(value, 0)
		_mark(&"x_major_tick_thickness_px")

## How far a major tick on a y axis protrudes from the axis line, in pixels,
## measured perpendicular to that line. Applies to every y axis of every pane.
@export var y_major_tick_length_px: int = 4:
	set(value):
		y_major_tick_length_px = maxi(value, 0)
		_mark(&"y_major_tick_length_px")

## Stroke width in pixels of a major tick on a y axis.
@export var y_major_tick_thickness_px: int = 1:
	set(value):
		y_major_tick_thickness_px = maxi(value, 0)
		_mark(&"y_major_tick_thickness_px")

## Length of a minor tick as a fraction of the major tick length of the same
## axis. Shared by both axes. Valid range is [code][0.0, 1.0][/code], and
## values outside it are clamped.
@export var minor_tick_length_ratio: float = 0.5:
	set(value):
		minor_tick_length_ratio = clampf(value, 0.0, 1.0)
		_mark(&"minor_tick_length_ratio")

## Stroke width in pixels of a minor tick on the x axis.
@export var x_minor_tick_thickness_px: int = 1:
	set(value):
		x_minor_tick_thickness_px = maxi(value, 0)
		_mark(&"x_minor_tick_thickness_px")

## Stroke width in pixels of a minor tick on a y axis.
@export var y_minor_tick_thickness_px: int = 1:
	set(value):
		y_minor_tick_thickness_px = maxi(value, 0)
		_mark(&"y_minor_tick_thickness_px")

## Gap in pixels between the x axis tick marks and the x tick labels.
@export var x_tick_x_label_gap_px: int = 4:
	set(value):
		x_tick_x_label_gap_px = maxi(value, 0)
		_mark(&"x_tick_x_label_gap_px")

## Gap in pixels between the y axis tick marks and the y tick labels.
@export var y_tick_y_label_gap_px: int = 4:
	set(value):
		y_tick_y_label_gap_px = maxi(value, 0)
		_mark(&"y_tick_y_label_gap_px")

## Padding in pixels between the left edge of the plot control and the panes,
## outside the space the axes reserve for their ticks and labels.
@export var padding_left_px: int = 4:
	set(value):
		padding_left_px = maxi(value, 0)
		_mark(&"padding_left_px")

## Padding in pixels between the right edge of the plot control and the panes,
## outside the space the axes reserve for their ticks and labels.
@export var padding_right_px: int = 4:
	set(value):
		padding_right_px = maxi(value, 0)
		_mark(&"padding_right_px")

## Padding in pixels between the top edge of the plot control and the panes,
## outside the space the axes reserve for their ticks and labels.
@export var padding_top_px: int = 4:
	set(value):
		padding_top_px = maxi(value, 0)
		_mark(&"padding_top_px")

## Padding in pixels between the bottom edge of the plot control and the panes,
## outside the space the axes reserve for their ticks and labels.
@export var padding_bottom_px: int = 4:
	set(value):
		padding_bottom_px = maxi(value, 0)
		_mark(&"padding_bottom_px")

## Gap in pixels between two neighbouring panes, and between the axis titles
## that belong to them.
@export var pane_gap_px: int = 4:
	set(value):
		pane_gap_px = maxi(value, 0)
		_mark(&"pane_gap_px")

## Color applied when [member series_colors] is empty.
const DEFAULT_SERIES_COLOR := Color(0.306, 0.475, 0.655)

## Per-series cycle of series colors. See [TauStyle] for how a cycle is
## indexed. An empty array is treated as all series drawn in
## [constant DEFAULT_SERIES_COLOR].
@export var series_colors: Array[Color] = [
	DEFAULT_SERIES_COLOR,
	Color(0.882, 0.341, 0.349),
	Color(0.349, 0.631, 0.31),
	Color(0.949, 0.557, 0.169),
	Color(0.729, 0.69, 0.675),
	Color(0.5, 0.416, 0.955),
	Color(0.612, 0.459, 0.373),
	Color(0.929, 0.888, 0.282),
]:
	set(value):
		series_colors = value.duplicate()
		_mark(&"series_colors")

## Opacity applied when [member series_alphas] is empty.
const DEFAULT_SERIES_ALPHA := 1.0

## Per-series cycle of series opacities, from [code]0.0[/code] to
## [code]1.0[/code]. See [TauStyle] for how a cycle is indexed. An empty array
## is treated as all series fully opaque.
@export var series_alphas: Array[float] = [DEFAULT_SERIES_ALPHA]:
	set(value):
		series_alphas = _clamped_floats(value, 0.0, 1.0)
		_mark(&"series_alphas")


#region Internal, not public API, may change without notice.

# Loads properties from the Godot theme attached to p_control.
#
# TauXYStyle is plot-wide, so there is no pane indexing. Values are written
# without consulting the override marks, because this runs on the resolved
# instance, not on the user-provided resource.
func load_from_theme(p_control: Control) -> void:
	if p_control == null:
		push_error("TauXYStyle.load_from_theme(): control is null")
		return

	if p_control.has_theme_color(&"xy_axis_color"):
		axis_color = p_control.get_theme_color(&"xy_axis_color")

	# Fonts and font sizes always resolve through the theme chain down to the
	# engine defaults, so neither needs a guard.
	label_font = p_control.get_theme_font(&"font")
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
		minor_tick_length_ratio = float(ratio_percent) / 100.0
	if p_control.has_theme_constant(&"xy_x_minor_tick_thickness"):
		x_minor_tick_thickness_px = p_control.get_theme_constant(&"xy_x_minor_tick_thickness")
	if p_control.has_theme_constant(&"xy_y_minor_tick_thickness"):
		y_minor_tick_thickness_px = p_control.get_theme_constant(&"xy_y_minor_tick_thickness")

	# A themed run replaces the whole cycle rather than patching over the
	# built-in one, so the resolved cycle is exactly what the theme defines and
	# no built-in entry trails it. Both scans stop at the first missing index,
	# so indices must be contiguous from 0.

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
		series_colors = theme_series_colors

	# Series alphas: unlimited number, keyed series_alpha_percent_0, series_alpha_percent_1, ...
	# Stored as percentages because theme constants only support integers.
	var theme_series_alphas: Array[float]
	var alpha_index := 0
	while true:
		var key := "series_alpha_percent_%d" % alpha_index
		if not p_control.has_theme_constant(key):
			break
		theme_series_alphas.append(float(p_control.get_theme_constant(key)) / 100.0)
		alpha_index += 1
	if not theme_series_alphas.is_empty():
		series_alphas = theme_series_alphas


# Applies overridden properties from p_user_style onto this resolved
# instance.
func apply_overrides_from(p_user_style: TauXYStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.is_overridden(&"axis_color"):
		axis_color = p_user_style.axis_color

	if p_user_style.is_overridden(&"label_font"):
		label_font = p_user_style.label_font
	if p_user_style.is_overridden(&"label_font_size"):
		label_font_size = p_user_style.label_font_size
	if p_user_style.is_overridden(&"label_color"):
		label_color = p_user_style.label_color

	if p_user_style.is_overridden(&"x_major_tick_length_px"):
		x_major_tick_length_px = p_user_style.x_major_tick_length_px
	if p_user_style.is_overridden(&"x_major_tick_thickness_px"):
		x_major_tick_thickness_px = p_user_style.x_major_tick_thickness_px
	if p_user_style.is_overridden(&"y_major_tick_length_px"):
		y_major_tick_length_px = p_user_style.y_major_tick_length_px
	if p_user_style.is_overridden(&"y_major_tick_thickness_px"):
		y_major_tick_thickness_px = p_user_style.y_major_tick_thickness_px

	if p_user_style.is_overridden(&"minor_tick_length_ratio"):
		minor_tick_length_ratio = p_user_style.minor_tick_length_ratio
	if p_user_style.is_overridden(&"x_minor_tick_thickness_px"):
		x_minor_tick_thickness_px = p_user_style.x_minor_tick_thickness_px
	if p_user_style.is_overridden(&"y_minor_tick_thickness_px"):
		y_minor_tick_thickness_px = p_user_style.y_minor_tick_thickness_px

	if p_user_style.is_overridden(&"x_tick_x_label_gap_px"):
		x_tick_x_label_gap_px = p_user_style.x_tick_x_label_gap_px
	if p_user_style.is_overridden(&"y_tick_y_label_gap_px"):
		y_tick_y_label_gap_px = p_user_style.y_tick_y_label_gap_px

	if p_user_style.is_overridden(&"padding_left_px"):
		padding_left_px = p_user_style.padding_left_px
	if p_user_style.is_overridden(&"padding_right_px"):
		padding_right_px = p_user_style.padding_right_px
	if p_user_style.is_overridden(&"padding_top_px"):
		padding_top_px = p_user_style.padding_top_px
	if p_user_style.is_overridden(&"padding_bottom_px"):
		padding_bottom_px = p_user_style.padding_bottom_px

	if p_user_style.is_overridden(&"pane_gap_px"):
		pane_gap_px = p_user_style.pane_gap_px

	if p_user_style.is_overridden(&"series_alphas"):
		series_alphas = p_user_style.series_alphas

	if p_user_style.is_overridden(&"series_colors"):
		series_colors = p_user_style.series_colors


# Produces a fully resolved TauXYStyle by applying all three cascade layers:
#   1. Start from defaults (a fresh TauXYStyle instance).
#   2. Load theme values (TauXYStyle is plot-wide, no pane indexing).
#   3. Apply user overrides from p_user_style (may be null).
#   4. Report what the resolved combination cannot draw.
#
# The returned instance is a new TauXYStyle owned by the caller. It is
# separate from p_user_style, which is never mutated.
static func resolve(p_control: Control, p_user_style: TauXYStyle) -> TauXYStyle:
	# Layer 1: defaults.
	var resolved := TauXYStyle.new()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	# Layer 4: report what the resolved combination cannot draw.
	resolved.validate_resolved()
	return resolved


# Reports the resolved property combinations that cannot be drawn as
# configured. An empty cycle is legal, but it is also the one way every series
# ends up sharing a color with no way to tell them apart.
func validate_resolved() -> void:
	if series_colors.is_empty():
		push_warning("TauXYStyle: series_colors is empty, every series is drawn in DEFAULT_SERIES_COLOR")


# Returns a copy of this resource carrying the property values and the
# override flags. The flags are copied explicitly because
# Resource.duplicate() only copies stored properties.
func make_snapshot() -> TauXYStyle:
	var copy := duplicate() as TauXYStyle
	copy._copy_overrides_from(self)
	return copy


func is_equal_to(p_other: TauStyle) -> bool:
	var other := p_other as TauXYStyle
	if other == null:
		return false
	if not super.is_equal_to(other):
		return false
	if axis_color != other.axis_color:
		return false
	if label_font != other.label_font:
		return false
	if label_font_size != other.label_font_size:
		return false
	if label_color != other.label_color:
		return false
	if x_major_tick_length_px != other.x_major_tick_length_px:
		return false
	if x_major_tick_thickness_px != other.x_major_tick_thickness_px:
		return false
	if y_major_tick_length_px != other.y_major_tick_length_px:
		return false
	if y_major_tick_thickness_px != other.y_major_tick_thickness_px:
		return false
	if minor_tick_length_ratio != other.minor_tick_length_ratio:
		return false
	if x_minor_tick_thickness_px != other.x_minor_tick_thickness_px:
		return false
	if y_minor_tick_thickness_px != other.y_minor_tick_thickness_px:
		return false
	if x_tick_x_label_gap_px != other.x_tick_x_label_gap_px:
		return false
	if y_tick_y_label_gap_px != other.y_tick_y_label_gap_px:
		return false
	if padding_left_px != other.padding_left_px:
		return false
	if padding_right_px != other.padding_right_px:
		return false
	if padding_top_px != other.padding_top_px:
		return false
	if padding_bottom_px != other.padding_bottom_px:
		return false
	if pane_gap_px != other.pane_gap_px:
		return false
	if series_alphas != other.series_alphas:
		return false
	if series_colors != other.series_colors:
		return false
	return true


# Layout-affecting: label_font, label_font_size, tick sizes, tick-label gaps,
# all four paddings, pane_gap_px. These feed into XYLayout.update() which
# computes pane rects and tick positions.
# Visual-only: axis_color, series_colors, series_alphas.
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


# Returns the font the tick labels are drawn with, never null.
func get_label_font() -> Font:
	if label_font == null:
		return ThemeDB.fallback_font
	return label_font


# Returns the resolved color for the given series index.
func get_series_color(p_series_index: int) -> Color:
	if series_colors.is_empty():
		return DEFAULT_SERIES_COLOR
	return series_colors[p_series_index % series_colors.size()]


# Returns the resolved opacity for the given series index.
func get_series_alpha(p_series_index: int) -> float:
	if series_alphas.is_empty():
		return DEFAULT_SERIES_ALPHA
	return series_alphas[p_series_index % series_alphas.size()]

#endregion
