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

const AxisId := preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId

## Theme-driven visual and spacing parameters for the XY plot (axes, ticks,
## padding, series colors, etc.). Never null.
## Modify properties directly: xy_config.style.pane_gap_px = 8.
## Properties set this way are automatically guarded from theme overwriting.
@export var style: TauXYStyle = TauXYStyle.new()

## Which edge of the plot carries the primary X-axis.
@export var x_axis_id: AxisId = AxisId.BOTTOM

## Configuration for the primary x-axis (shared across all panes).
@export var x_axis: TauAxisConfig = null

## Configuration for the secondary x-axis, drawn on the edge opposite
## x_axis_id. Null means no secondary axis.
##
## The secondary x-axis is display-only: it shows the primary x positions in
## another unit, through [member secondary_x_axis_transform]. Nothing is
## plotted against it. Both this axis and [member x_axis] must have
## [code]type = CONTINUOUS[/code].
##
## The secondary x-axis has no direction of its own. It runs the same way as
## the primary x-axis, and the other way when the transform decreases.
##
## Label values are picked over the secondary range according to
## [member TauAxisConfig.scale]: round values with a constant step on a
## [code]LINEAR[/code] scale, powers of ten and their subdivisions on a
## [code]LOGARITHMIC[/code] one. Each label then sits at the primary position
## whose transform gives the label value.
##
## [member TauAxisConfig.inverted], [member TauAxisConfig.include_zero_in_domain],
## the range override and the domain padding properties have no effect on
## this axis.
@export var secondary_x_axis: TauAxisConfig = null

## Transform from primary x-axis value to secondary x-axis value.
## Signature: [code]func(p_primary_value: float) -> float[/code]
## The callable receives a value in the primary x-axis range and returns
## the matching value on the secondary x-axis. For example, to show
## Fahrenheit on the secondary axis when the primary is Celsius:
## [codeblock]
## xy_config.secondary_x_axis_transform = func(c: float) -> float:
##     return c * 1.8 + 32.0
## [/codeblock]
##
## Over the current primary x range, the transform must be monotonic (always
## increasing or always decreasing) and return finite values. When
## [member secondary_x_axis] has a [code]LOGARITHMIC[/code] scale, the values
## must also be strictly positive. A decreasing or curved transform is fine,
## for example [code]1.0 / f[/code] to show periods for frequencies, as long
## as the primary x range does not hold 0.
##
## The primary x range depends on the data, so it can break these rules
## while the data changes. The secondary x-axis then shows no labels and no
## grid lines, while its line, its title and the space it takes stay. A
## warning is printed once per [method TauPlot.plot_xy] call. The labels come
## back on their own once the range meets the rules again.
##
## Required when [member secondary_x_axis] is not null.
var secondary_x_axis_transform: Callable = Callable()

## The list of panes, ordered along the stacking direction.
## When x is on BOTTOM or TOP, panes are ordered from top to bottom.
## When x is on LEFT or RIGHT, panes are ordered from left to right.
## Most plots need only one entry.
@export var panes: Array[TauPaneConfig] = []
