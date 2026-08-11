# TauPaneOverlayConfig

!!! info ""
    **Inherits:** `Resource`  
    **Inherited By:** [`TauBarConfig`](bar_config.md), [`TauScatterConfig`](scatter_config.md), [`TauLineConfig`](line_config.md)  

**Abstract class** for overlay configurations rendered inside a pane.

## Description

`TauPaneOverlayConfig` is the base class for the overlay configuration objects placed in [`TauPaneConfig.overlays`](pane_config.md#overlays). The three concrete subclasses are [`TauBarConfig`](bar_config.md) for bar overlays, [`TauScatterConfig`](scatter_config.md) for scatter overlays, and [`TauLineConfig`](line_config.md) for line overlays. A pane holds at most one overlay of each type. More than one is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts.

The base class carries what every overlay type has in common: the draw order of the series inside the overlay, whether its samples take part in hover hit testing, and the per-sample overrides described below. The subclass decides how samples are painted and carries the properties that only that kind of drawing has, including the style resource.

### Per-sample overrides

Some properties can be overridden per sample, through one of two mechanisms.

**Visual attributes** are buffers handed to the plot with the data, holding the value of one property indexed by sample index. The values are normally precomputed, which is what the mechanism is for. Writing them at runtime works as well, and leaves the caller responsible for keeping them in step with the [`Dataset`](dataset.md). See [`TauXYSeriesBinding.visual_attributes`](xy_series_binding.md#visual_attributes).

**Visual callbacks** are functions handed to the plot, called once per sample while the pane is drawn, and returning the value of one property for that sample. Each one receives the series index, the sample index, and the X and Y values of the sample, so the value can be derived from the sample itself. See [`visual_callbacks`](#visual_callbacks).

The plot reads the buffer first. If the buffer holds no value for a sample, the plot calls the callback. If the callback returns no value either, the plot uses the property. A `null` buffer, a buffer shorter than the sample count, an invalid entry, an unassigned callback, and an invalid return all count as no value.

Each subclass exposes a typed accessor that reads and writes [`visual_callbacks`](#visual_callbacks) as its own concrete type: [`bar_visual_callbacks`](bar_config.md#bar_visual_callbacks), [`scatter_visual_callbacks`](scatter_config.md#scatter_visual_callbacks), and [`line_visual_callbacks`](line_config.md#line_visual_callbacks).

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

1. **`overlay_type` is set by the subclass.** [`TauBarConfig`](bar_config.md) sets it to [`BAR`](tau_plot.md#paneoverlaytype), [`TauScatterConfig`](scatter_config.md) sets it to [`SCATTER`](tau_plot.md#paneoverlaytype), and [`TauLineConfig`](line_config.md) sets it to [`LINE`](tau_plot.md#paneoverlaytype) at construction. Do not assign this property manually.

## Enums

### `ZOrder`

Controls the order in which series are drawn within the overlay.

| Value | Meaning |
|---|---|
| `SERIES_ORDER` | Series are drawn in dataset order. The last series of the overlay is drawn on top. |
| `REVERSE_SERIES_ORDER` | Series are drawn in reverse dataset order. The first series of the overlay is drawn on top. |

## Properties

### overlay_type

`overlay_type`: [`PaneOverlayType`](tau_plot.md#paneoverlaytype)

The type of overlay this configuration instance describes. [`TauBarConfig`](bar_config.md) sets it to [`BAR`](tau_plot.md#paneoverlaytype), [`TauScatterConfig`](scatter_config.md) sets it to [`SCATTER`](tau_plot.md#paneoverlaytype), and [`TauLineConfig`](line_config.md) sets it to [`LINE`](tau_plot.md#paneoverlaytype). Read only, for reflection purposes (see [note 1](#notes)).

---

### z_order

`z_order`: [`ZOrder`](#zorder)

The draw order for series within the overlay. Default is [`REVERSE_SERIES_ORDER`](#zorder).

Controls which series covers which where the series of this overlay overlap. The order applies to the series bound to this overlay, sorted by dataset series index. [`SERIES_ORDER`](#zorder) draws them from the lowest dataset index up, placing the last series of the overlay on top. [`REVERSE_SERIES_ORDER`](#zorder) draws them from the highest dataset index down, placing the first series of the overlay on top.

---

### visual_callbacks

`visual_callbacks`: [`VisualCallbacks`](visual_callbacks.md)

Per-sample visual callbacks attached to this overlay. Default is `null`.

The instance must be the callbacks subclass matching the overlay type: [`BarVisualCallbacks`](bar_visual_callbacks.md) on a bar overlay, [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) on a scatter overlay, and [`LineVisualCallbacks`](line_visual_callbacks.md) on a line overlay. Any other type is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts.

`visual_callbacks` is not serializable. The property is not exported and cannot be saved in a `.tres` resource file. Assign it at runtime only.

---

### hoverable

`hoverable`: `bool`

Controls whether samples in this overlay participate in hover hit testing. Default is `true`.

When `false`, the overlay is invisible to the hover system. No hover signals fire, no tooltip appears, and no highlight renders for any sample in this overlay. The overlay is also left out of the [`AUTO`](hover_config.md#hovermode) resolution that derives the hover mode of a pane from its overlay composition.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauPaneOverlayConfig` instances when building the plot.
* [`TauPaneConfig`](pane_config.md) Holds the list of overlay configurations via its [`overlays`](pane_config.md#overlays) property.
* [`TauBarConfig`](bar_config.md) Concrete subclass for bar overlays.
* [`TauScatterConfig`](scatter_config.md) Concrete subclass for scatter overlays.
* [`TauLineConfig`](line_config.md) Concrete subclass for line overlays.
* [`TauAxisConfig`](axis_config.md) Configures the axes of the pane an overlay is drawn in.
* [`Dataset`](dataset.md) The data model. Passed to [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) and indexed by the per-sample override mechanisms.
* [`TauXYSeriesBinding`](xy_series_binding.md) Maps a series of the dataset to an overlay, and holds the per-sample [`visual_attributes`](xy_series_binding.md#visual_attributes) buffers.
* [`VisualCallbacks`](visual_callbacks.md) Base class for per-sample visual callbacks, assigned to [`visual_callbacks`](#visual_callbacks).
* [`BarVisualCallbacks`](bar_visual_callbacks.md) Typed callbacks for bar overlays, assigned through [`TauBarConfig.bar_visual_callbacks`](bar_config.md#bar_visual_callbacks).
* [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) Typed callbacks for scatter overlays, assigned through [`TauScatterConfig.scatter_visual_callbacks`](scatter_config.md#scatter_visual_callbacks).
* [`LineVisualCallbacks`](line_visual_callbacks.md) Typed callbacks for line overlays, assigned through [`TauLineConfig.line_visual_callbacks`](line_config.md#line_visual_callbacks).
* [`TauHoverConfig`](hover_config.md) Holds the hover mode that [`hoverable`](#hoverable) takes an overlay out of.
* [`TauXYStyle`](xy_style.md) Holds the series color cycle applied when no per-sample override supplies a color.