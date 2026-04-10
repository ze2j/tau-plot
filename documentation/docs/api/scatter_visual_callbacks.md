# ScatterVisualCallbacks

!!! info ""
    **Inherits:** [`VisualCallbacks`](visual_callbacks.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)
    
Callback-driven per-sample style overrides for [`SCATTER`](tau_plot.md#paneoverlaytype) overlays.

## Description

`ScatterVisualCallbacks` is the [`SCATTER`](tau_plot.md#paneoverlaytype) specific subclass of [`VisualCallbacks`](visual_callbacks.md). It carries the two callbacks inherited from that base class, [`color_callback`](visual_callbacks.md#color_callback) and [`alpha_callback`](visual_callbacks.md#alpha_callback), and adds four scatter-specific callbacks: [`size_callback`](#size_callback), [`shape_callback`](#shape_callback), [`outline_color_callback`](#outline_color_callback), and [`outline_width_callback`](#outline_width_callback).

Assign an instance to [`TauScatterConfig.scatter_visual_callbacks`](scatter_config.md#scatter_visual_callbacks). The renderer invokes each valid callback once per sample during the draw pass and applies the returned values on top of the values resolved from [`TauScatterStyle`](scatter_style.md) and [`TauXYStyle`](xy_style.md).

Each callback is optional. An invalid `Callable` means no callback is active for that property. The renderer falls through to the next resolution step when a callback is absent or when it returns a sentinel value.

The resolution order for each overridable property is:

1. The [`VisualAttributes`](visual_attributes.md) buffer, if a buffer is set and the sample index is within range.
2. The corresponding callback on `ScatterVisualCallbacks`, if the `Callable` is valid.
3. The resolved style value from the [three-layer cascade](scatter_style.md#three-layer-cascade) (theme then built-in default).

[`ScatterVisualAttributes`](scatter_visual_attributes.md) buffers always take priority over `ScatterVisualCallbacks` callbacks.

Each callback receives `x_value` as a `Variant`. Its concrete type is determined by the [`Dataset.XElementType`](dataset.md#xelementtype) chosen at construction time. When the dataset is built with [`XElementType.NUMERIC`](dataset.md#xelementtype), `x_value` is a `float`. When it is built with [`XElementType.CATEGORY`](dataset.md#xelementtype), `x_value` is a `String`. This is fixed for the lifetime of the [`Dataset`](dataset.md).

### Example

```gdscript
# Scale each marker by its Y value and use a distinct shape for outliers.
var callbacks := TauPlot.ScatterVisualCallbacks.new()

callbacks.size_callback = func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> float:
    return 8.0 + abs(y_value) * 2.0

callbacks.shape_callback = func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> ScatterStyle.MarkerShape:
    return ScatterStyle.MarkerShape.DIAMOND if abs(y_value) > 10.0 else ScatterStyle.MarkerShape.CIRCLE

scatter_config.scatter_visual_callbacks = callbacks
```

## Constructor

### `new()`

```gdscript
ScatterVisualCallbacks.new() -> ScatterVisualCallbacks
```

Creates a new `ScatterVisualCallbacks` instance with all callbacks set to an invalid `Callable`.

## Properties

### size_callback

`size_callback`: `Callable`

The per-sample marker size callback. Default is an invalid `Callable`.

If invalid, the marker size for every sample comes from the three-layer cascade via [`TauScatterStyle.marker_size_px`](scatter_style.md#marker_size_px). If valid, the callback is invoked once per sample. A return value of `0.0` or greater overrides the marker size in pixels of that sample. A negative return value is treated as unset and falls through to the cascade-resolved [`TauScatterStyle.marker_size_px`](scatter_style.md#marker_size_px). The callback signature is:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> float
```

`x_value` holds the sample's X value. Its concrete type depends on how the [`Dataset`](dataset.md) was built: `float` for [`XElementType.NUMERIC`](dataset.md#xelementtype) datasets, `String` for [`XElementType.CATEGORY`](dataset.md#xelementtype) datasets.

---

### shape_callback

`shape_callback`: `Callable`

The per-sample marker shape callback. Default is an invalid `Callable`.

If invalid, the shape for every sample comes from the three-layer cascade via [`TauScatterStyle.marker_shapes`](scatter_style.md#marker_shapes). If valid, the callback is invoked once per sample. A return value that is a valid [`MarkerShape`](scatter_style.md#markershape) enum value overrides the shape of that marker. A return value of `-1` is treated as unset and falls through to the cascade-resolved [`TauScatterStyle.marker_shapes`](scatter_style.md#marker_shapes). The callback signature is:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> ScatterStyle.MarkerShape
```

`x_value` holds the sample's X value. Its concrete type depends on how the [`Dataset`](dataset.md) was built: `float` for [`XElementType.NUMERIC`](dataset.md#xelementtype) datasets, `String` for [`XElementType.CATEGORY`](dataset.md#xelementtype) datasets.

---

### outline_color_callback

`outline_color_callback`: `Callable`

The per-sample outline color callback. Default is an invalid `Callable`.

If invalid, the outline color for every sample comes from the three-layer cascade via [`TauScatterStyle.outline_color`](scatter_style.md#outline_color). If valid, the callback is invoked once per sample. A return value other than `Color(0, 0, 0, 0)` overrides the outline color of that marker. A return value of `Color(0, 0, 0, 0)` is treated as unset and falls through to the cascade-resolved [`TauScatterStyle.outline_color`](scatter_style.md#outline_color). `Color(0, 0, 0, 0)` is therefore not a valid override outline color. The callback signature is:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> Color
```

`x_value` holds the sample's X value. Its concrete type depends on how the [`Dataset`](dataset.md) was built: `float` for [`XElementType.NUMERIC`](dataset.md#xelementtype) datasets, `String` for [`XElementType.CATEGORY`](dataset.md#xelementtype) datasets.

---

### outline_width_callback

`outline_width_callback`: `Callable`

The per-sample outline width callback. Default is an invalid `Callable`.

If invalid, the outline width for every sample comes from the three-layer cascade via [`TauScatterStyle.outline_width_px`](scatter_style.md#outline_width_px). If valid, the callback is invoked once per sample. A return value of `0.0` or greater overrides the outline stroke width in pixels of that marker, where `0.0` disables the outline for that sample. A negative return value is treated as unset and falls through to the cascade-resolved [`TauScatterStyle.outline_width_px`](scatter_style.md#outline_width_px). The callback signature is:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> float
```

`x_value` holds the sample's X value. Its concrete type depends on how the [`Dataset`](dataset.md) was built: `float` for [`XElementType.NUMERIC`](dataset.md#xelementtype) datasets, `String` for [`XElementType.CATEGORY`](dataset.md#xelementtype) datasets.

## Related Classes

* [`VisualCallbacks`](visual_callbacks.md) Base class. Defines the inherited [`color_callback`](visual_callbacks.md#color_callback) and [`alpha_callback`](visual_callbacks.md#alpha_callback).
* [`TauScatterConfig`](scatter_config.md) Owns the instance via its [`scatter_visual_callbacks`](scatter_config.md#scatter_visual_callbacks) property.
* [`ScatterVisualAttributes`](scatter_visual_attributes.md) Companion class that overrides the same properties from pre-built buffers rather than callbacks. Buffers take priority over callbacks.
* [`TauScatterStyle`](scatter_style.md) Provides the resolved scatter style values that callbacks override.
* [`BarVisualCallbacks`](bar_visual_callbacks.md) Sibling subclass for [`BAR`](tau_plot.md#paneoverlaytype) overlays.
