# ScatterVisualAttributes

!!! info ""
    **Inherits:** [`VisualAttributes`](visual_attributes.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)
    
Data-oriented per-sample style overrides for [`SCATTER`](tau_plot.md#paneoverlaytype) overlays.

## Description

`ScatterVisualAttributes` is the [`SCATTER`](tau_plot.md#paneoverlaytype) specific subclass of [`VisualAttributes`](visual_attributes.md). It carries the two buffers inherited from that base class, [`color_buffer`](visual_attributes.md#color_buffer) and [`alpha_buffer`](visual_attributes.md#alpha_buffer), and adds four scatter-specific buffers: [`size_buffer`](#size_buffer), [`shape_buffer`](#shape_buffer), [`outline_color_buffer`](#outline_color_buffer), and [`outline_width_buffer`](#outline_width_buffer).

Assign an instance to [`TauXYSeriesBinding.visual_attributes`](xy_series_binding.md#visual_attributes) when the binding targets a [`SCATTER`](tau_plot.md#paneoverlaytype) overlay. The renderer reads the buffers during each draw pass and applies per-sample overrides on top of the values resolved from [`TauScatterStyle`](scatter_style.md) and [`TauXYStyle`](xy_style.md).

Each buffer is optional. A `null` buffer means no per-sample override for that property, and the resolved style value applies to every sample in the series. Partial buffers are supported: for any sample index past the end of the buffer, the resolved style value applies.

### Example

```gdscript
# Size each marker individually by building a per-sample Float32Buffer.
var series_capacity := TauPlot.dataset.get_series_capacity(series_id)
var marker_sizes := TauPlot.Float32Buffer.new(series_capacity)
for i in series_capacity:
	marker_sizes.append_value(8.0 + i * 0.5)

var attributes := TauPlot.ScatterVisualAttributes.new()
attributes.size_buffer = marker_sizes

var binding := TauXYSeriesBinding.new()
binding.pane_index = 0
binding.series_id = series_id
binding.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
binding.y_axis_id = TauPlot.AxisId.LEFT
binding.visual_attributes = attributes
```

## Constructor

### `new()`

```gdscript
ScatterVisualAttributes.new() -> ScatterVisualAttributes
```

Creates a new `ScatterVisualAttributes` instance with all buffers set to `null`.

## Properties

### size_buffer

`size_buffer`: [`Float32Buffer`](float32_buffer.md)

The per-sample marker size buffer. Default is `null`.

If `null`, the marker size for every sample comes from [`TauScatterStyle.marker_size_px`](scatter_style.md#marker_size_px). If set, each entry overrides the marker size in pixels of the sample at the same index. A negative entry is treated as unset and falls through to the resolved style size. Entries beyond the series length are ignored. Samples beyond the buffer length fall through to the resolved style size.

---

### shape_buffer

`shape_buffer`: [`Int32Buffer`](int32_buffer.md)

The per-sample marker shape buffer. Default is `null`.

If `null`, the shape for every sample comes from [`TauScatterStyle.marker_shapes`](scatter_style.md#marker_shapes). If set, each entry must be a valid [`MarkerShape`](scatter_style.md#markershape) enum value. An entry of `-1` is treated as unset and falls through to the resolved style shape. `-1` is therefore not a valid override shape. Entries beyond the series length are ignored. Samples beyond the buffer length fall through to the resolved style shape.

---

### outline_color_buffer

`outline_color_buffer`: [`ColorBuffer`](color_buffer.md)

The per-sample outline color buffer. Default is `null`.

If `null`, the outline color for every sample comes from [`TauScatterStyle.outline_color`](scatter_style.md#outline_color). If set, each entry overrides the outline color of the sample at the same index. An entry equal to `Color(0, 0, 0, 0)` is treated as unset and falls through to the resolved style outline color. `Color(0, 0, 0, 0)` is therefore not a valid override outline color. Entries beyond the series length are ignored. Samples beyond the buffer length fall through to the resolved style outline color.

---

### outline_width_buffer

`outline_width_buffer`: [`Float32Buffer`](float32_buffer.md)

The per-sample outline width buffer. Default is `null`.

If `null`, the outline width for every sample comes from [`TauScatterStyle.outline_width_px`](scatter_style.md#outline_width_px). If set, each entry overrides the outline stroke width in pixels of the sample at the same index. A negative entry is treated as unset and falls through to the resolved style outline width. Valid override values are `0.0` or greater, where `0.0` disables the outline for that sample. Entries beyond the series length are ignored. Samples beyond the buffer length fall through to the resolved style outline width.

## Related Classes

* [`VisualAttributes`](visual_attributes.md) Base class. Defines the inherited [`color_buffer`](visual_attributes.md#color_buffer) and [`alpha_buffer`](visual_attributes.md#alpha_buffer).
* [`TauXYSeriesBinding`](xy_series_binding.md) Owns the instance via its [`visual_attributes`](xy_series_binding.md#visual_attributes) property.
* [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) Companion class that computes the same properties from a callback rather than a buffer.
* [`TauScatterStyle`](scatter_style.md) Provides the resolved scatter style values that buffers override.
* [`BarVisualAttributes`](bar_visual_attributes.md) Sibling subclass for [`BAR`](tau_plot.md#paneoverlaytype) overlays.
* [`Float32Buffer`](float32_buffer.md) Ring buffer storing `float` values (32-bit), used by [`size_buffer`](#size_buffer) and [`outline_width_buffer`](#outline_width_buffer).
* [`Int32Buffer`](int32_buffer.md) Ring buffer storing `int` values (32-bit), used by [`shape_buffer`](#shape_buffer).
* [`ColorBuffer`](color_buffer.md) Ring buffer storing `Color` values, used by [`outline_color_buffer`](#outline_color_buffer).
