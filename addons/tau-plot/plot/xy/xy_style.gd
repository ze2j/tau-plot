@tool

## Contains theme-driven visual and spacing parameters for the XY plot.
##
## Properties set on this resource take the highest priority, always winning
## over the theme and the built-in defaults. A property counts as set as soon
## as it is assigned, whatever the value, so assigning a built-in default from
## code still beats the theme.
##
## Properties left untouched fall back to the Godot theme. If the theme does
## not define them either, the built-in defaults apply.
##
## For array properties, assign a new array to mark the property as set.
## Mutating the existing array in place does not.
##
## Assign a new [Font] rather than mutating the one already assigned. An
## in-place change is not detected.
##
## [b]Limitation:[/b] a property set from the inspector to exactly its built-in
## default is not written to the saved resource, so it reads as untouched on
## load and the theme still wins. Assign it from code instead.
class_name TauXYStyle extends Resource

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()`.
################################################################################################

@export var axis_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		axis_color = value
		_overridden[&"axis_color"] = true

@export var label_font: Font = null:
	set(value):
		label_font = value
		_overridden[&"label_font"] = true

@export var label_font_size: int = 16:
	set(value):
		label_font_size = value
		_overridden[&"label_font_size"] = true

@export var label_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		label_color = value
		_overridden[&"label_color"] = true

## Tick mark dimensions for the x axis and y axis respectively.
## "x" and "y" refer to the logical axis, not screen direction. These values
## are orientation-independent: they work the same regardless of whether the
## axis is placed on a horizontal or vertical edge.
## - length: how far the tick protrudes from the axis line (perpendicular to it).
## - thickness: stroke width of the tick mark (passed to draw_line).
@export var x_major_tick_length_px: int = 4:
	set(value):
		x_major_tick_length_px = value
		_overridden[&"x_major_tick_length_px"] = true

@export var x_major_tick_thickness_px: int = 1:
	set(value):
		x_major_tick_thickness_px = value
		_overridden[&"x_major_tick_thickness_px"] = true

@export var y_major_tick_length_px: int = 4:
	set(value):
		y_major_tick_length_px = value
		_overridden[&"y_major_tick_length_px"] = true

@export var y_major_tick_thickness_px: int = 1:
	set(value):
		y_major_tick_thickness_px = value
		_overridden[&"y_major_tick_thickness_px"] = true

## Minor tick dimensions. The length is derived from the major tick length by
## multiplying it with minor_tick_length_ratio (shared across both axes).
## Thickness is independent per axis.
@export var minor_tick_length_ratio: float = 0.5:
	set(value):
		minor_tick_length_ratio = value
		_overridden[&"minor_tick_length_ratio"] = true

@export var x_minor_tick_thickness_px: int = 1:
	set(value):
		x_minor_tick_thickness_px = value
		_overridden[&"x_minor_tick_thickness_px"] = true

@export var y_minor_tick_thickness_px: int = 1:
	set(value):
		y_minor_tick_thickness_px = value
		_overridden[&"y_minor_tick_thickness_px"] = true

@export var x_tick_x_label_gap_px: int = 4:
	set(value):
		x_tick_x_label_gap_px = value
		_overridden[&"x_tick_x_label_gap_px"] = true

@export var y_tick_y_label_gap_px: int = 4:
	set(value):
		y_tick_y_label_gap_px = value
		_overridden[&"y_tick_y_label_gap_px"] = true

@export var padding_left_px: int = 4:
	set(value):
		padding_left_px = value
		_overridden[&"padding_left_px"] = true

@export var padding_right_px: int = 4:
	set(value):
		padding_right_px = value
		_overridden[&"padding_right_px"] = true

@export var padding_top_px: int = 4:
	set(value):
		padding_top_px = value
		_overridden[&"padding_top_px"] = true

@export var padding_bottom_px: int = 4:
	set(value):
		padding_bottom_px = value
		_overridden[&"padding_bottom_px"] = true

@export var pane_gap_px: int = 4:
	set(value):
		pane_gap_px = value
		_overridden[&"pane_gap_px"] = true

const DEFAULT_SERIES_COLOR := Color(0.306, 0.475, 0.655)

## Per-series cycle of series colors. Each entry sets the color of one series,
## with the array indexed cyclically by series index using modulo: series
## [code]i[/code] reads entry [code]i % series_colors.size()[/code]. An empty
## array is treated as all series drawn in [constant DEFAULT_SERIES_COLOR].
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
		series_colors = value
		_overridden[&"series_colors"] = true

const DEFAULT_SERIES_ALPHA := 1.0

## Per-series cycle of series opacities, from [code]0.0[/code] to
## [code]1.0[/code]. Each entry sets the opacity of one series, with the array
## indexed cyclically by series index using modulo: series [code]i[/code] reads
## entry [code]i % series_alphas.size()[/code]. An empty array is treated as
## all series fully opaque.
@export var series_alphas: Array[float] = [DEFAULT_SERIES_ALPHA]:
	set(value):
		series_alphas = value
		_overridden[&"series_alphas"] = true


# Exported property names assigned at least once, whatever the value. Member
# initializers bypass the setters, so a fresh instance starts empty.
var _overridden: Dictionary[StringName, bool] = {}


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

	# Series alphas: unlimited number, keyed series_alpha_percent_0, series_alpha_percent_1, ...
	# Stored as percentages because theme constants only support integers.
	var theme_series_alphas: Array[float]
	var alpha_index := 0
	while true:
		var key := "series_alpha_percent_%d" % alpha_index
		if not p_control.has_theme_constant(key):
			break
		theme_series_alphas.append(clampf(float(p_control.get_theme_constant(key)) / 100.0, 0.0, 1.0))
		alpha_index += 1
	if not theme_series_alphas.is_empty():
		series_alphas.resize(max(series_alphas.size(), theme_series_alphas.size()))
		for i in range(theme_series_alphas.size()):
			series_alphas[i] = theme_series_alphas[i]


####################################################################################################
# Cascade: user overrides (layer 3)
####################################################################################################

## Returns [code]true[/code] when [param p_property] has been assigned on this
## resource, whatever the assigned value.
func is_overridden(p_property: StringName) -> bool:
	return _overridden.has(p_property)


## Applies overridden properties from [param p_user_style] onto this resolved
## instance.
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
		series_alphas = p_user_style.series_alphas.duplicate()

	if p_user_style.is_overridden(&"series_colors"):
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

## Returns a copy of this resource carrying the property values and the
## override flags. The flags are copied explicitly because
## [method Resource.duplicate] only copies stored properties.
func make_snapshot() -> TauXYStyle:
	var copy := duplicate() as TauXYStyle
	copy._copy_overrides_from(self)
	return copy


# Writing a typed collection into another instance through a property is
# rejected at runtime, so the copy is made from inside the target.
func _copy_overrides_from(p_source: TauXYStyle) -> void:
	_overridden = p_source._overridden.duplicate()


func is_equal_to(p_other: TauXYStyle) -> bool:
	if p_other == null:
		return false
	if _overridden != p_other._overridden:
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
	if series_alphas != p_other.series_alphas:
		return false
	if series_colors != p_other.series_colors:
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


####################################################################################################
# Helpers
####################################################################################################

## Returns the resolved color for the given series index.
func get_series_color(p_series_index: int) -> Color:
	if series_colors.is_empty():
		return DEFAULT_SERIES_COLOR
	return series_colors[p_series_index % series_colors.size()]


## Returns the resolved opacity for the given series index.
func get_series_alpha(p_series_index: int) -> float:
	if series_alphas.is_empty():
		return DEFAULT_SERIES_ALPHA
	return clampf(series_alphas[p_series_index % series_alphas.size()], 0.0, 1.0)
