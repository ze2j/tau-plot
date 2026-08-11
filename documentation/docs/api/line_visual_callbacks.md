# LineVisualCallbacks

!!! info ""
    **Inherits:** [`VisualCallbacks`](visual_callbacks.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)

Callback-driven per-sample style overrides for [`LINE`](tau_plot.md#paneoverlaytype) overlays.

## Description

`LineVisualCallbacks` is the [`LINE`](tau_plot.md#paneoverlaytype) specific subclass of [`VisualCallbacks`](visual_callbacks.md). It carries the two callbacks inherited from that base class, [`color_callback`](visual_callbacks.md#color_callback) and [`alpha_callback`](visual_callbacks.md#alpha_callback), and adds no overlay-specific callbacks of its own.

Assign an instance to [`TauLineConfig.line_visual_callbacks`](line_config.md#line_visual_callbacks). Any other subclass on a line overlay is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts. The renderer invokes each valid callback once per sample during the draw pass and applies the returned values on top of the per-series color and alpha resolved from [`TauXYStyle`](xy_style.md).

Each callback is optional. An invalid `Callable` means no callback is active for that property. The renderer falls through to the next resolution step when a callback is absent or when it returns a sentinel value.

The resolution order for each overridable property is:

1. The [`LineVisualAttributes`](line_visual_attributes.md) buffer, if a buffer is set and the sample index is within range.
2. The corresponding callback on `LineVisualCallbacks`, if the `Callable` is valid.
3. The resolved per-series value from [`TauXYStyle.series_colors`](xy_style.md#series_colors) and [`TauXYStyle.series_alphas`](xy_style.md#series_alphas).

[`LineVisualAttributes`](line_visual_attributes.md) buffers always take priority over `LineVisualCallbacks` callbacks.

Both callbacks override the stroke of the curve. The area painted around it takes its color from [`TauLineFill`](line_fill.md) and is left untouched.

Each callback receives `x_value` as a `Variant`. Its concrete type is determined by the [`Dataset.XElementType`](dataset.md#xelementtype) chosen at construction time. When the dataset is built with [`XElementType.NUMERIC`](dataset.md#xelementtype), `x_value` is a `float`. When it is built with [`XElementType.CATEGORY`](dataset.md#xelementtype), `x_value` is a `String`. This is fixed for the lifetime of the [`Dataset`](dataset.md).

### Example

```gdscript
# Color the curve by threshold: samples over the limit read as an alert.
var callbacks := TauPlot.LineVisualCallbacks.new()
callbacks.color_callback = func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> Color:
    return Color.CRIMSON if y_value > 100.0 else Color.STEEL_BLUE

var line_overlay := TauLineConfig.new()
line_overlay.line_visual_callbacks = callbacks
```

### Notes

1. **A returned color colors a sample, not a segment.** Each sample carries its returned color into the curve, and the segment between two samples fades from the color of one to the color of the other. A threshold crossing therefore reads as a fade across the segment rather than as a sharp break at the crossing point, whatever the [interpolation mode](line_config.md#interpolation_modes).

2. **`y_value` is the value stored in the dataset.** In [`STACKED`](line_config.md#linemode) mode the curve is drawn at the running total, and the callback still receives the value the [`Dataset`](dataset.md) holds, never the running total and never the normalized value.

3. **The color returned here is not always the color drawn.** While at least one sample of the plot is hovered and [`TauHoverConfig.highlight_enabled`](hover_config.md#highlight_enabled) is `true`, every color goes through [`TauHoverConfig.hover_highlight_callback`](hover_config.md#hover_highlight_callback) before it is drawn. That callback receives one color and a `bool` saying whether this sample is the hovered one, and returns the color to draw. By default it brightens the hovered sample and dims every other sample. When no sample is hovered, the color returned here is drawn unchanged. The color of one sample never depends on the color of another.

## Constructor

### `new()`

```gdscript
LineVisualCallbacks.new() -> LineVisualCallbacks
```

Creates a new `LineVisualCallbacks` instance with all callbacks set to an invalid `Callable`.

## Related Classes

* [`VisualCallbacks`](visual_callbacks.md) Base class. Defines the inherited [`color_callback`](visual_callbacks.md#color_callback) and [`alpha_callback`](visual_callbacks.md#alpha_callback).
* [`TauLineConfig`](line_config.md) Owns the instance via its [`line_visual_callbacks`](line_config.md#line_visual_callbacks) property.
* [`LineVisualAttributes`](line_visual_attributes.md) Companion class that overrides the same properties from pre-built buffers rather than callbacks. Buffers take priority over callbacks.
* [`TauLineStyle`](line_style.md) Provides the resolved line style values the callbacks are applied on top of.
* [`TauLineFill`](line_fill.md) Paints the area around the curve, which the callbacks do not reach.
* [`TauXYStyle`](xy_style.md) Provides the per-series color and alpha a sample falls back to.
* [`TauHoverConfig`](hover_config.md) Holds the highlight callback the resolved color is routed through while a sample is hovered.
* [`BarVisualCallbacks`](bar_visual_callbacks.md) Sibling subclass for [`BAR`](tau_plot.md#paneoverlaytype) overlays.
* [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) Sibling subclass for [`SCATTER`](tau_plot.md#paneoverlaytype) overlays.
* [`Dataset`](dataset.md) The data model. Supplies the sample index and the X and Y values each callback receives.