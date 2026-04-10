# TauPaneOverlayConfig

!!! info ""
    **Inherits:** `Resource`  
    **Inherited By:** [`TauBarConfig`](bar_config.md), [`TauScatterConfig`](scatter_config.md) 
    
**Abstract class** for overlay configurations rendered inside a pane.

## Description

`TauPaneOverlayConfig` is the base class for overlay configuration objects placed in [`TauPaneConfig.overlays`](pane_config.md#overlays). It is never instantiated directly. The two concrete subclasses are [`TauBarConfig`](bar_config.md), which configures bar overlays, and [`TauScatterConfig`](scatter_config.md), which configures scatter overlays.

Properties defined on `TauPaneOverlayConfig` apply to every overlay type. [`z_order`](#z_order) controls the draw order of series within the overlay. [`hoverable`](#hoverable) controls whether samples in the overlay participate in hover hit testing. [`visual_callbacks`](#visual_callbacks) attaches per-sample computed rendering properties. [`overlay_type`](#overlay_type) identifies the overlay type and is set automatically by each concrete subclass at construction.

[visual_callbacks](#visual_callbacks) provides a callback-driven way to override style properties per sample at draw time. This property can also be accessed through a typed accessor: [`TauBarConfig`](bar_config.md) exposes [`bar_visual_callbacks`](bar_config.md#bar_visual_callbacks) and [`TauScatterConfig`](scatter_config.md) exposes [`scatter_visual_callbacks`](scatter_config.md#scatter_visual_callbacks).

After [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) succeeds, the plot holds a reference to every `TauPaneOverlayConfig` instance it received. Mutating a property at runtime is supported, but requires calling [`TauPlot.queue_refresh()`](tau_plot.md#queue_refresh) to apply the change.

### Example

```gdscript
# Create a BAR overlay
var bar := TauBarConfig.new()
bar.z_order = TauPaneOverlayConfig.ZOrder.SERIES_ORDER
bar.hoverable = false

var pane := TauPaneConfig.new()
pane.y_left_axis = TauAxisConfig.new()
pane.overlays = [bar]
```

### Notes

1. **`overlay_type` is set by the subclass.** [`TauBarConfig`](bar_config.md) sets it to [`BAR`](tau_plot.md#paneoverlaytype) and [`TauScatterConfig`](scatter_config.md) sets it to [`SCATTER`](tau_plot.md#paneoverlaytype) at construction. Do not assign this property manually.

2. **`visual_callbacks` is not serializable.** The property is not exported and cannot be saved in a `.tres` resource file. Assign it at runtime only. Use the typed accessor on the concrete subclass ([`bar_visual_callbacks`](bar_config.md#bar_visual_callbacks) on [`TauBarConfig`](bar_config.md), [`scatter_visual_callbacks`](scatter_config.md#scatter_visual_callbacks) on [`TauScatterConfig`](scatter_config.md)).

## Enums

### `ZOrder`

Controls the order in which series are drawn within the overlay.

| Value | Meaning |
|---|---|
| `SERIES_ORDER` | Series are drawn in dataset order from index `0` to `N-1`. The last series in the dataset is drawn on top. |
| `REVERSE_SERIES_ORDER` | Series are drawn in reverse dataset order. The first series in the dataset is drawn on top. |

## Properties

### overlay_type

`overlay_type`: [`PaneOverlayType`](tau_plot.md#paneoverlaytype)

The type of overlay this configuration instance describes. [`TauBarConfig`](bar_config.md) sets it to [`BAR`](tau_plot.md#paneoverlaytype) and [`TauScatterConfig`](scatter_config.md) sets it to [`SCATTER`](tau_plot.md#paneoverlaytype). Intended for lookup purposes only (see [note 1](#notes)).

---

### z_order

`z_order`: [`ZOrder`](#zorder)

The draw order for series within the overlay. Default is [`REVERSE_SERIES_ORDER`](#zorder).

Controls which series appears on top when markers or bars at the same X position overlap. [`SERIES_ORDER`](#zorder) draws series from index `0` to `N-1`, placing the last series on top. [`REVERSE_SERIES_ORDER`](#zorder) draws series from index `N-1` down to `0`, placing the first series on top.

---

### visual_callbacks

`visual_callbacks`: [`VisualCallbacks`](visual_callbacks.md)

Per-sample visual callbacks attached to this overlay. Default is `null`.

---

### hoverable

`hoverable`: `bool`

Controls whether samples in this overlay participate in hover hit testing. Default is `true`.

When `false`, the overlay is invisible to the hover system. No hover signals fire, no tooltip appears, and no highlight renders for any sample in this overlay.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauPaneOverlayConfig` instances when building the plot.
* [`TauPaneConfig`](pane_config.md) Holds the list of overlay configurations via its [`overlays`](pane_config.md#overlays) property.
* [`TauBarConfig`](bar_config.md) Concrete subclass for bar overlays.
* [`TauScatterConfig`](scatter_config.md) Concrete subclass for scatter overlays.
* [`VisualCallbacks`](visual_callbacks.md) Base class for per-sample visual callbacks, assigned to [`visual_callbacks`](#visual_callbacks).
* [`BarVisualCallbacks`](bar_visual_callbacks.md) Typed callbacks for bar overlays, assigned through [`TauBarConfig.bar_visual_callbacks`](bar_config.md#bar_visual_callbacks).
* [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) Typed callbacks for scatter overlays, assigned through [`TauScatterConfig.scatter_visual_callbacks`](scatter_config.md#scatter_visual_callbacks).
* [`TauXYStyle`](xy_style.md) Provides the series color palette applied when `visual_callbacks` is `null`.
