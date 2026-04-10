## Behavioral configuration for grid lines in a single pane.
##
## Controls which grid lines are enabled and which axes drive the
## X and Y grid lines. Visual properties (color, thickness, dash) live in
## [TauPaneStyle], not here.
class_name TauGridLineConfig extends Resource

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`
#          and, if applicable, in `has_layout_affecting_change()`.
################################################################################################

const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId

## Which X axis edge supplies tick positions for the X grid lines.
## Set this to the primary x edge (e.g. BOTTOM) to use the primary
## axis ticks, or to the opposite edge (e.g. TOP) to use the secondary
## x axis ticks.
## Ignored when no secondary x axis is used (primary ticks are
## always used in that case).
## Ignored when both [member x_major_enabled] and
## [member x_minor_enabled] are false.
@export var x_source_axis_id: AxisId = AxisId.BOTTOM

## Which Y axis edge supplies tick positions for the Y grid lines.
## Only matters when the pane has two populated Y axes. When exactly
## one Y axis is populated, that axis is used regardless of this
## property.
## Ignored when both [member y_major_enabled] and
## [member y_minor_enabled] are false.
@export var y_source_axis_id: AxisId = AxisId.LEFT

@export var x_major_enabled: bool = false
@export var x_minor_enabled: bool = false
@export var y_major_enabled: bool = false
@export var y_minor_enabled: bool = false


func is_equal_to(p_other: TauGridLineConfig) -> bool:
	if p_other == null:
		return false
	if x_source_axis_id != p_other.x_source_axis_id:
		return false
	if y_source_axis_id != p_other.y_source_axis_id:
		return false
	if x_major_enabled != p_other.x_major_enabled:
		return false
	if x_minor_enabled != p_other.x_minor_enabled:
		return false
	if y_major_enabled != p_other.y_major_enabled:
		return false
	if y_minor_enabled != p_other.y_minor_enabled:
		return false
	return true


## Grid line enable/disable changes are visual-only and do not affect
## layout (pane rects, tick positions, or label measurement).
func has_layout_affecting_change(_p_other: TauGridLineConfig) -> bool:
	return false
