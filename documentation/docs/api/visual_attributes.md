# VisualAttributes

!!! info ""
    **Inherits:** `RefCounted`  
    **Inherited By:** [`BarVisualAttributes`](bar_visual_attributes.md), [`ScatterVisualAttributes`](scatter_visual_attributes.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)

**Abstract class** for data-oriented per-sample style overrides.

## Description

`VisualAttributes` provides a data-oriented way to override style properties per sample. Instead of applying a uniform style to every sample in a series, an overlay can carry a `VisualAttributes` instance whose buffers supply a distinct value for each sample index. `VisualAttributes` defines the buffers shared by all overlay types. Concrete subclasses extend it with overlay-specific buffers.

An instance is assigned to [`TauXYSeriesBinding.visual_attributes`](xy_series_binding.md#visual_attributes). The renderer reads it during each draw pass.

Each **buffer** is optional. A `null` buffer means no per-sample override for that property. The resolved style value applies to every sample in the series instead.

A buffer does not need to cover every sample in the series. For any sample index past the end of the buffer, the resolved style value applies. **Partial buffers** are fully supported.

Fill color values in [`color_buffer`](#color_buffer) take priority over [`TauXYStyle.series_colors`](xy_style.md#series_colors). Alpha values in [`alpha_buffer`](#alpha_buffer) take priority over [`TauXYStyle.series_alpha`](xy_style.md#series_alpha).

### Notes

1. **Color sentinel value.** An entry equal to `Color(0, 0, 0, 0)` in [`color_buffer`](#color_buffer) is treated as unset. That sample falls through to the next resolution step: the callback if one is set, then [`TauXYStyle.series_colors`](xy_style.md#series_colors). `Color(0, 0, 0, 0)` is therefore not a valid override color.

2. **Alpha sentinel value.** A negative entry in [`alpha_buffer`](#alpha_buffer) is treated as unset. That sample falls through to the resolved [`TauXYStyle.series_alpha`](xy_style.md#series_alpha) value. Valid override values are in the range `[0.0, 1.0]`.

## Properties

### color_buffer

`color_buffer`: [`ColorBuffer`](color_buffer.md)

The per-sample fill color buffer. Default is `null`.

If `null`, the fill color for every sample comes from [`TauXYStyle.series_colors`](xy_style.md#series_colors). If set, each entry overrides the fill color of the sample at the same index. An entry equal to `Color(0, 0, 0, 0)` is treated as unset and falls through to the next resolution step (see note [1](#notes)). Entries beyond the series length are ignored. Samples beyond the buffer length fall through to the resolved style color.

The alpha channel of any color stored in this buffer is always ignored. The final alpha is determined solely by [`alpha_buffer`](#alpha_buffer) or [`TauXYStyle.series_alpha`](xy_style.md#series_alpha).

---

### alpha_buffer

`alpha_buffer`: [`Float32Buffer`](float32_buffer.md)

The per-sample alpha buffer. Default is `null`.

If `null`, the alpha for every sample comes from [`TauXYStyle.series_alpha`](xy_style.md#series_alpha). If set, each entry overrides the alpha of the sample at the same index. A negative entry is treated as unset and falls through to the resolved style alpha (see note [2](#notes)). Entries beyond the series length are ignored. Samples beyond the buffer length fall through to the resolved style alpha.

The resolved alpha overwrites the alpha channel of the fill color, regardless of whether the fill color comes from [`color_buffer`](#color_buffer) or [`TauXYStyle.series_colors`](xy_style.md#series_colors).

## Related Classes

* [`TauXYSeriesBinding`](xy_series_binding.md) Owns the `VisualAttributes` instance via its [`visual_attributes`](xy_series_binding.md#visual_attributes) property.
* [`BarVisualAttributes`](bar_visual_attributes.md) Subclass for bar overlays.
* [`ScatterVisualAttributes`](scatter_visual_attributes.md) Subclass for scatter overlays.
* [`VisualCallbacks`](visual_callbacks.md) Companion base class that computes the same properties on-the-fly from a callback rather than a buffer.
* [`ColorBuffer`](color_buffer.md) Ring buffer storing `Color` values, used by [`color_buffer`](#color_buffer).
* [`Float32Buffer`](float32_buffer.md) Ring buffer storing `float` values (32-bit), used by [`alpha_buffer`](#alpha_buffer).
* [`TauXYStyle`](xy_style.md) Provides the resolved series colors and alpha that buffers override.
