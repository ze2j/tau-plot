# VisualAttributes

!!! info ""
    **Inherits:** `RefCounted`  
    **Inherited By:** [`BarVisualAttributes`](bar_visual_attributes.md), [`ScatterVisualAttributes`](scatter_visual_attributes.md), [`LineVisualAttributes`](line_visual_attributes.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)

**Abstract class** for data-oriented per-sample style overrides.

## Description

`VisualAttributes` carries one **buffer** per overridable property, so a series can hold a distinct value for each of its samples instead of taking one uniform value from its style. `VisualAttributes` defines the buffers every overlay type has, and each concrete subclass adds the buffers specific to its own overlay type.

An instance is assigned to [`TauXYSeriesBinding.visual_attributes`](xy_series_binding.md#visual_attributes), and must be the subclass matching the overlay the binding targets: [`BarVisualAttributes`](bar_visual_attributes.md) for [`BAR`](tau_plot.md#paneoverlaytype), [`ScatterVisualAttributes`](scatter_visual_attributes.md) for [`SCATTER`](tau_plot.md#paneoverlaytype), and [`LineVisualAttributes`](line_visual_attributes.md) for [`LINE`](tau_plot.md#paneoverlaytype). Any other type is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts.

A buffer is read by logical sample index, the index the [`Dataset`](dataset.md) reads a series by, where `0` is the oldest sample. A series at capacity drops its oldest sample on the next append and every index then names a different sample, so a buffer of a streaming series has to be appended to in step with the data.

Each buffer is optional. A `null` buffer means no per-sample override for that property, and the resolved style value applies to every sample of the series. A buffer does not have to cover the whole series: **partial buffers** are supported, and a sample index past the end of the buffer takes the resolved style value as well. Entries past the end of the series are never read.

Each buffer also accepts a sentinel entry meaning no override for that one sample, so a buffer can span a whole series and still leave individual samples to the style. Every sentinel is stated on the property that accepts it.

See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for the order a buffer resolves in against a [`VisualCallbacks`](visual_callbacks.md) callback and the style property.

An instance is assigned at runtime only. `VisualAttributes` is a `RefCounted` and the property holding it is not exported, so buffers cannot be saved in a `.tres` resource file.

### Notes

1. **Color sentinel value.** An entry equal to [`ColorBuffer.NO_COLOR`](color_buffer.md), which is fully transparent black, is treated as unset. That sample falls through to the next resolution step, so [`ColorBuffer.NO_COLOR`](color_buffer.md) is not a usable override color.

2. **Alpha sentinel value.** A negative entry is treated as unset. That sample falls through to the next resolution step, so a fully transparent sample is written as `0.0` rather than as a negative value.

3. **Hover highlighting runs after the override.** The highlight can change the color a sample is drawn with while the cursor is over its pane. A buffer entry decides the color a sample starts from, not always the color it ends up drawn in. See [`TauHoverConfig`](hover_config.md).

## Properties

### color_buffer

`color_buffer`: [`ColorBuffer`](color_buffer.md)

Buffer holding the fill color of each sample. Default is `null`.

An entry overrides the fill color of the sample at the same index, taking priority over [`TauXYStyle.series_colors`](xy_style.md#series_colors). An entry equal to [`ColorBuffer.NO_COLOR`](color_buffer.md) is treated as unset, see [note 1](#notes).

The alpha channel of an entry is ignored. The alpha of a sample comes from [`alpha_buffer`](#alpha_buffer) or from [`TauXYStyle.series_alphas`](xy_style.md#series_alphas).

---

### alpha_buffer

`alpha_buffer`: [`Float32Buffer`](float32_buffer.md)

Buffer holding the opacity of each sample, replacing the alpha channel of its fill color. Default is `null`.

An entry overrides the alpha of the sample at the same index, taking priority over [`TauXYStyle.series_alphas`](xy_style.md#series_alphas). Valid override values run from `0.0` to `1.0`, and an entry above `1.0` is clamped to `1.0` as the sample is drawn. A negative entry is treated as unset, see [note 2](#notes).

## Related Classes

* [`TauXYSeriesBinding`](xy_series_binding.md) Owns the `VisualAttributes` instance via its [`visual_attributes`](xy_series_binding.md#visual_attributes) property.
* [`BarVisualAttributes`](bar_visual_attributes.md) Subclass for [`BAR`](tau_plot.md#paneoverlaytype) overlays.
* [`ScatterVisualAttributes`](scatter_visual_attributes.md) Subclass for [`SCATTER`](tau_plot.md#paneoverlaytype) overlays.
* [`LineVisualAttributes`](line_visual_attributes.md) Subclass for [`LINE`](tau_plot.md#paneoverlaytype) overlays.
* [`VisualCallbacks`](visual_callbacks.md) Companion base class that computes the same properties at draw time rather than reading them from a buffer. Buffers take priority over callbacks.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class of the overlay configurations. Defines how a per-sample override resolves against a callback and a style property.
* [`ColorBuffer`](color_buffer.md) Ring buffer storing `Color` values, used by [`color_buffer`](#color_buffer). Declares the [`NO_COLOR`](color_buffer.md) sentinel.
* [`Float32Buffer`](float32_buffer.md) Ring buffer storing `float` values (32-bit), used by [`alpha_buffer`](#alpha_buffer).
* [`Dataset`](dataset.md) The data model. Its logical sample index is the index a buffer is read by.
* [`TauXYStyle`](xy_style.md) Provides the per-series color and alpha a sample falls back to.
* [`TauHoverConfig`](hover_config.md) Controls the highlight, which can change the color a sample is drawn with.
* [`TauPlot`](tau_plot.md) The plot node. Reads the buffers of every binding it received on each draw pass.