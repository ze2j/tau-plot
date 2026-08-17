# VisualCallbacks

!!! info ""
    **Inherits:** `RefCounted`  
    **Inherited By:** [`BarVisualCallbacks`](bar_visual_callbacks.md), [`ScatterVisualCallbacks`](scatter_visual_callbacks.md), [`LineVisualCallbacks`](line_visual_callbacks.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)

**Abstract class** for callback-driven per-sample style overrides.

## Description

`VisualCallbacks` carries one function per overridable property, called once per sample while the pane is drawn, so the value of a property can be derived from the sample itself instead of being stored anywhere. `VisualCallbacks` defines the callbacks every overlay type has, and each concrete subclass adds the callbacks specific to its own overlay type.

An instance is assigned to the typed accessor of the overlay it belongs to: [`TauBarConfig.bar_visual_callbacks`](bar_config.md#bar_visual_callbacks), [`TauScatterConfig.scatter_visual_callbacks`](scatter_config.md#scatter_visual_callbacks), or [`TauLineConfig.line_visual_callbacks`](line_config.md#line_visual_callbacks). Assigning a subclass that does not match the overlay through the base [`TauPaneOverlayConfig.visual_callbacks`](pane_overlay_config.md#visual_callbacks) property is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts.

Every callback takes the same four arguments:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float)
```

* `series_index: int` The series index in the [`Dataset`](dataset.md), not the index of the series within the overlay.
* `sample_index: int` The logical sample index in the series, where `0` is the oldest sample.
* `x_value: Variant` The X value of the sample. Its concrete type follows the [`Dataset.XElementType`](dataset.md#xelementtype) chosen at construction: `float` for [`NUMERIC`](dataset.md#xelementtype), `String` for [`CATEGORY`](dataset.md#xelementtype). This is fixed for the lifetime of the [`Dataset`](dataset.md).
* `y_value: float` The Y value the [`Dataset`](dataset.md) holds for the sample, the one [`SampleHit.y_raw_value`](sample_hit.md#y_raw_value) also reports. In a stacked overlay it is neither the running total the sample is drawn at nor its normalized value.

Each callback is optional. An invalid `Callable` means no override for that property, and the resolved style value applies to every sample of the series. Each callback also has a sentinel return value meaning no override for that one sample, so a callback can decide per sample whether to override at all. Every sentinel is stated on the property that returns it.

A callback runs once per sample per draw pass, so it holds no state and its cost is paid on every redraw.

See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for the order a callback resolves in against a [`VisualAttributes`](visual_attributes.md) buffer and the style property.

An instance is assigned at runtime only. `VisualCallbacks` is a `RefCounted` and the property holding it is not exported, so callbacks cannot be saved in a `.tres` resource file.

### Notes

1. **Color sentinel value.** A return of [`ColorBuffer.NO_COLOR`](color_buffer.md), which is fully transparent black, is treated as unset. That sample falls through to the next resolution step, so [`ColorBuffer.NO_COLOR`](color_buffer.md) is not a usable override color.

2. **Alpha sentinel value.** A negative return is treated as unset. That sample falls through to the next resolution step, so a fully transparent sample is returned as `0.0` rather than as a negative value.

3. **Hover highlighting runs after the override.** While at least one sample of the plot is hovered and [`TauHoverConfig.highlight_enabled`](hover_config.md#highlight_enabled) is `true`, every resolved color passes through [`TauHoverConfig.hover_highlight_callback`](hover_config.md#hover_highlight_callback) before it is drawn, and the emphasized sample also takes the hovered-state properties of its style. A returned value decides the color a sample starts from, not always the color it ends up drawn in.

## Properties

### color_callback

`color_callback`: `Callable`

Callback computing the fill color of one sample. Default is an invalid `Callable`.

The return value overrides the fill color of the sample, taking priority over [`TauXYStyle.series_colors`](xy_style.md#series_colors). A return of [`ColorBuffer.NO_COLOR`](color_buffer.md) is treated as unset, see [note 1](#notes). The callback signature is:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> Color
```

The alpha channel of the returned color is ignored. The alpha of a sample comes from [`alpha_callback`](#alpha_callback) or from [`TauXYStyle.series_alphas`](xy_style.md#series_alphas).

---

### alpha_callback

`alpha_callback`: `Callable`

Callback computing the opacity of one sample, replacing the alpha channel of its fill color. Default is an invalid `Callable`.

The return value overrides the alpha of the sample, taking priority over [`TauXYStyle.series_alphas`](xy_style.md#series_alphas). Valid override values run from `0.0` to `1.0`, and a return above `1.0` is clamped to `1.0` as the sample is drawn. A negative return is treated as unset, see [note 2](#notes). The callback signature is:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> float
```

## Related Classes

* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class of the overlay configurations. Holds the instance via [`visual_callbacks`](pane_overlay_config.md#visual_callbacks) and defines how a callback resolves against a buffer and a style property.
* [`TauBarConfig`](bar_config.md) Owns the instance via its [`bar_visual_callbacks`](bar_config.md#bar_visual_callbacks) typed accessor.
* [`TauScatterConfig`](scatter_config.md) Owns the instance via its [`scatter_visual_callbacks`](scatter_config.md#scatter_visual_callbacks) typed accessor.
* [`TauLineConfig`](line_config.md) Owns the instance via its [`line_visual_callbacks`](line_config.md#line_visual_callbacks) typed accessor.
* [`BarVisualCallbacks`](bar_visual_callbacks.md) Subclass for [`BAR`](tau_plot.md#paneoverlaytype) overlays.
* [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) Subclass for [`SCATTER`](tau_plot.md#paneoverlaytype) overlays.
* [`LineVisualCallbacks`](line_visual_callbacks.md) Subclass for [`LINE`](tau_plot.md#paneoverlaytype) overlays.
* [`VisualAttributes`](visual_attributes.md) Companion base class that reads the same properties from pre-built buffers rather than computing them. Buffers take priority over callbacks.
* [`ColorBuffer`](color_buffer.md) Declares the [`NO_COLOR`](color_buffer.md) sentinel a color callback returns to override nothing.
* [`Dataset`](dataset.md) The data model. Supplies the series index, the sample index, and the X and Y values a callback receives.
* [`SampleHit`](sample_hit.md) Reports the same raw Y value a callback receives, through [`y_raw_value`](sample_hit.md#y_raw_value).
* [`TauXYStyle`](xy_style.md) Provides the per-series color and alpha a sample falls back to.
* [`TauHoverConfig`](hover_config.md) Holds the highlight callback a resolved color is routed through while a sample is hovered.
* [`TauPlot`](tau_plot.md) The plot node. Invokes every valid callback once per sample on each draw pass.