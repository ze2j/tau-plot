# BarVisualCallbacks

!!! info ""
    **Inherits:** [`VisualCallbacks`](visual_callbacks.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)
    
Callback-driven per-sample style overrides for [`BAR`](tau_plot.md#paneoverlaytype) overlays.

## Description

`BarVisualCallbacks` is the [`BAR`](tau_plot.md#paneoverlaytype) specific subclass of [`VisualCallbacks`](visual_callbacks.md). It carries the two callbacks inherited from that base class, [`color_callback`](visual_callbacks.md#color_callback) and [`alpha_callback`](visual_callbacks.md#alpha_callback), and adds one bar-specific callback: [`style_box_callback`](#style_box_callback).

Assign an instance to [`TauBarConfig.bar_visual_callbacks`](bar_config.md#bar_visual_callbacks). The renderer invokes each valid callback once per sample during the draw pass and applies the returned values on top of the values resolved from [`TauBarStyle`](bar_style.md) and [`TauXYStyle`](xy_style.md).

Each callback is optional. An invalid `Callable` means no callback is active for that property. The renderer falls through to the next resolution step when a callback is absent or when it returns a sentinel value.

The resolution order for each overridable property is:

1. The [`VisualAttributes`](visual_attributes.md) buffer, if a buffer is set and the sample index is within range.
2. The corresponding callback on `BarVisualCallbacks`, if the `Callable` is valid.
3. The resolved style value from the [three-layer cascade](bar_style.md#three-layer-cascade) (theme then built-in default).

[`BarVisualAttributes`](bar_visual_attributes.md) buffers always take priority over `BarVisualCallbacks` callbacks.

Each callback receives `x_value` as a `Variant`. Its concrete type is determined by the [`Dataset.XElementType`](dataset.md#xelementtype) chosen at construction time. When the dataset is built with [`XElementType.NUMERIC`](dataset.md#xelementtype), `x_value` is a `float`. When it is built with [`XElementType.CATEGORY`](dataset.md#xelementtype), `x_value` is a `String`. This is fixed for the lifetime of the [`Dataset`](dataset.md).

### Example

```gdscript
# Give positive and negative bars a distinct shape by returning different
# StyleBoxFlat instances based on the sample's Y value.
var round_box := StyleBoxFlat.new()
round_box.corner_radius_top_left = 4
round_box.corner_radius_top_right = 4

var flat_box := StyleBoxFlat.new()

var callbacks := TauPlot.BarVisualCallbacks.new()
callbacks.style_box_callback = func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> StyleBox:
    return round_box if y_value >= 0.0 else flat_box

var bar_cfg := TauBarConfig.new()
bar_cfg.mode = TauBarConfig.BarMode.INDEPENDENT
bar_cfg.bar_visual_callbacks = callbacks
```

## Constructor

### `new()`

```gdscript
BarVisualCallbacks.new() -> BarVisualCallbacks
```

Creates a new `BarVisualCallbacks` instance with all callbacks set to an invalid `Callable`.

## Properties

### style_box_callback

`style_box_callback`: `Callable`

The per-sample `StyleBox` callback. Default is an invalid `Callable`.

If invalid, the `StyleBox` for every sample comes from the three-layer cascade via [`TauBarStyle.style_box`](bar_style.md#style_box). If valid, the callback is invoked once per sample. A non-`null` return value overrides the `StyleBox` used to draw that bar. A `null` return value is treated as unset and falls through to the cascade-resolved [`TauBarStyle.style_box`](bar_style.md#style_box). The callback signature is:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> StyleBox
```

`x_value` holds the sample's X value. Its concrete type depends on how the [`Dataset`](dataset.md) was built: `float` for [`XElementType.NUMERIC`](dataset.md#xelementtype) datasets, `String` for [`XElementType.CATEGORY`](dataset.md#xelementtype) datasets.

The accepted concrete return types are `StyleBoxFlat` and `StyleBoxTexture`. Any other subclass logs an error and the cascade-resolved `StyleBox` is used instead.

`StyleBoxFlat.bg_color` and `StyleBoxTexture.modulate_color` on the returned `StyleBox` are always ignored. The fill color comes from [`TauXYStyle.series_colors`](xy_style.md#series_colors) and [`TauXYStyle.series_alpha`](xy_style.md#series_alpha), except when per-sample overrides are active via [`color_callback`](visual_callbacks.md#color_callback), [`alpha_callback`](visual_callbacks.md#alpha_callback), or [`BarVisualAttributes`](bar_visual_attributes.md) buffers.

## Related Classes

* [`VisualCallbacks`](visual_callbacks.md) Base class. Defines the inherited [`color_callback`](visual_callbacks.md#color_callback) and [`alpha_callback`](visual_callbacks.md#alpha_callback).
* [`TauBarConfig`](bar_config.md) Owns the instance via its [`bar_visual_callbacks`](bar_config.md#bar_visual_callbacks) property.
* [`BarVisualAttributes`](bar_visual_attributes.md) Companion class that overrides the same properties from pre-built buffers rather than callbacks. Buffers take priority over callbacks.
* [`TauBarStyle`](bar_style.md) Provides the resolved bar style values that callbacks override.
* [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) Sibling subclass for [`SCATTER`](tau_plot.md#paneoverlaytype) overlays.
