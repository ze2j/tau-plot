# TauXYConfig

!!! info ""
    **Inherits:** `Resource`  

Configures an XY plot.

## Description

`TauXYConfig` is the second argument passed to [`TauPlot.plot_xy()`](tau_plot.md#plot_xy). It groups three concerns:

- the configuration of the X axis shared by all panes, 
- the ordered list of panes that make up the plot area,
- the visual style of the plot through [`style`](#style).

The X axis is shared across every pane. [`x_axis_id`](#x_axis_id) determines which edge of the plot carries it. When the X axis sits on [`BOTTOM`](tau_plot.md#axisid) or [`TOP`](tau_plot.md#axisid), panes stack vertically from top to bottom. When it sits on [`LEFT`](tau_plot.md#axisid) or [`RIGHT`](tau_plot.md#axisid), panes stack horizontally from left to right. Most plots need only one pane.

An optional **secondary X axis** sits on the edge opposite the **primary X axis**. It is display-only. It shows the primary X positions in another unit, such as Celsius on the primary axis and Fahrenheit on the secondary, and the plot draws nothing against it. [`secondary_x_axis_transform`](#secondary_x_axis_transform) turns a primary value into the matching secondary value.

[`style`](#style) is created automatically at construction and is never `null`. All other properties default to `null` or an empty array. Two of them must be assigned before the config reaches [`plot_xy()`](tau_plot.md#plot_xy): [`x_axis`](#x_axis) takes the [`TauAxisConfig`](axis_config.md) of the primary X axis, and [`panes`](#panes) takes at least one [`TauPaneConfig`](pane_config.md). Leaving either at its default is a validation error.

After [`plot_xy()`](tau_plot.md#plot_xy) succeeds, the plot holds a reference to the `TauXYConfig` instance. Mutating it at runtime is supported, but requires calling [`TauPlot.queue_refresh()`](tau_plot.md#queue_refresh) to apply the changes. Runtime mutation is not yet supported by every property: see [Runtime Configuration Change Limitations](../runtime-configuration-change-limitations.md).

### Example

```gdscript
# Resistance over a temperature sweep. 
# X carries the temperature in Celsius, and the opposite edge reads the same domain in Fahrenheit.
var celsius_axis := TauAxisConfig.new()
celsius_axis.title = "Temperature (C)"

var fahrenheit_axis := TauAxisConfig.new()
fahrenheit_axis.title = "Temperature (F)"

var resistance_axis := TauAxisConfig.new()
resistance_axis.title = "Resistance (Ohm)"

var pane := TauPaneConfig.new()
pane.y_left_axis = resistance_axis

var config := TauXYConfig.new()
config.x_axis = celsius_axis
config.secondary_x_axis = fahrenheit_axis
config.secondary_x_axis_transform = func(c: float) -> float:
	return c * 1.8 + 32.0
config.panes = [pane]
```

## Constructor

### `new()`

```gdscript
TauXYConfig.new() -> TauXYConfig
```

Creates a new `TauXYConfig` with [`style`](#style) initialized to a default [`TauXYStyle`](xy_style.md), [`x_axis_id`](#x_axis_id) set to [`BOTTOM`](tau_plot.md#axisid), and all other properties set to `null` or empty. [`x_axis`](#x_axis) and [`panes`](#panes) must still be assigned.

## Properties

### x_axis_id

`x_axis_id`: [`AxisId`](tau_plot.md#axisid)

The position of the primary X axis. Default is [`BOTTOM`](tau_plot.md#axisid).

This value also controls the stacking direction of panes. [`BOTTOM`](tau_plot.md#axisid) and [`TOP`](tau_plot.md#axisid) produce vertical stacking. [`LEFT`](tau_plot.md#axisid) and [`RIGHT`](tau_plot.md#axisid) produce horizontal stacking.

---

### x_axis

`x_axis`: [`TauAxisConfig`](axis_config.md)

Configuration for the primary X axis, shared across all panes. Default is `null`.

Required. A `null` `x_axis` is a validation error and [`plot_xy()`](tau_plot.md#plot_xy) aborts without modifying the current plot. The assigned instance carries the type, scale, domain, and tick settings that every pane reads.

---

### secondary_x_axis

`secondary_x_axis`: [`TauAxisConfig`](axis_config.md)

Configuration for the secondary X axis, drawn at the position opposite [`x_axis_id`](#x_axis_id). Default is `null`, which means no secondary axis is drawn.

If [`TauAxisConfig.inverted`](axis_config.md#inverted) is `true` on [`x_axis`](#x_axis), then the secondary X axis is inverted as well. If [`secondary_x_axis_transform`](#secondary_x_axis_transform) decreases, then the secondary X axis runs opposite to the primary X axis: its largest value sits where the primary X axis shows its smallest.

Its domain is the primary X domain passed through [`secondary_x_axis_transform`](#secondary_x_axis_transform). The [`TauAxisConfig.scale`](axis_config.md#scale) of this axis picks the label values over that domain: round values with a constant step on a [`LINEAR`](axis_config.md#scale-enum) scale, powers of ten and their subdivisions on a [`LOGARITHMIC`](axis_config.md#scale-enum) one. [`TauAxisConfig.tick_count_preferred`](axis_config.md#tick_count_preferred), [`TauAxisConfig.overlap_strategy`](axis_config.md#overlap_strategy), and [`TauAxisConfig.min_label_spacing_px`](axis_config.md#min_label_spacing_px) apply as on any other axis. Each label then sits at the primary position whose transform gives the label value. A curved transform therefore leaves uneven gaps between labels. X grid lines taken from the secondary X axis through [`TauGridLineConfig.x_source_axis_id`](grid_line_config.md#x_source_axis_id) use the same positions.

Some [`TauAxisConfig`](axis_config.md) properties have no effect on this axis. Each of them says so in its own entry.

Three cases are validation errors that cause [`plot_xy()`](tau_plot.md#plot_xy) to abort: a [`CATEGORICAL`](axis_config.md#type-enum) secondary X axis, a secondary X axis while the [`type`](axis_config.md#type) of [`x_axis`](#x_axis) is [`CATEGORICAL`](axis_config.md#type-enum), and a secondary X axis without [`secondary_x_axis_transform`](#secondary_x_axis_transform).

---

### secondary_x_axis_transform

`secondary_x_axis_transform`: `Callable`

Transform from a primary X axis value to the matching secondary X axis value. Default is an invalid `Callable`.

Required when [`secondary_x_axis`](#secondary_x_axis) is not `null`. Omitting it is a validation error that causes [`plot_xy()`](tau_plot.md#plot_xy) to abort. The callable receives one `float`, the primary value, and returns a `float`, the secondary value.

Over the current primary X domain, the transform must be monotonic, which means always increasing or always decreasing, and must return finite values. When the [`TauAxisConfig.scale`](axis_config.md#scale) of [`secondary_x_axis`](#secondary_x_axis) is [`LOGARITHMIC`](axis_config.md#scale-enum), the values must also be strictly positive. A decreasing or curved transform is valid, for example `1.0 / f` for a frequency-to-period conversion, as long as the primary X domain does not hold `0`.

```gdscript
# Frequency on the primary axis, period on the secondary.
# Pin the domain so that it never holds 0, where 1.0 / f is not finite.
config.x_axis.range_override_enabled = true
config.x_axis.min_override = 1.0
config.x_axis.max_override = 10.0
config.secondary_x_axis_transform = func(f: float) -> float:
	return 1.0 / f
```

The primary X domain depends on the data, so it can break these rules while the data changes. If it does, then the secondary X axis shows no labels, and the plot draws no X grid line from it. Its line, its title, and the space it takes stay, so the plot does not jump. The plot pushes a warning the first time this happens after each [`plot_xy()`](tau_plot.md#plot_xy) call. The labels come back on their own once the domain meets the rules again.

`secondary_x_axis_transform` is not serializable. The property is not exported and cannot be saved in a `.tres` resource file. Assign it at runtime only.

---

### panes

`panes`: `Array[`[`TauPaneConfig`](pane_config.md)`]`

The ordered list of panes that make up the plot area. Default is `[]`.

Each entry defines one pane's Y axes, overlays, and stretch ratio. When [`x_axis_id`](#x_axis_id) is [`BOTTOM`](tau_plot.md#axisid) or [`TOP`](tau_plot.md#axisid), index `0` is the topmost pane. When it is [`LEFT`](tau_plot.md#axisid) or [`RIGHT`](tau_plot.md#axisid), index `0` is the leftmost pane. An empty array is a validation error, and so is a `null` entry.

---

### style

`style`: [`TauXYStyle`](xy_style.md)

The visual style applied to the whole plot: axis colors, tick dimensions, label font, padding, pane spacing, and the series color palette. Default is a freshly constructed [`TauXYStyle`](xy_style.md) with all built-in defaults.

Never `null`. Modify properties directly on the instance. Any property left unassigned on this instance can still be set by the active Godot theme. Multiple `TauXYConfig` instances can share the same [`TauXYStyle`](xy_style.md) resource.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Accepts `TauXYConfig` as the second argument of [`plot_xy()`](tau_plot.md#plot_xy).
* [`TauXYStyle`](xy_style.md) Owned by `TauXYConfig` via [`style`](#style). Controls plot-wide visual properties.
* [`TauPaneConfig`](pane_config.md) One entry in [`panes`](#panes). Defines a pane's Y axes and overlays.
* [`TauAxisConfig`](axis_config.md) Configures an individual axis. Used by [`x_axis`](#x_axis) and [`secondary_x_axis`](#secondary_x_axis).
* [`TauGridLineConfig`](grid_line_config.md) Can take its X grid line positions from [`secondary_x_axis`](#secondary_x_axis).
* [`TauXYSeriesBinding`](xy_series_binding.md) Maps a dataset series to a pane, overlay, and Y axis. Passed alongside `TauXYConfig` to [`plot_xy()`](tau_plot.md#plot_xy).
* [`Dataset`](dataset.md) The data model passed to [`plot_xy()`](tau_plot.md#plot_xy) alongside `TauXYConfig`.