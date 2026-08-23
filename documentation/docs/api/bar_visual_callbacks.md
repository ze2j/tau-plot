# BarVisualCallbacks

!!! info ""
    **Inherits:** [`VisualCallbacks`](visual_callbacks.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)

Callback-driven per-sample style overrides for [`BAR`](tau_plot.md#paneoverlaytype) overlays.

## Description

`BarVisualCallbacks` is the [`BAR`](tau_plot.md#paneoverlaytype) specific subclass of [`VisualCallbacks`](visual_callbacks.md). It carries the two callbacks inherited from that base class, [`color_callback`](visual_callbacks.md#color_callback) and [`alpha_callback`](visual_callbacks.md#alpha_callback), and adds one bar-specific callback: [`style_box_callback`](#style_box_callback).

Assign an instance to [`TauBarConfig.bar_visual_callbacks`](bar_config.md#bar_visual_callbacks). Any other subclass on a bar overlay is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts. The plot invokes each valid callback once per sample on each draw pass and applies the returned values on top of the values resolved from [`TauBarStyle`](bar_style.md) and [`TauXYStyle`](xy_style.md).

Each callback is optional. An invalid `Callable` means no override for that property, and the resolved style value applies to every sample of the series. Each callback receives the dataset series index, the logical sample index, and the X and Y values of the sample, as described in [`VisualCallbacks`](visual_callbacks.md).

See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for the order a callback resolves in against a [`BarVisualAttributes`](bar_visual_attributes.md) buffer and the style property.

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

var bar_overlay := TauBarConfig.new()
bar_overlay.mode = TauBarConfig.BarMode.INDEPENDENT
bar_overlay.bar_visual_callbacks = callbacks
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

Callback computing the `StyleBox` one bar is drawn with. Default is an invalid `Callable`.

The return value overrides the `StyleBox` of the bar, taking priority over [`TauBarStyle.style_box`](bar_style.md#style_box). A `null` return is treated as unset and that bar falls through to the resolved [`TauBarStyle.style_box`](bar_style.md#style_box). The callback signature is:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> StyleBox
```

The accepted concrete return types are `StyleBoxFlat` and `StyleBoxTexture`. Any other subclass pushes an error and the bar falls back to the resolved [`TauBarStyle.style_box`](bar_style.md#style_box).

`StyleBoxFlat.bg_color` and `StyleBoxTexture.modulate_color` on the returned `StyleBox` are ignored. The fill color of a bar comes from [`TauXYStyle.series_colors`](xy_style.md#series_colors) and [`TauXYStyle.series_alphas`](xy_style.md#series_alphas), or from the per-sample overrides that replace them, [`color_callback`](visual_callbacks.md#color_callback), [`alpha_callback`](visual_callbacks.md#alpha_callback), and the [`BarVisualAttributes`](bar_visual_attributes.md) buffers.

Corner radii and borders on a returned `StyleBoxFlat` are read as if the bar grew upward from the baseline and are remapped to the direction the bar actually grows in, the same way [`TauBarStyle.style_box`](bar_style.md#style_box) is.

The emphasized bar takes [`TauBarStyle.hovered_style_box`](bar_style.md#hovered_style_box) instead of the returned value, so this callback shapes every bar except that one.

## Related Classes

* [`VisualCallbacks`](visual_callbacks.md) Base class. Defines the inherited [`color_callback`](visual_callbacks.md#color_callback) and [`alpha_callback`](visual_callbacks.md#alpha_callback), the arguments every callback receives, and their sentinels.
* [`TauBarConfig`](bar_config.md) Owns the instance via its [`bar_visual_callbacks`](bar_config.md#bar_visual_callbacks) property.
* [`BarVisualAttributes`](bar_visual_attributes.md) Companion class that reads the same properties from pre-built buffers rather than computing them. Buffers take priority over callbacks.
* [`TauBarStyle`](bar_style.md) Provides the resolved bar style values the callbacks are applied on top of, including the [`hovered_style_box`](bar_style.md#hovered_style_box) that wins over [`style_box_callback`](#style_box_callback).
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class of [`TauBarConfig`](bar_config.md). Defines how a per-sample override resolves against a buffer and a style property.
* [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) Sibling subclass for [`SCATTER`](tau_plot.md#paneoverlaytype) overlays.
* [`LineVisualCallbacks`](line_visual_callbacks.md) Sibling subclass for [`LINE`](tau_plot.md#paneoverlaytype) overlays.
* [`TauXYStyle`](xy_style.md) Provides the per-series color and alpha a sample falls back to.
* [`Dataset`](dataset.md) The data model. Supplies the series index, the sample index, and the X and Y values a callback receives.