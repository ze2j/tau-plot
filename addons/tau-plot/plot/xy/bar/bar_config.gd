## Bar-overlay specific rendering config.
class_name TauBarConfig extends TauPaneOverlayConfig

const BarVisualCallbacks := preload("res://addons/tau-plot/plot/xy/bar/bar_visual_callbacks.gd").BarVisualCallbacks

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`
#          and, if applicable, in `has_layout_affecting_change()`.
################################################################################################

## Theme-driven visual and spacing parameters for bars.
## Never null. Modify properties directly: bar_config.style.bar_width_px = 32.
## Properties set this way are automatically guarded from theme overwriting.
@export var style: TauBarStyle = TauBarStyle.new()

enum BarMode
{
	GROUPED,
	STACKED,
	INDEPENDENT
}
@export var mode: BarMode = BarMode.GROUPED

const StackedNormalization = preload("res://addons/tau-plot/plot/xy/stacked_normalization.gd").StackedNormalization
@export var stacked_normalization: StackedNormalization = StackedNormalization.NONE


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

# If type == CATEGORICAL, allowed: AUTO, THEME, CATEGORY_WIDTH_FRACTION.
# If type == CONTINUOUS,  allowed: AUTO, THEME, DATA_UNITS, NEIGHBOR_SPACING_FRACTION.
@export var bar_width_policy: BarWidthPolicy = BarWidthPolicy.AUTO

####################################################################################################
# CATEGORY_WIDTH_FRACTION policy (CATEGORICAL X axis type only)
####################################################################################################

# Fraction of the category slot width used by the entire group
# For a single series, this is the bar width.
@export_range(0.01, 1.00, 0.01) var category_width_fraction: float = 0.9    # Must in ]0; 1]

# Gap between bars inside a group, expressed as a fraction of bar width.
# Bar width is derived so that all bars and gaps fit within the category_width_fraction.
@export_range(0.00, 1.00, 0.01) var intra_group_gap_fraction: float = 0.1   # Must in [0; 1]

####################################################################################################
# DATA_UNITS policy (LINEAR X scale only)
####################################################################################################

# Bar width expressed in X data units.
# Visible effect: bars keep a constant width in "real" X units across the plot.
# Must be >= 0.
@export var bar_width_x_units: float = 1.0

# Extra spacing between bars inside a GROUPED cluster, expressed in X data units.
# Visible effect: increases or decreases the whitespace between series bars at the same X.
# Must be >= 0.
@export var bar_gap_x_units: float = 0.0


####################################################################################################
# DATA_UNITS policy (LOGARITHMIC X scale only)
####################################################################################################

# Bar width expressed as a multiplicative factor around the bar's X value.
# Visible effect: bars have a consistent relative thickness everywhere on a log axis
# (same visual width at X = 1, 10, 100, etc.).
# Example: 2.0 means the bar spans from X/sqrt(2) to X*sqrt(2).
# Must be > 1.
@export var bar_width_log_factor: float = 1.5

# Extra spacing between bars inside a GROUPED cluster, expressed as a multiplicative
# factor relative to the bar width on a log axis.
# Visible effect: increases or decreases the whitespace between series bars at the same X,
# consistently across decades.
# Must be >= 1.
@export var bar_gap_log_factor: float = 1.0


####################################################################################################
# NEIGHBOR_SPACING_FRACTION policy (continuous X only)
####################################################################################################

# Fraction of the local spacing between neighboring X samples used as the bar width
# (STACKED / INDEPENDENT) or as the total group width (GROUPED).
# Visible effect: bars automatically become thinner in dense regions and thicker in
# sparse regions.
# Must be in ]0, 1].
@export_range(0.01, 1.00) var neighbor_spacing_fraction: float = 0.8

# Extra spacing between bars inside a GROUPED cluster, expressed as a fraction of the
# individual bar width.
# For interior points, spacing is the minimum distance to the previous or next X value.
# For edge points, spacing is the distance to the single neighboring X value.
# Visible effect: increases or decreases the whitespace between series bars at the same X
# while still adapting to local sample spacing.
# Must be >= 0.
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


####################################################################################################
# Helpers
####################################################################################################

func _init() -> void:
	overlay_type = PaneOverlayType.BAR


func get_resolved_bar_width_policy(p_axis_type: TauAxisConfig.Type) -> BarWidthPolicy:
	if bar_width_policy != BarWidthPolicy.AUTO:
		return bar_width_policy

	if p_axis_type == TauAxisConfig.Type.CATEGORICAL:
		return BarWidthPolicy.CATEGORY_WIDTH_FRACTION

	return BarWidthPolicy.NEIGHBOR_SPACING_FRACTION


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
# Only mode and stacked_normalization affect the domain (stacking changes Y
# bounds via _apply_bar_domain_overrides_y). All width, gap, and spacing
# properties are visual-only: they control how bars are drawn within a fixed
# domain but do not feed into domain or tick computation.
func has_layout_affecting_change(p_other: TauPaneOverlayConfig) -> bool:
	var other := p_other as TauBarConfig
	if other == null:
		return false

	if not super.has_layout_affecting_change(other):
		return false

	if mode != other.mode:
		return true

	if mode == BarMode.STACKED and stacked_normalization != other.stacked_normalization:
		return true

	return false
