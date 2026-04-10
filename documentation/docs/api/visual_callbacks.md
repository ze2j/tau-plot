# VisualCallbacks

!!! info ""
    **Inherits:** `RefCounted`  
    **Inherited By:** [`BarVisualCallbacks`](bar_visual_callbacks.md), [`ScatterVisualCallbacks`](scatter_visual_callbacks.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)
    
**Abstract class** for callback-driven per-sample style overrides.

## Description

`VisualCallbacks` provides a callback-driven way to override style properties per sample. Instead of applying a uniform style to every sample in a series, an overlay can carry a `VisualCallbacks` instance whose callbacks compute a distinct value for each sample on-the-fly during each draw pass. `VisualCallbacks` defines the callbacks shared by all overlay types. Concrete subclasses extend it with overlay-specific callbacks.

An instance is assigned to [`TauBarConfig.bar_visual_callbacks`](bar_config.md#bar_visual_callbacks) or [`TauScatterConfig.scatter_visual_callbacks`](scatter_config.md#scatter_visual_callbacks). The renderer invokes each valid callback once per sample during the draw pass.

Each callback is optional. An invalid `Callable` means no callback is active for that property. The renderer falls through to the next resolution step when a callback is absent or when it returns a sentinel value.

The resolution order for each overridable property is:

1. The [`VisualAttributes`](visual_attributes.md) buffer, if a buffer is set and the sample index is within range.
2. The corresponding callback on `VisualCallbacks`, if the `Callable` is valid.
3. The resolved style value from the [three-layer cascade](xy_style.md#three-layer-cascade) (theme then built-in default).

[`VisualAttributes`](visual_attributes.md) buffers always take priority over `VisualCallbacks` callbacks.

Each callback receives four arguments: `series_index` (the series index in the [`Dataset`](dataset.md)), `sample_index` (the zero-based index of the sample within the series), `x_value` (the sample X value as a `Variant`), and `y_value` (the sample Y value as a `float`).

Fill color values returned by [`color_callback`](#color_callback) take priority over [`TauXYStyle.series_colors`](xy_style.md#series_colors). Alpha values returned by [`alpha_callback`](#alpha_callback) take priority over [`TauXYStyle.series_alpha`](xy_style.md#series_alpha).

## Properties

### color_callback

`color_callback`: `Callable`

The per-sample fill color callback. Default is an invalid `Callable`.

If invalid, the fill color for each sample is resolved without this callback. If valid, the callback is invoked once per sample and its return value overrides the fill color of that sample. The callback signature is:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> Color
```

`x_value` holds the sample's X value. Its concrete type depends on how the [`Dataset`](dataset.md) was built: `float` for [`XElementType.NUMERIC`](dataset.md#xelementtype) datasets, `String` for [`XElementType.CATEGORY`](dataset.md#xelementtype) datasets.

The alpha channel of any returned color is always ignored. The final alpha is determined solely by [`alpha_callback`](#alpha_callback) or [`TauXYStyle.series_alpha`](xy_style.md#series_alpha).

---

### alpha_callback

`alpha_callback`: `Callable`

The per-sample alpha callback. Default is an invalid `Callable`.

If invalid, the alpha for each sample is resolved without this callback. If valid, the callback is invoked once per sample. A return value of `0.0` or greater overrides the alpha of that sample. A negative return value is treated as unset and falls through to the resolved [`TauXYStyle.series_alpha`](xy_style.md#series_alpha). Valid override values are in the range `[0.0, 1.0]`. The callback signature is:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> float
```

`x_value` holds the sample's X value. Its concrete type depends on how the [`Dataset`](dataset.md) was built: `float` for [`XElementType.NUMERIC`](dataset.md#xelementtype) datasets, `String` for [`XElementType.CATEGORY`](dataset.md#xelementtype) datasets.

The resolved alpha overwrites the alpha channel of the fill color, regardless of whether the fill color comes from [`color_callback`](#color_callback) or [`TauXYStyle.series_colors`](xy_style.md#series_colors).

## Related Classes

* [`TauBarConfig`](bar_config.md) Owns the instance via its [`bar_visual_callbacks`](bar_config.md#bar_visual_callbacks) typed property.
* [`TauScatterConfig`](scatter_config.md) Owns the instance via its [`scatter_visual_callbacks`](scatter_config.md#scatter_visual_callbacks) typed property.
* [`BarVisualCallbacks`](bar_visual_callbacks.md) Subclass for bar overlays.
* [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) Subclass for scatter overlays.
* [`VisualAttributes`](visual_attributes.md) Companion base class that overrides the same properties from pre-built buffers rather than callbacks.
* [`TauXYStyle`](xy_style.md) Provides the resolved series colors and alpha that callbacks override.
