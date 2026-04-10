# TauPaneConfig

!!! info ""
    **Inherits:** `Resource`  

Configures a pane in an XY plot.

## Description

`TauPaneConfig` defines one rectangular strip of the plot area. Each entry in [`TauXYConfig.panes`](xy_config.md#panes) is one `TauPaneConfig` instance. The plot renders panes in array order, stacking them vertically when the X axis is [`BOTTOM`](tau_plot.md#axisid) or [`TOP`](tau_plot.md#axisid), or horizontally when it is [`LEFT`](tau_plot.md#axisid) or [`RIGHT`](tau_plot.md#axisid).

Each pane exposes four **Y axis slots**: [`y_bottom_axis`](#y_bottom_axis), [`y_top_axis`](#y_top_axis), [`y_left_axis`](#y_left_axis), and [`y_right_axis`](#y_right_axis). Only the two slots orthogonal to the X axis are valid Y positions:

 - When the X axis is [`BOTTOM`](tau_plot.md#axisid) or [`TOP`](tau_plot.md#axisid), only [`y_left_axis`](#y_left_axis) and [`y_right_axis`](#y_right_axis) are valid.
 - When the X axis is [`LEFT`](tau_plot.md#axisid) or [`RIGHT`](tau_plot.md#axisid), only [`y_bottom_axis`](#y_bottom_axis) and [`y_top_axis`](#y_top_axis) are valid.

A pane can use one or both valid Y axis slots.

Each pane holds one or more **overlays**, configured through [`overlays`](#overlays). An overlay is a visual layer that draws series data inside the pane. Each [type of overlay](tau_plot.md#paneoverlaytype) maps to a concrete configuration class: [`TauBarConfig`](bar_config.md) draws bars, [`TauScatterConfig`](scatter_config.md) draws scatter markers. A pane can combine different types, but each type can appear at most once.

The relative size of a pane within the plot area is controlled by [`stretch_ratio`](#stretch_ratio). It works like `Control.size_flags_stretch_ratio`: a pane with ratio `3` alongside one with ratio `1` takes 75% of the available space.

Visual appearance is controlled by [`style`](#style). Grid lines are the horizontal and vertical lines drawn across the pane at each tick position, giving readers a reference to read data values against. They are configured through [`grid_line`](#grid_line), which is `null` by default, leaving all grid lines disabled.

When a pane carries two Y axes, [`align_y_axes_at_zero`](#align_y_axes_at_zero) optionally adjusts one or both domains so that the value zero aligns at the same pixel position on both sides of the pane.

### Example

```gdscript
var price_axis := TauAxisConfig.new()
price_axis.title = "Price"
price_axis.include_zero_in_domain = false

var bar_config := TauBarConfig.new()
bar_config.mode = TauBarConfig.BarMode.INDEPENDENT

var pane := TauPaneConfig.new()
pane.y_left_axis = price_axis
pane.stretch_ratio = 3.0
pane.overlays = [bar_config]
```

### Notes

1. **Axis slots parallel to the X axis are invalid.** Assigning a Y axis to a slot that runs parallel to the X axis is a validation error. [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) logs the error and aborts without modifying the current plot.

## Constructor

### `new()`

```gdscript
TauPaneConfig.new() -> TauPaneConfig
```

Creates a new `TauPaneConfig` with all properties set to their built-in defaults. The instance is ready to configure and pass to [`TauXYConfig.panes`](xy_config.md#panes).

## Properties

### y_bottom_axis

`y_bottom_axis`: `TauAxisConfig`

When non-`null`, places a Y axis on the bottom edge of the pane. Default is `null`.

Only valid when the X axis is [`LEFT`](tau_plot.md#axisid) or [`RIGHT`](tau_plot.md#axisid). Assigning it when the X axis is [`BOTTOM`](tau_plot.md#axisid) or [`TOP`](tau_plot.md#axisid) is a validation error (see [note 1](#notes)).

---

### y_top_axis

`y_top_axis`: `TauAxisConfig`

When non-`null`, places a Y axis on the top edge of the pane. Default is `null`.

Only valid when the X axis is [`LEFT`](tau_plot.md#axisid) or [`RIGHT`](tau_plot.md#axisid). Assigning it when the X axis is [`BOTTOM`](tau_plot.md#axisid) or [`TOP`](tau_plot.md#axisid) is a validation error (see [note 1](#notes)).

---

### y_left_axis

`y_left_axis`: `TauAxisConfig`

When non-`null`, places a Y axis on the left edge of the pane. Default is `null`.

Only valid when the X axis is [`BOTTOM`](tau_plot.md#axisid) or [`TOP`](tau_plot.md#axisid). Assigning it when the X axis is [`LEFT`](tau_plot.md#axisid) or [`RIGHT`](tau_plot.md#axisid) is a validation error (see [note 1](#notes)).

---

### y_right_axis

`y_right_axis`: `TauAxisConfig`

When non-`null`, places a Y axis on the right edge of the pane. Default is `null`.

Only valid when the X axis is [`BOTTOM`](tau_plot.md#axisid) or [`TOP`](tau_plot.md#axisid). Assigning it when the X axis is [`LEFT`](tau_plot.md#axisid) or [`RIGHT`](tau_plot.md#axisid) is a validation error (see [note 1](#notes)).

---

### overlays

`overlays`: `Array[TauPaneOverlayConfig]`

The list of overlays rendered in this pane. Default is `[]`.

Add one entry per [type of overlay](tau_plot.md#paneoverlaytype) to use: [`TauBarConfig`](bar_config.md) for bars, [`TauScatterConfig`](scatter_config.md) for scatter markers. The same type of overlay cannot appear more than once. The order of entries does not affect rendering order.

---

### style

`style`: `TauPaneStyle`

The visual style applied to this pane: grid line colors, thicknesses, and dash lengths. Default is a freshly constructed [`TauPaneStyle`](pane_style.md) with all built-in defaults.

Never `null`. Modify properties directly on the instance. Any property left at its built-in default remains overridable by the active Godot theme. Multiple `TauPaneConfig` instances can share the same [`TauPaneStyle`](pane_style.md) resource.

---

### grid_line

`grid_line`: `TauGridLineConfig`

Grid line configuration for this pane. Default is `null`.

Grid lines are the horizontal and vertical lines drawn across the pane at each tick position. If `null`, all grid lines are disabled. Assign a [`TauGridLineConfig`](grid_line_config.md) instance to enable individual grid lines and configure which axis drives each direction. Visual properties such as color, thickness, and dash pattern are set in [`style`](#style).

---

### stretch_ratio

`stretch_ratio`: `float`

The relative size of this pane compared to the others along the stacking direction. Default is `1.0`.

Works like `Control.size_flags_stretch_ratio`. Three panes with ratios `2.0`, `1.0`, and `1.0` produce a 50%/25%/25% split. Has no visible effect when the plot contains only one pane.

---

### align_y_axes_at_zero

`align_y_axes_at_zero`: `bool`

When `true`, the plot adjusts Y axis domains so that zero appears at the same pixel position on both sides of the pane. Default is `false`.

The pane must have exactly two Y axes, both using [`TauAxisConfig.Scale.LINEAR`](axis_config.md#scale). Each must include zero in its domain. An axis with [`TauAxisConfig.range_override_enabled`](axis_config.md#range_override_enabled) set to `true` is never modified. If both axes have it enabled, alignment is skipped entirely. If only one does, only the other axis is adjusted. If neither does, the axis requiring the least domain expansion is adjusted.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauPaneConfig` instances when building the plot.
* [`TauXYConfig`](xy_config.md) Owns the list of `TauPaneConfig` instances via its [`panes`](xy_config.md#panes) property.
* [`TauAxisConfig`](axis_config.md) Configures a Y axis assigned to one of the four axis slots.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class for overlay configurations placed in [`overlays`](#overlays).
* [`TauBarConfig`](bar_config.md) Concrete overlay configuration for bar rendering.
* [`TauScatterConfig`](scatter_config.md) Concrete overlay configuration for scatter rendering.
* [`TauPaneStyle`](pane_style.md) Controls visual appearance for this pane, assigned to [`style`](#style).
* [`TauGridLineConfig`](grid_line_config.md) Holds the grid line configuration for this pane, assigned to [`grid_line`](#grid_line).
* [`TauXYStyle`](xy_style.md) Sibling style resource for the whole plot.
* [`TauBarStyle`](bar_style.md) Sibling style resource for bar overlays.
* [`TauScatterStyle`](scatter_style.md) Sibling style resource for scatter overlays.
