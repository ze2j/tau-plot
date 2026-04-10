## Top-level configuration for XY plots.
##
## This resource defines a shared X axis (the independent axis used by all
## series across all panes) and one or more panes. Each pane occupies a strip
## of the plot area along the stacking direction, with up to two Y axis slots
## on the edges orthogonal to the X axis.
##
## The X axis can sit on any of the four edges (BOTTOM, TOP, LEFT, RIGHT).
## When X is on BOTTOM or TOP, panes stack vertically. When X is on LEFT or
## RIGHT, panes stack horizontally. Most plots only need one pane.
class_name TauXYConfig extends Resource

const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId

## Theme-driven visual and spacing parameters for the XY plot (axes, ticks,
## padding, series colors, etc.). Never null.
## Modify properties directly: xy_config.style.pane_gap_px = 8.
## Properties set this way are automatically guarded from theme overwriting.
@export var style: TauXYStyle = TauXYStyle.new()

## Which edge of the plot carries the primary X-axis.
@export var x_axis_id: AxisId = AxisId.BOTTOM

## Configuration for the primary x-axis (shared across all panes).
@export var x_axis: TauAxisConfig = null

## Configuration for the secondary x-axis (display-only, drawn on the
## edge opposite x_axis_id). Null means no secondary axis.
## Must have [code]type = CONTINUOUS[/code] (CATEGORICAL is not supported).
## Fields [member TauAxisConfig.include_zero_in_domain],
## [member TauAxisConfig.domain_padding_mode], and
## [member TauAxisConfig.inverted] are ignored on this axis
## because its domain is derived from the primary via
## [member secondary_x_axis_transform].
@export var secondary_x_axis: TauAxisConfig = null

## Transform from primary x-axis value to secondary x-axis value.
## Signature: [code]func(p_primary_value: float) -> float[/code]
## The callable receives a value in the primary x-axis domain and returns
## the corresponding value in the secondary x-axis domain. For example,
## to show Fahrenheit on the secondary axis when the primary is Celsius:
## [codeblock]
## xy_config.secondary_x_axis_transform = func(c: float) -> float:
##     return c * 1.8 + 32.0
## [/codeblock]
## The transform can flip the direction (e.g. [code]1.0 / x[/code] for
## frequency-to-period conversion).
## Required when [member secondary_x_axis] is not null.
var secondary_x_axis_transform: Callable = Callable()

## The list of panes, ordered along the stacking direction.
## When x is on BOTTOM or TOP, panes are ordered from top to bottom.
## When x is on LEFT or RIGHT, panes are ordered from left to right.
## Most plots need only one entry.
@export var panes: Array[TauPaneConfig] = []
