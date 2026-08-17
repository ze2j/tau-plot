# BarVisualAttributes

!!! info ""
    **Inherits:** [`VisualAttributes`](visual_attributes.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)

Data-oriented per-sample style overrides for [`BAR`](tau_plot.md#paneoverlaytype) overlays.

## Description

`BarVisualAttributes` is the [`BAR`](tau_plot.md#paneoverlaytype) specific subclass of [`VisualAttributes`](visual_attributes.md). It carries the two **buffers** inherited from that base class, [`color_buffer`](visual_attributes.md#color_buffer) and [`alpha_buffer`](visual_attributes.md#alpha_buffer), and adds no overlay-specific buffers of its own.

Assign an instance to [`TauXYSeriesBinding.visual_attributes`](xy_series_binding.md#visual_attributes) when the binding targets a [`BAR`](tau_plot.md#paneoverlaytype) overlay. Any other subclass on such a binding is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts. The plot reads the buffers on each draw pass and applies the per-sample values on top of the per-series color and alpha resolved from [`TauXYStyle`](xy_style.md).

Each buffer is optional. A `null` buffer means no per-sample override for that property, and the resolved style value applies to every sample of the series. Partial buffers are supported: a sample index past the end of the buffer takes the resolved style value as well.

The two buffers reach the fill of a bar. Its shape comes from [`TauBarStyle.style_box`](bar_style.md#style_box), which only [`BarVisualCallbacks.style_box_callback`](bar_visual_callbacks.md#style_box_callback) overrides per sample.

See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for the order a buffer resolves in against a [`BarVisualCallbacks`](bar_visual_callbacks.md) callback and the style property.

### Example

```gdscript
# Color each bar individually by building a per-sample ColorBuffer.
var series_capacity := dataset.get_series_capacity(series_id)
var colors := TauPlot.ColorBuffer.new(series_capacity)
for i in series_capacity:
    colors.append_value(Color(0.2 + i * 0.1, 0.4, 0.8))

var attributes := TauPlot.BarVisualAttributes.new()
attributes.color_buffer = colors

var binding := TauXYSeriesBinding.new()
binding.pane_index = 0
binding.series_id = series_id
binding.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
binding.y_axis_id = TauPlot.AxisId.LEFT
binding.visual_attributes = attributes
```

## Constructor

### `new()`

```gdscript
BarVisualAttributes.new() -> BarVisualAttributes
```

Creates a new `BarVisualAttributes` instance with all buffers set to `null`.

## Related Classes

* [`VisualAttributes`](visual_attributes.md) Base class. Defines the inherited [`color_buffer`](visual_attributes.md#color_buffer) and [`alpha_buffer`](visual_attributes.md#alpha_buffer), their sentinels, and the partial buffer rule.
* [`TauXYSeriesBinding`](xy_series_binding.md) Owns the instance via its [`visual_attributes`](xy_series_binding.md#visual_attributes) property.
* [`BarVisualCallbacks`](bar_visual_callbacks.md) Companion class that computes the same properties at draw time rather than reading them from a buffer. Buffers take priority over callbacks.
* [`TauBarConfig`](bar_config.md) Configures the overlay the buffers are read for.
* [`TauBarStyle`](bar_style.md) Provides the resolved bar style values the buffers are applied on top of.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class of [`TauBarConfig`](bar_config.md). Defines how a per-sample override resolves against a callback and a style property.
* [`ScatterVisualAttributes`](scatter_visual_attributes.md) Sibling subclass for [`SCATTER`](tau_plot.md#paneoverlaytype) overlays.
* [`LineVisualAttributes`](line_visual_attributes.md) Sibling subclass for [`LINE`](tau_plot.md#paneoverlaytype) overlays.
* [`ColorBuffer`](color_buffer.md) Ring buffer storing `Color` values, used by [`color_buffer`](visual_attributes.md#color_buffer).
* [`Float32Buffer`](float32_buffer.md) Ring buffer storing `float` values (32-bit), used by [`alpha_buffer`](visual_attributes.md#alpha_buffer).
* [`TauXYStyle`](xy_style.md) Provides the per-series color and alpha a sample falls back to.
* [`Dataset`](dataset.md) The data model. Its logical sample index is the index a buffer is read by.