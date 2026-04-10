## Configures a single pane in the plot.
##
## A pane is a strip of the plot area with four positional y axis slots.
## Only the two slots orthogonal to [member TauXYConfig.x_axis_id] are valid
## y axis positions. When X is on BOTTOM or TOP, panes are horizontal strips
## stacked vertically. When X is on LEFT or RIGHT, panes are vertical strips
## stacked side by side.
##
## Most plots use a single pane with one y axis and one x axis.
## Panes can be stacked for multiple independent scales (e.g. a stock chart
## with a price pane and a volume pane).
class_name TauPaneConfig extends Resource

const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId

## Y axis displayed on the bottom edge, or [code]null[/code] if unused.
@export var y_bottom_axis: TauAxisConfig = null

## Y axis displayed on the top edge, or [code]null[/code] if unused.
@export var y_top_axis: TauAxisConfig = null

## Y axis displayed on the left edge, or [code]null[/code] if unused.
@export var y_left_axis: TauAxisConfig = null

## Y axis displayed on the right edge, or [code]null[/code] if unused.
@export var y_right_axis: TauAxisConfig = null

## Visual style for this pane.
## Multiple panes can share the same TauPaneStyle resource.
@export var style: TauPaneStyle = TauPaneStyle.new()

## Grid line settings. Visual styling lives in [member style].
@export var grid_line: TauGridLineConfig = null

## A list of overlay configs, one per distinct [code]PaneOverlayType[/code], in no particular order.
## Add concrete configs directly (e.g. [TauBarConfig], [TauScatterConfig]).
@export var overlays: Array[TauPaneOverlayConfig] = []

## Stretch ratio of this pane compared to the others. Works like
## [member Control.size_flags_stretch_ratio]. Three panes with weights
## [code]2, 1, 1[/code] produce a 50%/25%/25% split.
@export var stretch_ratio: float = 1.0

## If [code]true[/code], the two y axes are adjusted so that
## the value zero appears at the same pixel position on both sides.
##
## The pane must have exactly two y axes, both using
## [constant TauAxisConfig.Scale.LINEAR] scale. Each axis must also
## guarantee that zero is inside its range: axes with
## [member TauAxisConfig.range_override_enabled] satisfy this when
## the specified range contains zero, and axes without
## [member TauAxisConfig.range_override_enabled] satisfy this when
## [member TauAxisConfig.include_zero_in_domain] is [code]true[/code].
##
## An axis with [member TauAxisConfig.range_override_enabled] is never
## modified. If both axes have it enabled, alignment is skipped. If
## only one axis has it enabled, only the other axis is adjusted.
## If neither axis has it enabled, the axis whose domain needs the
## least expansion is adjusted.
@export var align_y_axes_at_zero: bool = false


####################################################################################################
# Helpers
####################################################################################################

const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType


func get_y_axis_config(p_axis_id: AxisId) -> TauAxisConfig:
	match p_axis_id:
		AxisId.BOTTOM:
			return y_bottom_axis
		AxisId.TOP:
			return y_top_axis
		AxisId.LEFT:
			return y_left_axis
		AxisId.RIGHT:
			return y_right_axis
		_:
			push_error("Unexpected axis id %d" % p_axis_id)
			return null


func get_overlay_config(p_overlay_type: PaneOverlayType) -> TauPaneOverlayConfig:
	for overlay_config in overlays:
		if overlay_config != null and overlay_config.overlay_type == p_overlay_type:
			return overlay_config
	return null
