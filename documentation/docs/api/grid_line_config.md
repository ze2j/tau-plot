# TauGridLineConfig

!!! info ""
    **Inherits:** `Resource`  

Selects which grid lines are enabled in a pane and which axes supply their tick positions.

## Description

Grid lines are straight lines drawn across the pane background at each tick position. They give the reader a visual reference for reading data values without having to trace back to the axis. X grid lines run perpendicular to the X axis. Y grid lines run perpendicular to the Y axis. Both directions support major lines, which align with major ticks, and minor lines, which align with minor ticks and are typically styled thinner and more transparent to stay visually subordinate.

The four flags [`x_major_enabled`](#x_major_enabled), [`x_minor_enabled`](#x_minor_enabled), [`y_major_enabled`](#y_major_enabled), and [`y_minor_enabled`](#y_minor_enabled) control each independently.

A grid line needs a tick to sit on, which puts two limits on what the flags can produce. Minor ticks exist only on a [`LOGARITHMIC`](axis_config.md#scale-enum) axis, so a minor grid line draws nothing against a linear axis. A [`CATEGORICAL`](axis_config.md#type-enum) X axis produces no tick sequence at all, so a plot whose X axis is categorical draws no X grid line, major or minor. Both cases are silent: the flag stays `true` and nothing appears.

`TauGridLineConfig` is assigned to [`TauPaneConfig.grid_line`](pane_config.md#grid_line). When that property is `null`, all grid lines in the pane are disabled. Assigning an instance activates the grid line system for that pane and lets individual lines be turned on or off through the four enable flags.

`TauGridLineConfig` only governs behavior: which lines are drawn and at which positions. Visual properties such as color, stroke width, and dash pattern are set in [`TauPaneStyle`](pane_style.md).

The **source axis** properties control which axis supplies the tick positions used to place grid lines:

- [`x_source_axis_id`](#x_source_axis_id) selects between the primary and [secondary X axis](xy_config.md#secondary_x_axis). It is only relevant when a secondary X axis is present on the plot. When no secondary X axis exists, the primary X axis is always used regardless of this property.
- [`y_source_axis_id`](#y_source_axis_id) selects which Y axis drives the Y grid lines. It is only relevant when the pane has two populated Y axes. When the pane has exactly one Y axis, that axis is always used regardless of this property.

All property changes are visual-only. Every change triggers a redraw but never triggers layout recomputation.

After [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) succeeds, the plot holds a reference to this instance. Mutating a property at runtime is supported, but requires calling [`TauPlot.queue_refresh()`](tau_plot.md#queue_refresh) to apply the change. Runtime mutation is not yet supported by every property: see [Runtime Configuration Change Limitations](../runtime-configuration-change-limitations.md).

### Example

```gdscript
# Enable major Y grid lines driven by the left axis.
var grid := TauGridLineConfig.new()
grid.y_major_enabled = true
grid.y_source_axis_id = TauPlot.AxisId.LEFT

var pane := TauPaneConfig.new()
pane.y_left_axis = TauAxisConfig.new()
pane.overlays = [TauBarConfig.new()]
pane.grid_line = grid
```

## Constructor

### `new()`

```gdscript
TauGridLineConfig.new() -> TauGridLineConfig
```

Creates a new `TauGridLineConfig` with all enable flags set to `false` and source axes set to their built-in defaults. All grid lines are disabled until at least one enable flag is set to `true`.

## Properties

### x_source_axis_id

`x_source_axis_id`: [`AxisId`](tau_plot.md#axisid)

The X axis whose tick positions drive the X grid lines. Default is [`BOTTOM`](tau_plot.md#axisid).

Set this to the primary X axis (for example [`BOTTOM`](tau_plot.md#axisid)) to use primary axis ticks, or to the opposite axis (for example [`TOP`](tau_plot.md#axisid)) to use [secondary X axis](xy_config.md#secondary_x_axis) ticks. Ignored when no secondary X axis is present on the plot. Also ignored when both [`x_major_enabled`](#x_major_enabled) and [`x_minor_enabled`](#x_minor_enabled) are `false`.

When a secondary X axis is present and this property names an edge that carries neither X axis, the plot pushes an error and draws no X grid line.

---

### y_source_axis_id

`y_source_axis_id`: [`AxisId`](tau_plot.md#axisid)

The Y axis whose tick positions drive the Y grid lines. Default is [`LEFT`](tau_plot.md#axisid).

Only applies when the pane has two populated Y axes. When exactly one Y axis is populated, that axis is used regardless of this property. Also ignored when both [`y_major_enabled`](#y_major_enabled) and [`y_minor_enabled`](#y_minor_enabled) are `false`.

When the pane has two populated Y axes and this property names neither of them, the plot pushes an error and falls back to the first populated one. A pane with no populated Y axis draws no Y grid line.

---

### x_major_enabled

`x_major_enabled`: `bool`

If `true`, major grid lines are drawn perpendicular to the X axis at each major tick position. Default is `false`.

Nothing is drawn when the X axis is [`CATEGORICAL`](axis_config.md#type-enum).

---

### x_minor_enabled

`x_minor_enabled`: `bool`

If `true`, minor grid lines are drawn perpendicular to the X axis at each minor tick position. Default is `false`.

Nothing is drawn unless the source X axis is [`CONTINUOUS`](axis_config.md#type-enum) on a [`LOGARITHMIC`](axis_config.md#scale-enum) scale, the one combination that produces minor ticks.

---

### y_major_enabled

`y_major_enabled`: `bool`

If `true`, major grid lines are drawn perpendicular to the Y axis at each major tick position. Default is `false`.

---

### y_minor_enabled

`y_minor_enabled`: `bool`

If `true`, minor grid lines are drawn perpendicular to the Y axis at each minor tick position. Default is `false`.

Nothing is drawn unless the source Y axis uses a [`LOGARITHMIC`](axis_config.md#scale-enum) scale, the one scale that produces minor ticks.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauGridLineConfig` during rendering.
* [`TauPaneConfig`](pane_config.md) Owns the `TauGridLineConfig` instance via its [`grid_line`](pane_config.md#grid_line) property.
* [`TauPaneStyle`](pane_style.md) Controls the visual appearance of grid lines: color, thickness, and dash pattern.
* [`TauAxisConfig`](axis_config.md) Configures the axis that supplies tick positions to the grid lines.
* [`TauXYConfig`](xy_config.md) Holds the secondary X axis via [`secondary_x_axis`](xy_config.md#secondary_x_axis), which affects [`x_source_axis_id`](#x_source_axis_id) behavior.