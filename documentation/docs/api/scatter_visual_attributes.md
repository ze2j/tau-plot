# ScatterVisualAttributes

!!! info ""
    **Inherits:** [`VisualAttributes`](visual_attributes.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)

Data-oriented per-sample style overrides for [`SCATTER`](tau_plot.md#paneoverlaytype) overlays.

## Description

`ScatterVisualAttributes` is the [`SCATTER`](tau_plot.md#paneoverlaytype) specific subclass of [`VisualAttributes`](visual_attributes.md). It carries the two **buffers** inherited from that base class, [`color_buffer`](visual_attributes.md#color_buffer) and [`alpha_buffer`](visual_attributes.md#alpha_buffer), and adds four scatter-specific buffers: [`size_buffer`](#size_buffer), [`shape_buffer`](#shape_buffer), [`outline_color_buffer`](#outline_color_buffer), and [`outline_width_buffer`](#outline_width_buffer).

Assign an instance to [`TauXYSeriesBinding.visual_attributes`](xy_series_binding.md#visual_attributes) when the binding targets a [`SCATTER`](tau_plot.md#paneoverlaytype) overlay. Any other subclass on such a binding is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts. The plot reads the buffers on each draw pass and applies the per-sample values on top of the values resolved from [`TauScatterStyle`](scatter_style.md) and [`TauXYStyle`](xy_style.md).

Each buffer is optional. A `null` buffer means no per-sample override for that property, and the resolved style value applies to every sample of the series. Partial buffers are supported: a sample index past the end of the buffer takes the resolved style value as well.

The emphasized marker takes the hovered-state properties of [`TauScatterStyle`](scatter_style.md), so [`size_buffer`](#size_buffer), [`outline_color_buffer`](#outline_color_buffer), and [`outline_width_buffer`](#outline_width_buffer) shape every marker except that one.

See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for the order a buffer resolves in against a [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) callback and the style property.

### Example

```gdscript
# Size each marker individually by building a per-sample Float32Buffer.
var series_capacity := dataset.get_series_capacity(series_id)
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

Buffer holding the marker size of each sample. Default is `null`.

An entry overrides the size of the marker at the same index, taking priority over [`TauScatterStyle.marker_sizes_px`](scatter_style.md#marker_sizes_px). A negative entry is treated as unset. The unit follows the active [`TauScatterConfig.marker_size_policy`](scatter_config.md#marker_size_policy): pixels under [`THEME`](scatter_config.md#markersizepolicy), X data units under [`DATA_UNITS`](scatter_config.md#markersizepolicy), where the drawn size then changes with the X domain.

The resolved pixel size is raised to `1.0`, so an entry of `0.0` draws a one pixel marker rather than hiding one. Hide a marker through [`shape_buffer`](#shape_buffer) instead.

Under [`DATA_UNITS`](scatter_config.md#markersizepolicy) on a [categorical](axis_config.md#type-enum) X axis there is no data span to convert, and the entry is not read at all: the size comes from [`TauScatterStyle.marker_sizes_px`](scatter_style.md#marker_sizes_px), with no error and no warning.

---

### shape_buffer

`shape_buffer`: [`Int32Buffer`](int32_buffer.md)

Buffer holding the marker shape of each sample. Default is `null`.

An entry overrides the shape of the marker at the same index, taking priority over [`TauScatterStyle.marker_shapes`](scatter_style.md#marker_shapes). A negative entry is treated as unset. Valid override values are the [`TauScatterStyle.MarkerShape`](scatter_style.md#markershape) members as integers, and any other positive entry draws a [`CIRCLE`](scatter_style.md#markershape) with no message, since the buffer is read once per sample.

An entry of [`NONE`](scatter_style.md#markershape) draws nothing for that sample. A sample that draws nothing is also left out of hover hit testing, so it reports no [`SampleHit`](sample_hit.md) and never appears in a tooltip.

---

### outline_color_buffer

`outline_color_buffer`: [`ColorBuffer`](color_buffer.md)

Buffer holding the color of the outline stroked around each marker. Default is `null`.

An entry overrides the outline color of the marker at the same index, taking priority over [`TauScatterStyle.outline_color`](scatter_style.md#outline_color). An entry equal to [`ColorBuffer.NO_COLOR`](color_buffer.md) is treated as unset, see [note 1](visual_attributes.md#notes) on the base class.

The resolved alpha of the sample is applied on top of the entry, so a marker and its outline fade together.

---

### outline_width_buffer

`outline_width_buffer`: [`Float32Buffer`](float32_buffer.md)

Buffer holding the thickness in pixels of the outline stroked around each marker. Default is `null`.

An entry overrides the outline width of the marker at the same index, taking priority over [`TauScatterStyle.outline_width_px`](scatter_style.md#outline_width_px). A negative entry is treated as unset. Valid override values are `0.0` or greater, where `0.0` leaves that marker unoutlined, and the drawn outline never exceeds half the resolved marker size.

## Related Classes

* [`VisualAttributes`](visual_attributes.md) Base class. Defines the inherited [`color_buffer`](visual_attributes.md#color_buffer) and [`alpha_buffer`](visual_attributes.md#alpha_buffer), their sentinels, and the partial buffer rule.
* [`TauXYSeriesBinding`](xy_series_binding.md) Owns the instance via its [`visual_attributes`](xy_series_binding.md#visual_attributes) property.
* [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) Companion class that computes the same properties at draw time rather than reading them from a buffer. Buffers take priority over callbacks.
* [`TauScatterConfig`](scatter_config.md) Configures the overlay the buffers are read for. Its [`marker_size_policy`](scatter_config.md#marker_size_policy) decides the unit of a [`size_buffer`](#size_buffer) entry.
* [`TauScatterStyle`](scatter_style.md) Provides the resolved scatter style values the buffers are applied on top of, including the hovered-state properties that win over them.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class of [`TauScatterConfig`](scatter_config.md). Defines how a per-sample override resolves against a callback and a style property.
* [`TauAxisConfig`](axis_config.md) Configures the X axis whose type decides whether a [`DATA_UNITS`](scatter_config.md#markersizepolicy) size is converted or discarded.
* [`SampleHit`](sample_hit.md) Reports one hovered sample. A marker hidden through [`shape_buffer`](#shape_buffer) produces none.
* [`BarVisualAttributes`](bar_visual_attributes.md) Sibling subclass for [`BAR`](tau_plot.md#paneoverlaytype) overlays.
* [`LineVisualAttributes`](line_visual_attributes.md) Sibling subclass for [`LINE`](tau_plot.md#paneoverlaytype) overlays.
* [`Float32Buffer`](float32_buffer.md) Ring buffer storing `float` values (32-bit), used by [`size_buffer`](#size_buffer) and [`outline_width_buffer`](#outline_width_buffer).
* [`Int32Buffer`](int32_buffer.md) Ring buffer storing `int` values (32-bit), used by [`shape_buffer`](#shape_buffer).
* [`ColorBuffer`](color_buffer.md) Ring buffer storing `Color` values, used by [`outline_color_buffer`](#outline_color_buffer).
* [`TauXYStyle`](xy_style.md) Provides the per-series color and alpha a sample falls back to.
* [`Dataset`](dataset.md) The data model. Its logical sample index is the index a buffer is read by.