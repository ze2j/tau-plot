## Line-overlay specific rendering config.
class_name TauLineConfig extends TauPaneOverlayConfig

const LineVisualCallbacks := preload("res://addons/tau-plot/plot/xy/line/line_visual_callbacks.gd").LineVisualCallbacks

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`
#          and, if applicable, in `has_layout_affecting_change()`.
################################################################################################

## Theme-driven visual parameters for lines.
## Never null. Modify properties directly: line_config.style.line_width_px = 3.0.
## Properties set this way are automatically guarded from theme overwriting.
@export var style: TauLineStyle = TauLineStyle.new()

enum LineMode
{
	INDEPENDENT,   ## Each series is drawn independently.
	STACKED        ## Values at the same X are summed across series.
}
@export var mode: LineMode = LineMode.INDEPENDENT

const StackedNormalization = preload("res://addons/tau-plot/plot/xy/stacked_normalization.gd").StackedNormalization
@export var stacked_normalization: StackedNormalization = StackedNormalization.NONE

## Maximum pixel distance from the cursor to a sample position for the sample
## to be considered a hover hit.
##
## In NEAREST mode, this is a 2D Euclidean distance gate. Samples farther
## than this value from the cursor are excluded entirely.
##
## In X_ALIGNED mode, this is an x-axis-only pixel gate. Samples whose x
## screen position differs from the target x by more than this value are
## excluded. The same threshold sets [member SampleHit.contains_pointer]
## on included hits.
@export var hover_max_distance_px: int = 10


####################################################################################################
# Typed visual_callbacks accessor
####################################################################################################

## Typed accessor for line-specific visual callbacks.
## Shadows the base [member TauPaneOverlayConfig.visual_callbacks] with the concrete type.
var line_visual_callbacks: LineVisualCallbacks:
	get:
		return visual_callbacks as LineVisualCallbacks
	set(value):
		visual_callbacks = value


####################################################################################################
# Helpers
####################################################################################################

func _init() -> void:
	overlay_type = PaneOverlayType.LINE


func is_equal_to(p_other: TauPaneOverlayConfig) -> bool:
	var other := p_other as TauLineConfig
	if other == null:
		return false

	if not super.is_equal_to(other):
		return false

	if mode != other.mode:
		return false
	if stacked_normalization != other.stacked_normalization:
		return false
	if hover_max_distance_px != other.hover_max_distance_px:
		return false

	return true


# Returns true if the change between this and p_other affects layout/domain.
# Returns false if the change only affects visual appearance.
#
# Only mode and stacked_normalization affect the domain: stacking changes the
# Y bounds. Hover distance is a pure hit-test parameter with no layout effect.
func has_layout_affecting_change(p_other: TauPaneOverlayConfig) -> bool:
	var other := p_other as TauLineConfig
	if other == null:
		return false

	if not super.has_layout_affecting_change(other):
		return false

	if mode != other.mode:
		return true

	if mode == LineMode.STACKED and stacked_normalization != other.stacked_normalization:
		return true

	return false
