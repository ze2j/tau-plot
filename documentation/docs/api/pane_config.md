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

Each pane holds one or more **overlays**, configured through [`overlays`](#overlays). An overlay is a visual layer that draws series data inside the pane. Each [type of overlay](tau_plot.md#paneoverlaytype) maps to a concrete configuration class: [`TauBarConfig`](bar_config.md) draws bars, [`TauScatterConfig`](scatter_config.md) draws scatter markers, and [`TauLineConfig`](line_config.md) draws curves. A pane can combine different types, but each type can appear at most once. A second overlay of a type already present is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts.

The relative size of a pane within the plot area is controlled by [`stretch_ratio`](#stretch_ratio). It works like `Control.size_flags_stretch_ratio`: a pane with ratio `3` alongside one with ratio `1` takes 75% of the available space.

Visual appearance is controlled by [`style`](#style). Grid lines are the horizontal and vertical lines drawn across the pane at each tick position, giving readers a reference to read data values against. They are configured through [`grid_line`](#grid_line), which is `null` by default, leaving all grid lines disabled.

When a pane carries two Y axes, [`align_y_axes_at_zero`](#align_y_axes_at_zero) optionally adjusts one or both domains so that the value zero aligns at the same pixel position on both sides of the pane.

After [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) succeeds, the plot holds a reference to every `TauPaneConfig` instance it received. Mutating a property at runtime is supported, but requires calling [`TauPlot.queue_refresh()`](tau_plot.md#queue_refresh) to apply the change.

### Example

```gdscript
# A single pane drawing prices as bars against a Y axis on its left edge.
var price_axis := TauAxisConfig.new()
price_axis.title = "Price"
# Bars grow from zero, so the domain has to contain it.
price_axis.include_zero_in_domain = true

var bar_config := TauBarConfig.new()
bar_config.mode = TauBarConfig.BarMode.INDEPENDENT

var pane := TauPaneConfig.new()
pane.y_left_axis = price_axis
pane.overlays = [bar_config]
```

### Notes

1. **A Y axis in a slot parallel to the X axis is ignored.** Nothing rejects it and nothing draws it. What does abort [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) is a binding: a [`TauXYSeriesBinding.y_axis_id`](xy_series_binding.md#y_axis_id) that is not orthogonal to [`TauXYConfig.x_axis_id`](xy_config.md#x_axis_id), or one naming a slot the target pane left `null`.

## Constructor

### `new()`

```gdscript
TauPaneConfig.new() -> TauPaneConfig
```

Creates a new `TauPaneConfig` with all properties set to their built-in defaults. The instance is ready to configure and pass to [`TauXYConfig.panes`](xy_config.md#panes).

## Properties

### y_bottom_axis

`y_bottom_axis`: [`TauAxisConfig`](axis_config.md)

When non-`null`, places a Y axis on the bottom edge of the pane. Default is `null`.

Only valid when the X axis is [`LEFT`](tau_plot.md#axisid) or [`RIGHT`](tau_plot.md#axisid). Assigning it when the X axis is [`BOTTOM`](tau_plot.md#axisid) or [`TOP`](tau_plot.md#axisid) has no effect (see [note 1](#notes)).

---

### y_top_axis

`y_top_axis`: [`TauAxisConfig`](axis_config.md)

When non-`null`, places a Y axis on the top edge of the pane. Default is `null`.

Only valid when the X axis is [`LEFT`](tau_plot.md#axisid) or [`RIGHT`](tau_plot.md#axisid). Assigning it when the X axis is [`BOTTOM`](tau_plot.md#axisid) or [`TOP`](tau_plot.md#axisid) has no effect (see [note 1](#notes)).

---

### y_left_axis

`y_left_axis`: [`TauAxisConfig`](axis_config.md)

When non-`null`, places a Y axis on the left edge of the pane. Default is `null`.

Only valid when the X axis is [`BOTTOM`](tau_plot.md#axisid) or [`TOP`](tau_plot.md#axisid). Assigning it when the X axis is [`LEFT`](tau_plot.md#axisid) or [`RIGHT`](tau_plot.md#axisid) has no effect (see [note 1](#notes)).

---

### y_right_axis

`y_right_axis`: [`TauAxisConfig`](axis_config.md)

When non-`null`, places a Y axis on the right edge of the pane. Default is `null`.

Only valid when the X axis is [`BOTTOM`](tau_plot.md#axisid) or [`TOP`](tau_plot.md#axisid). Assigning it when the X axis is [`LEFT`](tau_plot.md#axisid) or [`RIGHT`](tau_plot.md#axisid) has no effect (see [note 1](#notes)).

---

### overlays

`overlays`: `Array[`[`TauPaneOverlayConfig`](pane_overlay_config.md)`]`

The list of overlays rendered in this pane. Default is `[]`.

Add one entry per [type of overlay](tau_plot.md#paneoverlaytype) to use: [`TauBarConfig`](bar_config.md) for bars, [`TauScatterConfig`](scatter_config.md) for scatter markers, [`TauLineConfig`](line_config.md) for curves. A second entry of a type already present is a validation error, and so is a `null` entry. The order of entries does not affect rendering order.

---

### style

`style`: [`TauPaneStyle`](pane_style.md)

The visual style applied to this pane: grid line colors, thicknesses, and dash lengths. Default is a freshly constructed [`TauPaneStyle`](pane_style.md) with all built-in defaults.

Never `null`. Modify properties directly on the instance. Any property left unassigned on this instance can still be set by the active Godot theme. Multiple `TauPaneConfig` instances can share the same [`TauPaneStyle`](pane_style.md) resource.

---

### grid_line

`grid_line`: [`TauGridLineConfig`](grid_line_config.md)

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

Alignment requires the pane to hold exactly two Y axes, both using [`TauAxisConfig.Scale.LINEAR`](axis_config.md#scale-enum), and both guaranteeing zero inside their domain. What counts as that guarantee differs per axis. An axis with [`TauAxisConfig.range_override_enabled`](axis_config.md#range_override_enabled) satisfies it when the overridden range contains zero. An axis without it satisfies it when [`TauAxisConfig.include_zero_in_domain`](axis_config.md#include_zero_in_domain) is `true`.

An axis with [`TauAxisConfig.range_override_enabled`](axis_config.md#range_override_enabled) is never modified. If both axes have it enabled, alignment is skipped. If only one does, only the other axis is adjusted. If neither does, the axis requiring the least domain expansion is adjusted.

Every precondition above is checked silently. When one is unmet the two domains are left as computed, with no error and no warning.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauPaneConfig` instances when building the plot.
* [`TauXYSeriesBinding`](xy_series_binding.md) Maps a series to a pane and to one of its Y axis slots.
* [`TauXYConfig`](xy_config.md) Owns the list of `TauPaneConfig` instances via its [`panes`](xy_config.md#panes) property, and carries the X axis position that decides which Y axis slots are valid.
* [`TauAxisConfig`](axis_config.md) Configures a Y axis assigned to one of the four axis slots.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class for overlay configurations placed in [`overlays`](#overlays).
* [`TauBarConfig`](bar_config.md) Concrete overlay configuration for bar rendering.
* [`TauScatterConfig`](scatter_config.md) Concrete overlay configuration for scatter rendering.
* [`TauLineConfig`](line_config.md) Concrete overlay configuration for line rendering.
* [`TauPaneStyle`](pane_style.md) Controls visual appearance for this pane, assigned to [`style`](#style).
* [`TauGridLineConfig`](grid_line_config.md) Holds the grid line configuration for this pane, assigned to [`grid_line`](#grid_line).
* [`TauXYStyle`](xy_style.md) Sibling style resource for the whole plot.
* [`TauBarStyle`](bar_style.md) Sibling style resource for bar overlays.
* [`TauScatterStyle`](scatter_style.md) Sibling style resource for scatter overlays.
* [`TauLineStyle`](line_style.md) Sibling style resource for line overlays.