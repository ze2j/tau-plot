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

A **secondary X axis** can be added on the edge opposite the primary. It is display-only: its domain is not computed independently but derived from the primary domain through [`secondary_x_axis_transform`](#secondary_x_axis_transform). This is useful for showing the same data range in a different unit, such as Celsius on the primary axis and Fahrenheit on the secondary. The secondary axis only supports [`TauAxisConfig.Type.CONTINUOUS`](axis_config.md#type).

[`style`](#style) is created automatically at construction and is never `null`. All other properties default to `null` or an empty array. Assign an [`TauAxisConfig`](axis_config.md) to [`x_axis`](#x_axis) to configure the primary X axis. Leave it `null` to rely on built-in defaults. Populate [`panes`](#panes) with at least one [`TauPaneConfig`](pane_config.md) before passing the config to [`plot_xy()`](tau_plot.md#plot_xy).

After [`plot_xy()`](tau_plot.md#plot_xy) succeeds, the plot holds a reference to the `TauXYConfig` instance. Mutating it at runtime is supported, but requires calling [`TauPlot.queue_refresh()`](tau_plot.md#queue_refresh) to apply the changes.

### Example

```gdscript
var time_axis := TauAxisConfig.new()
time_axis.title = "Time (s)"

var pane := TauPaneConfig.new()
pane.y_left_axis = TauAxisConfig.new()

var config := TauXYConfig.new()
config.x_axis = time_axis
config.panes = [pane]
config.secondary_x_axis = TauAxisConfig.new()
config.secondary_x_axis_transform = func(c: float) -> float:
    return 1024.0 * c
```

## Constructor

### `new()`

```gdscript
TauXYConfig.new() -> TauXYConfig
```

Creates a new `TauXYConfig` with [`style`](#style) initialized to a default [`TauXYStyle`](xy_style.md), [`x_axis_id`](#x_axis_id) set to [`BOTTOM`](tau_plot.md#axisid), and all other properties set to `null` or empty.

## Properties

### x_axis_id

`x_axis_id`: [`AxisId`](tau_plot.md#axisid)

The position of the primary X axis. Default is [`BOTTOM`](tau_plot.md#axisid).

This value also controls the stacking direction of panes. [`BOTTOM`](tau_plot.md#axisid) and [`TOP`](tau_plot.md#axisid) produce vertical stacking. [`LEFT`](tau_plot.md#axisid) and [`RIGHT`](tau_plot.md#axisid) produce horizontal stacking.

---

### x_axis

`x_axis`: [`TauAxisConfig`](axis_config.md)

Configuration for the primary X axis, shared across all panes. Default is `null`.

If `null`, the axis uses built-in defaults for type, scale, domain, and ticks. Assign an [`TauAxisConfig`](axis_config.md) instance to control those parameters explicitly.

---

### secondary_x_axis

`secondary_x_axis`: [`TauAxisConfig`](axis_config.md)

Configuration for the secondary X axis, drawn at the position opposite [`x_axis_id`](#x_axis_id). Default is `null`, which means no secondary axis is drawn.

Only [`TauAxisConfig.Type.CONTINUOUS`](axis_config.md#type) is supported. When set, [`secondary_x_axis_transform`](#secondary_x_axis_transform) must also be assigned or [`plot_xy()`](tau_plot.md#plot_xy) aborts with a validation error. [`TauAxisConfig.include_zero_in_domain`](axis_config.md#include_zero_in_domain), [`TauAxisConfig.domain_padding_mode`](axis_config.md#domain_padding_mode), and [`TauAxisConfig.inverted`](axis_config.md#inverted) are ignored on this axis because its domain is derived from the primary through [`secondary_x_axis_transform`](#secondary_x_axis_transform).

---

### secondary_x_axis_transform

`secondary_x_axis_transform`: `Callable`

Transform from a primary X axis value to the corresponding secondary X axis value. Default is an invalid `Callable`.

Required when [`secondary_x_axis`](#secondary_x_axis) is not `null`. Omitting it is a validation error that causes [`plot_xy()`](tau_plot.md#plot_xy) to abort. The callable receives one `float` argument (the primary value) and must return a `float` (the secondary value). The transform may flip direction, for example `1.0 / x` for a frequency-to-period conversion.

```gdscript
# Celsius primary, Fahrenheit secondary.
config.secondary_x_axis_transform = func(t: float) -> float:
    return t * 1.8 + 32.0
```

---

### panes

`panes`: `Array[`[`TauPaneConfig`](pane_config.md)`]`

The ordered list of panes that make up the plot area. Default is `[]`.

Each entry defines one pane's Y axes, overlays, and stretch ratio. When [`x_axis_id`](#x_axis_id) is [`BOTTOM`](tau_plot.md#axisid) or [`TOP`](tau_plot.md#axisid), index `0` is the topmost pane. When it is [`LEFT`](tau_plot.md#axisid) or [`RIGHT`](tau_plot.md#axisid), index `0` is the leftmost pane. At least one [`TauPaneConfig`](pane_config.md) must be present for [`plot_xy()`](tau_plot.md#plot_xy) to succeed.

---

### style

`style`: [`TauXYStyle`](xy_style.md)

The visual style applied to the whole plot: axis colors, tick dimensions, label font, padding, pane spacing, and the series color palette. Default is a freshly constructed [`TauXYStyle`](xy_style.md) with all built-in defaults.

Never `null`. Modify properties directly on the instance. Any property left at its built-in default remains overridable by the active Godot theme.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Accepts `TauXYConfig` as the second argument of [`plot_xy()`](tau_plot.md#plot_xy).
* [`TauXYStyle`](xy_style.md) Owned by `TauXYConfig` via [`style`](#style). Controls plot-wide visual properties.
* [`TauPaneConfig`](pane_config.md) One entry in [`panes`](#panes). Defines a pane's Y axes and overlays.
* [`TauAxisConfig`](axis_config.md) Configures an individual axis. Used by [`x_axis`](#x_axis) and [`secondary_x_axis`](#secondary_x_axis).
* [`TauXYSeriesBinding`](xy_series_binding.md) Maps a dataset series to a pane, overlay, and Y axis. Passed alongside `TauXYConfig` to [`plot_xy()`](tau_plot.md#plot_xy).
* [`Dataset`](dataset.md) The data model passed to [`plot_xy()`](tau_plot.md#plot_xy) alongside `TauXYConfig`.
