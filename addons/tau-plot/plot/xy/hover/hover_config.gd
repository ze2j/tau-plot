## Configuration for the hover inspection system: mode, tooltip, crosshair,
## highlight, and formatting callbacks.
class_name TauHoverConfig extends Resource


enum HoverMode
{
	AUTO,        ## Resolved per-pane based on overlay composition.
	NEAREST,     ## Single closest sample across all overlays in the pane.
	X_ALIGNED,   ## All samples at the nearest x position across all overlays.
}


enum CrosshairMode
{
	NONE,     ## No crosshair lines.
	X_ONLY,   ## Vertical line at the hovered x position.
	Y_ONLY,   ## Horizontal line at the hovered y position.
	BOTH,     ## Both vertical and horizontal lines.
}


enum TooltipPositionMode
{
	SNAP_TO_POINT,  ## Tooltip anchors to the data point with a small offset.
	FOLLOW_MOUSE,   ## Tooltip follows the cursor with a small offset.
}


## Controls which samples are collected on hover.
## AUTO resolves per-pane based on overlay composition (see HoverMode).
@export var hover_mode: HoverMode = HoverMode.AUTO

## Whether hovered samples receive a visual highlight via the
## hover_highlight_callback. Can be disabled independently of the tooltip.
@export var highlight_enabled: bool = true

## Callback invoked during rendering to adjust sample colors based on
## hover state. Receives the resolved normal color and whether this
## specific sample is the hovered one. Returns the color to actually draw.
##
## When a sample IS hovered, the callback can brighten the color, add
## saturation, or return it unchanged. When a sample is NOT hovered, the
## callback can dim it (lower alpha, desaturate) or return it unchanged.
##
## This callback is only invoked when highlight_enabled is true and at
## least one sample is currently hovered. When no sample is hovered, all
## samples use their normal resolved colors with no callback invocation.
##
## Signature: func(color: Color, hovered: bool) -> Color
##
## When unset (invalid Callable), the built-in default brightens the
## hovered sample slightly and dims non-hovered samples.
var hover_highlight_callback: Callable = Callable()

@export_group("Tooltip")

## Whether the built-in tooltip is rendered. When false, signals still fire
## and highlight/crosshair still work if enabled, but no tooltip popup
## appears. This is the switch for users who want to build their own UI
## via the sample_hovered signal.
@export var tooltip_enabled: bool = true

## Tooltip position relative to the data point.
@export var tooltip_position_mode: TooltipPositionMode = TooltipPositionMode.SNAP_TO_POINT

## Number of significant digits relative to the visible domain span used
## when formatting numeric values in tooltips. Higher values show more
## decimal places. The displayed precision adapts to the domain: a span
## of 0.001 with 3 digits shows ~6 decimal places, while a span of 1000
## with 3 digits shows ~0.
@export_range(1, 15) var tooltip_precision_digits: int = 3

## Visual styling for the tooltip popup.
## Resolved through the standard defaults > theme > user-override cascade.
@export var tooltip_style: TauTooltipStyle = TauTooltipStyle.new()

@export_group("Crosshair")

## Crosshair guide lines drawn at the hovered position.
@export var crosshair_mode: CrosshairMode = CrosshairMode.NONE

## Visual styling for the crosshair lines.
## Resolved through the standard defaults > theme > user-override cascade.
@export var crosshair_style: TauCrosshairStyle = TauCrosshairStyle.new()

@export_group("")

## Optional text formatting callback. Receives the array of SampleHit and
## returns a String (supports BBCode). When set, replaces the default
## formatting. When unset (invalid Callable), the built-in format is used.
##
## Note: the hits array is not deduplicated. If a series is bound to
## multiple overlays, there may be multiple entries with the same
## (series_id, sample_index). The callback is responsible for handling
## this as it sees fit.
##
## Signature: func(hits: Array[SampleHit]) -> String
var format_tooltip_text: Callable = Callable()

## Optional content factory callback. Receives the array of SampleHit and
## returns a Control node that becomes the tooltip's content. The plot
## manages positioning, show/hide lifecycle, and size constraints. The
## returned Control is freed when the tooltip hides.
##
## When set, takes priority over format_tooltip_text.
##
## Signature: func(hits: Array[SampleHit]) -> Control
var create_tooltip_control: Callable = Callable()
