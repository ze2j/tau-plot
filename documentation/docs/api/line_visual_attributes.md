# LineVisualAttributes

!!! info ""
    **Inherits:** [`VisualAttributes`](visual_attributes.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)

Data-oriented per-sample style overrides for [`LINE`](tau_plot.md#paneoverlaytype) overlays.

## Description

`LineVisualAttributes` is the [`LINE`](tau_plot.md#paneoverlaytype) specific subclass of [`VisualAttributes`](visual_attributes.md). It carries the two **buffers** inherited from that base class, [`color_buffer`](visual_attributes.md#color_buffer) and [`alpha_buffer`](visual_attributes.md#alpha_buffer), and adds no overlay-specific buffers of its own.

Assign an instance to [`TauXYSeriesBinding.visual_attributes`](xy_series_binding.md#visual_attributes) when the binding targets a [`LINE`](tau_plot.md#paneoverlaytype) overlay. Any other subclass on such a binding is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts. The plot reads the buffers on each draw pass and applies the per-sample values on top of the per-series color and alpha resolved from [`TauXYStyle`](xy_style.md).

Each buffer is optional. A `null` buffer means no per-sample override for that property, and the resolved style value applies to every sample in the series. Partial buffers are supported: for any sample index past the end of the buffer, the resolved style value applies.

The two buffers override the stroke of the curve. The area painted around it takes its color from [`TauLineFill`](line_fill.md) and is left untouched.

See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for the order a buffer resolves in against a [`LineVisualCallbacks`](line_visual_callbacks.md) callback and the style property.

### Example

```gdscript
# Fade the oldest samples of a live series by writing a per-sample alpha.
var capacity := dataset.get_series_capacity(series_id)
var alphas := TauPlot.Float32Buffer.new(capacity)
for i in capacity:
    alphas.append_value(float(i + 1) / float(capacity))

var attributes := TauPlot.LineVisualAttributes.new()
attributes.alpha_buffer = alphas

var binding := TauXYSeriesBinding.new()
binding.pane_index = 0
binding.series_id = series_id
binding.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
binding.y_axis_id = TauPlot.AxisId.LEFT
binding.visual_attributes = attributes
```

### Notes

1. **A per-sample color colors a sample, not a segment.** Each sample carries its own color into the curve, and the segment between two samples fades from the color of one to the color of the other. No [interpolation mode](line_config.md#interpolation_modes) makes the change abrupt, since the fade follows the drawn path whatever its shape.

## Constructor

### `new()`

```gdscript
LineVisualAttributes.new() -> LineVisualAttributes
```

Creates a new `LineVisualAttributes` instance with all buffers set to `null`.

## Related Classes

* [`VisualAttributes`](visual_attributes.md) Base class. Defines the inherited [`color_buffer`](visual_attributes.md#color_buffer) and [`alpha_buffer`](visual_attributes.md#alpha_buffer).
* [`TauXYSeriesBinding`](xy_series_binding.md) Owns the instance via its [`visual_attributes`](xy_series_binding.md#visual_attributes) property.
* [`LineVisualCallbacks`](line_visual_callbacks.md) Companion class that computes the same properties from a callback rather than a buffer. Buffers take priority over callbacks.
* [`TauLineConfig`](line_config.md) Configures the overlay the buffers are read for.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class of [`TauLineConfig`](line_config.md). Defines how a per-sample override resolves against a callback and a style property.
* [`TauLineStyle`](line_style.md) Provides the resolved line style values the buffers are applied on top of.
* [`TauLineFill`](line_fill.md) Paints the area around the curve, which the buffers do not reach.
* [`TauXYStyle`](xy_style.md) Provides the per-series color and alpha a sample falls back to.
* [`BarVisualAttributes`](bar_visual_attributes.md) Sibling subclass for [`BAR`](tau_plot.md#paneoverlaytype) overlays.
* [`ScatterVisualAttributes`](scatter_visual_attributes.md) Sibling subclass for [`SCATTER`](tau_plot.md#paneoverlaytype) overlays.
* [`ColorBuffer`](color_buffer.md) Ring buffer storing `Color` values, used by [`color_buffer`](visual_attributes.md#color_buffer).
* [`Float32Buffer`](float32_buffer.md) Ring buffer storing `float` values (32-bit), used by [`alpha_buffer`](visual_attributes.md#alpha_buffer).
* [`Dataset`](dataset.md) The data model. Its logical sample index is the index the buffers are read by.