# TauXYSeriesBinding

!!! info ""
    **Inherits:** `Resource`

Maps one dataset series to a pane, an overlay type, and a Y axis in an XY plot.

## Description

`TauXYSeriesBinding` is the connection object between a [`Dataset`](dataset.md) series and its visual representation inside the plot. An array of bindings is passed as the third argument to [`TauPlot.plot_xy()`](tau_plot.md#plot_xy). Each binding specifies which series to render, in which pane, through which overlay, and against which Y axis.

Four properties define the mapping:

- [`series_id`](#series_id) identifies the series in the dataset. 
- [`pane_index`](#pane_index) selects the pane by its position in [`TauXYConfig.panes`](xy_config.md#panes).
- [`overlay_type`](#overlay_type) selects the visual layer: [`BAR`](tau_plot.md#paneoverlaytype), [`SCATTER`](tau_plot.md#paneoverlaytype), or [`LINE`](tau_plot.md#paneoverlaytype). 
- [`y_axis_id`](#y_axis_id) selects the Y axis. That axis must be orthogonal to the X axis set in [`TauXYConfig.x_axis_id`](xy_config.md#x_axis_id), and the corresponding axis slot must be populated in the target pane.

A series can appear in multiple bindings. It may be rendered in different panes or through different overlay types, for example once as a line and once as scatter markers within the same pane. The only constraints are:
- The same series cannot be bound to the same overlay type in the same pane more than once.
- A series in one pane must reference the same Y axis across all its bindings for that pane.

[`show_in_legend`](#show_in_legend) decides whether this binding contributes a key to the legend. The flag is per binding, so a series drawn by two overlays can show a key for one of them and not the other.

The optional [`visual_attributes`](#visual_attributes) property carries per-sample style overrides. When set, the plot reads its buffers by sample index and they take precedence over the values resolved from the style resources, as described in [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides). The instance must be of the subclass matching the overlay type: [`BarVisualAttributes`](bar_visual_attributes.md) for [`BAR`](tau_plot.md#paneoverlaytype), [`ScatterVisualAttributes`](scatter_visual_attributes.md) for [`SCATTER`](tau_plot.md#paneoverlaytype), and [`LineVisualAttributes`](line_visual_attributes.md) for [`LINE`](tau_plot.md#paneoverlaytype).

All four required properties are validated when [`plot_xy()`](tau_plot.md#plot_xy) is called. Binding errors abort the call without modifying the current plot.

### Example

```gdscript
# Price as a curve in pane 0, volume as bars in pane 1.
var sb_price := TauXYSeriesBinding.new()
sb_price.series_id = dataset.get_series_id_by_index(0)
sb_price.pane_index = 0
sb_price.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
sb_price.y_axis_id = TauPlot.AxisId.LEFT

var sb_volume := TauXYSeriesBinding.new()
sb_volume.series_id = dataset.get_series_id_by_index(1)
sb_volume.pane_index = 1
sb_volume.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
sb_volume.y_axis_id = TauPlot.AxisId.LEFT
# The volume series does not appear in the legend.
sb_volume.show_in_legend = false

%MyPlot.plot_xy(dataset, config, [sb_price, sb_volume])
```

## Constructor

### `new()`

```gdscript
TauXYSeriesBinding.new() -> TauXYSeriesBinding
```

Creates a new `TauXYSeriesBinding` with all properties set to their built-in defaults. Assign at least [`series_id`](#series_id), [`pane_index`](#pane_index), [`overlay_type`](#overlay_type), and [`y_axis_id`](#y_axis_id) before passing the instance to [`TauPlot.plot_xy()`](tau_plot.md#plot_xy).

## Properties

### series_id

`series_id`: `int`

The series ID of the series to render. Default is `0`.

Must match a series ID present in the [`Dataset`](dataset.md) passed to [`plot_xy()`](tau_plot.md#plot_xy). Obtain valid IDs from [`Dataset`](dataset.md) methods such as `get_series_id_by_index()`. If the ID does not exist in the dataset, [`plot_xy()`](tau_plot.md#plot_xy) logs an error and aborts.

---

### pane_index

`pane_index`: `int`

The zero-based index of the target pane within [`TauXYConfig.panes`](xy_config.md#panes). Default is `0`.

Selects which pane the series is rendered in. If the index is out of range, [`plot_xy()`](tau_plot.md#plot_xy) logs an error and aborts.

---

### overlay_type

`overlay_type`: [`PaneOverlayType`](tau_plot.md#paneoverlaytype)

The overlay type used to render the series. Default is [`BAR`](tau_plot.md#paneoverlaytype).

One of [`BAR`](tau_plot.md#paneoverlaytype), [`SCATTER`](tau_plot.md#paneoverlaytype), or [`LINE`](tau_plot.md#paneoverlaytype). The selected overlay type must be present in the target pane's [`TauPaneConfig.overlays`](pane_config.md#overlays) list.

---

### y_axis_id

`y_axis_id`: [`AxisId`](tau_plot.md#axisid)

The Y axis this series is plotted against. Default is [`LEFT`](tau_plot.md#axisid).

Must be orthogonal to the X axis position configured by [`TauXYConfig.x_axis_id`](xy_config.md#x_axis_id). The axis slot selected by this value must also be populated in the target pane. Violation is a validation error.

---

### show_in_legend

`show_in_legend`: `bool`

If `true`, this binding contributes a key to the legend. Default is `true`.

The legend holds one entry per series, and a series appears as soon as one of its bindings opts in. A series bound to several overlays contributes one key per opted-in binding, so setting this to `false` on one of them drops that key and keeps the entry. Setting it to `false` on all of them drops the entry. Has no effect while [`TauPlot.legend_enabled`](tau_plot.md#legend_enabled) is `false`.

---

### visual_attributes

`visual_attributes`: [`VisualAttributes`](visual_attributes.md)

Optional per-sample style overrides for this series. Default is `null`.

When `null`, all samples use the uniform style resolved from the active style resources. When set, the plot reads the buffers by sample index and applies them on top of the resolved style values, in the order described in [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides). The instance must be the subclass corresponding to [`overlay_type`](#overlay_type): [`BarVisualAttributes`](bar_visual_attributes.md) for [`BAR`](tau_plot.md#paneoverlaytype), [`ScatterVisualAttributes`](scatter_visual_attributes.md) for [`SCATTER`](tau_plot.md#paneoverlaytype), and [`LineVisualAttributes`](line_visual_attributes.md) for [`LINE`](tau_plot.md#paneoverlaytype). Any other type is a validation error.

`visual_attributes` is not serializable. The property is not exported and cannot be saved in a `.tres` resource file. Assign it at runtime only.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Accepts bindings as the third argument of [`plot_xy()`](tau_plot.md#plot_xy).
* [`Dataset`](dataset.md) Source of the series referenced by [`series_id`](#series_id).
* [`TauXYConfig`](xy_config.md) Defines the pane list that [`pane_index`](#pane_index) indexes into, and the X axis position that constrains [`y_axis_id`](#y_axis_id).
* [`TauPaneConfig`](pane_config.md) Defines the Y axis slots and overlay types available in the target pane.
* [`VisualAttributes`](visual_attributes.md) Abstract base class for per-sample style override buffers, assigned to [`visual_attributes`](#visual_attributes).
* [`BarVisualAttributes`](bar_visual_attributes.md) Required subclass of [`VisualAttributes`](visual_attributes.md) when [`overlay_type`](#overlay_type) is [`BAR`](tau_plot.md#paneoverlaytype).
* [`ScatterVisualAttributes`](scatter_visual_attributes.md) Required subclass of [`VisualAttributes`](visual_attributes.md) when [`overlay_type`](#overlay_type) is [`SCATTER`](tau_plot.md#paneoverlaytype).
* [`LineVisualAttributes`](line_visual_attributes.md) Required subclass of [`VisualAttributes`](visual_attributes.md) when [`overlay_type`](#overlay_type) is [`LINE`](tau_plot.md#paneoverlaytype).
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class of the overlay configurations. Defines how a per-sample override resolves against a callback and a style property.
* [`TauLegendConfig`](legend_config.md) Configures the legend that [`show_in_legend`](#show_in_legend) feeds.