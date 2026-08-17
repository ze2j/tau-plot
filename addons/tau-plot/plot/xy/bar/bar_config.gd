## Bar-overlay specific rendering config.
class_name TauBarConfig extends TauPaneOverlayConfig

const BarVisualCallbacks := preload("res://addons/tau-plot/plot/xy/bar/bar_visual_callbacks.gd").BarVisualCallbacks

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`
#          and, if applicable, in `has_layout_affecting_change()`. `style` is the
#          one exception, see the note above `is_equal_to()`.
################################################################################################

## Theme-driven visual and spacing parameters for bars.
## Never null. Modify properties directly: bar_config.style.bar_width_px = 32.
## Properties set this way are automatically guarded from theme overwriting.
@export var style: TauBarStyle = TauBarStyle.new()

## How the bars of several series are arranged.
enum BarMode
{
	## Bars sit side by side inside the x position, sharing its width.
	GROUPED,

	## Bars are stacked on top of one another, each starting where the
	## previous series ended.
	STACKED,

	## Bars are drawn at full width at the x position and overlap, each series
	## starting from the baseline.
	INDEPENDENT
}

## Arrangement of the bars of several series. See [enum BarMode].
## A single-series overlay draws the same way in all three modes.
@export var mode: BarMode = BarMode.GROUPED

const StackedNormalization := preload("res://addons/tau-plot/plot/xy/stacked_normalization.gd").StackedNormalization

## What each stack is scaled to in [constant BarMode.STACKED]. See
## [enum StackedNormalization]. Ignored in the other bar modes.
@export var stacked_normalization: StackedNormalization = StackedNormalization.NONE

const StackedNegativePolicy := preload("res://addons/tau-plot/plot/xy/stacked_negative_policy.gd").StackedNegativePolicy

## How negative values are handled in STACKED mode:
## - SKIP_NEGATIVES (default) drops negative samples entirely from the stack.
## - DIVERGING splits each X into an upper stack of positive values and
## a lower stack of negative values, both anchored at zero.
## - SIGNED_SUM is not a valid choice for bars: bar geometry cannot represent a
## downward dip without overlapping rectangles. Setting it produces a validation
## error.
@export var stacked_negative_policy: StackedNegativePolicy = StackedNegativePolicy.SKIP_NEGATIVES


## Where the bar width and the gaps between bars come from.
enum BarWidthPolicy
{
	AUTO,                       ## Uses the library default width policy for the active X axis type:
								## - CATEGORICAL => CATEGORY_WIDTH_FRACTION
								## - CONTINUOUS => NEIGHBOR_SPACING_FRACTION
	THEME,                      ## Uses theme constants (pixel-based) for width/gaps: bar_intragroup_gap_px and bar_width_px.
	CATEGORY_WIDTH_FRACTION,    ## Width derived from the categorical slot width (CATEGORICAL X axis type only).
	DATA_UNITS,                 ## Width expressed in X data units (CONTINUOUS X axis type only).
	NEIGHBOR_SPACING_FRACTION   ## Width derived from local neighbor spacing (CONTINUOUS X axis type only).
}

## Where the bar width and the gaps between bars come from. See
## [enum BarWidthPolicy].
##
## Which policies a pane accepts depends on the type of its x axis. A
## categorical x axis accepts AUTO, THEME and CATEGORY_WIDTH_FRACTION. A
## continuous one accepts AUTO, THEME, DATA_UNITS and
## NEIGHBOR_SPACING_FRACTION. Any other combination is a validation error.
##
## The policy also decides whether the width is theme-driven.
## [constant BarWidthPolicy.THEME] reads [member TauBarStyle.bar_width_px] and
## [member TauBarStyle.bar_intragroup_gap_px], both resolved through the style
## cascade described in [TauStyle], so a theme can set them. Every other
## policy derives the width and the gap from properties of this config, which
## have no theme layer.
@export var bar_width_policy: BarWidthPolicy = BarWidthPolicy.AUTO

####################################################################################################
# CATEGORY_WIDTH_FRACTION policy (CATEGORICAL X axis type only)
####################################################################################################

## Share of a category slot taken up by the whole group of bars drawn at that
## category, the rest being left as whitespace between categories. With a
## single series this is the bar width itself.
##
## Only read under [constant BarWidthPolicy.CATEGORY_WIDTH_FRACTION]. Valid
## range is [code]]0.0, 1.0][/code].
@export_range(0.01, 1.00, 0.01) var category_width_fraction: float = 0.9

## Gap between two bars of the same group, as a share of one bar width. The
## bar width is derived so that the bars and the gaps together fill the span
## set by [member category_width_fraction].
##
## Only read under [constant BarWidthPolicy.CATEGORY_WIDTH_FRACTION], and
## only in [constant BarMode.GROUPED]. Valid range is
## [code][0.0, 1.0][/code].
@export_range(0.00, 1.00, 0.01) var intra_group_gap_fraction: float = 0.1

####################################################################################################
# DATA_UNITS policy (LINEAR X scale only)
####################################################################################################

## Bar width in x data units, so bars keep the same width in data terms
## wherever they sit on the axis.
##
## Only read under [constant BarWidthPolicy.DATA_UNITS] on a linear x axis. A
## logarithmic x axis reads [member bar_width_log_factor] instead. Must be at
## or above [code]0.0[/code].
@export var bar_width_x_units: float = 1.0

## Gap between two bars of the same group, in x data units.
##
## Only read under [constant BarWidthPolicy.DATA_UNITS] on a linear x axis,
## and only in [constant BarMode.GROUPED]. Must be at or above
## [code]0.0[/code].
@export var bar_gap_x_units: float = 0.0


####################################################################################################
# DATA_UNITS policy (LOGARITHMIC X scale only)
####################################################################################################

## Bar width as a multiplicative factor around the x value of the bar, so
## bars keep the same on-screen width across decades. [code]2.0[/code] spans
## from [code]x / sqrt(2)[/code] to [code]x * sqrt(2)[/code].
##
## Only read under [constant BarWidthPolicy.DATA_UNITS] on a logarithmic x
## axis. A linear x axis reads [member bar_width_x_units] instead. Must be
## at or above [code]1.0[/code].
@export var bar_width_log_factor: float = 1.5

## Gap between two bars of the same group, as a multiplicative factor on the
## bar width, so the gap stays even across decades.
##
## Only read under [constant BarWidthPolicy.DATA_UNITS] on a logarithmic x
## axis, and only in [constant BarMode.GROUPED]. [code]1.0[/code] leaves no
## gap. Must be at or above [code]1.0[/code].
@export var bar_gap_log_factor: float = 1.0


####################################################################################################
# NEIGHBOR_SPACING_FRACTION policy (continuous X only)
####################################################################################################

## Share of the distance to the nearest neighbouring x sample taken up by the
## bar, or by the whole group in [constant BarMode.GROUPED]. Bars thin out
## where the samples crowd together and widen where they spread apart.
##
## Only read under [constant BarWidthPolicy.NEIGHBOR_SPACING_FRACTION]. Valid
## range is [code]]0.0, 1.0][/code].
@export_range(0.01, 1.00, 0.01) var neighbor_spacing_fraction: float = 0.8

## Gap between two bars of the same group, as a share of one bar width, so
## the gap follows the local sample spacing the same way the width does.
##
## Only read under [constant BarWidthPolicy.NEIGHBOR_SPACING_FRACTION], and
## only in [constant BarMode.GROUPED]. Must be at or above [code]0.0[/code].
@export var neighbor_gap_fraction: float = 0.1


####################################################################################################
# Typed visual_callbacks accessor
####################################################################################################

## Typed accessor for bar-specific visual callbacks.
## Shadows the base [member TauPaneOverlayConfig.visual_callbacks] with the concrete type.
var bar_visual_callbacks: BarVisualCallbacks:
	get:
		return visual_callbacks as BarVisualCallbacks
	set(value):
		visual_callbacks = value


#region Internal, not public API, may change without notice.

func _init() -> void:
	overlay_type = PaneOverlayType.BAR


func get_resolved_bar_width_policy(p_axis_type: TauAxisConfig.Type) -> BarWidthPolicy:
	if bar_width_policy != BarWidthPolicy.AUTO:
		return bar_width_policy

	if p_axis_type == TauAxisConfig.Type.CATEGORICAL:
		return BarWidthPolicy.CATEGORY_WIDTH_FRACTION

	return BarWidthPolicy.NEIGHBOR_SPACING_FRACTION


# `style` is left out on purpose. A style resource carries its own equality and
# emits `changed` when mutated, so style changes are diffed and re-resolved on
# their own. Comparing it here would only repeat that work.
func is_equal_to(p_other: TauPaneOverlayConfig) -> bool:
	var other := p_other as TauBarConfig
	if other == null:
		return false

	if not super.is_equal_to(other):
		return false

	if mode != other.mode:
		return false
	if stacked_normalization != other.stacked_normalization:
		return false
	if stacked_negative_policy != other.stacked_negative_policy:
		return false

	if bar_width_policy != other.bar_width_policy:
		return false

	if category_width_fraction != other.category_width_fraction:
		return false
	if intra_group_gap_fraction != other.intra_group_gap_fraction:
		return false

	if bar_width_x_units != other.bar_width_x_units:
		return false
	if bar_gap_x_units != other.bar_gap_x_units:
		return false

	if bar_width_log_factor != other.bar_width_log_factor:
		return false
	if bar_gap_log_factor != other.bar_gap_log_factor:
		return false

	if neighbor_spacing_fraction != other.neighbor_spacing_fraction:
		return false
	if neighbor_gap_fraction != other.neighbor_gap_fraction:
		return false

	return true


# Returns true if the change between this and p_other affects layout/domain.
# Returns false if the change only affects visual appearance.
#
# mode, stacked_normalization, and stacked_negative_policy affect the domain:
# stacking changes Y bounds, normalization pins the range, and the negative
# policy decides whether the lower half-axis exists. All width, gap, and
# spacing properties are visual-only: they control how bars are drawn within
# a fixed domain but do not feed into domain or tick computation.
func has_layout_affecting_change(p_other: TauPaneOverlayConfig) -> bool:
	var other := p_other as TauBarConfig

	if super.has_layout_affecting_change(other):
		return true

	if mode != other.mode:
		return true

	if mode == BarMode.STACKED and stacked_normalization != other.stacked_normalization:
		return true

	if mode == BarMode.STACKED and stacked_negative_policy != other.stacked_negative_policy:
		return true

	return false

#endregion
