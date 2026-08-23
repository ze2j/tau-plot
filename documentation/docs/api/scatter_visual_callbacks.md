# ScatterVisualCallbacks

!!! info ""
    **Inherits:** [`VisualCallbacks`](visual_callbacks.md)  
    **Namespace:** [`TauPlot`](tau_plot.md)

Callback-driven per-sample style overrides for [`SCATTER`](tau_plot.md#paneoverlaytype) overlays.

## Description

`ScatterVisualCallbacks` is the [`SCATTER`](tau_plot.md#paneoverlaytype) specific subclass of [`VisualCallbacks`](visual_callbacks.md). It carries the two callbacks inherited from that base class, [`color_callback`](visual_callbacks.md#color_callback) and [`alpha_callback`](visual_callbacks.md#alpha_callback), and adds four scatter-specific callbacks: [`size_callback`](#size_callback), [`shape_callback`](#shape_callback), [`outline_color_callback`](#outline_color_callback), and [`outline_width_callback`](#outline_width_callback).

Assign an instance to [`TauScatterConfig.scatter_visual_callbacks`](scatter_config.md#scatter_visual_callbacks). Any other subclass on a scatter overlay is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts. The plot invokes each valid callback once per sample on each draw pass and applies the returned values on top of the values resolved from [`TauScatterStyle`](scatter_style.md) and [`TauXYStyle`](xy_style.md).

Each callback is optional. An invalid `Callable` means no override for that property, and the resolved style value applies to every sample of the series. Each callback receives the dataset series index, the logical sample index, and the X and Y values of the sample, as described in [`VisualCallbacks`](visual_callbacks.md).

The emphasized marker takes the hovered-state properties of [`TauScatterStyle`](scatter_style.md), so [`size_callback`](#size_callback), [`outline_color_callback`](#outline_color_callback), and [`outline_width_callback`](#outline_width_callback) shape every marker except that one.

See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for the order a callback resolves in against a [`ScatterVisualAttributes`](scatter_visual_attributes.md) buffer and the style property.

### Example

```gdscript
# Scale each marker by its Y value and use a distinct shape for outliers.
var callbacks := TauPlot.ScatterVisualCallbacks.new()

callbacks.size_callback = func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> float:
    return 8.0 + abs(y_value) * 2.0

callbacks.shape_callback = func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> TauScatterStyle.MarkerShape:
    return TauScatterStyle.MarkerShape.DIAMOND if abs(y_value) > 10.0 else TauScatterStyle.MarkerShape.CIRCLE

var scatter_overlay := TauScatterConfig.new()
scatter_overlay.scatter_visual_callbacks = callbacks
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

Callback computing the marker size of one sample. Default is an invalid `Callable`.

The return value overrides the size of the marker, taking priority over [`TauScatterStyle.marker_sizes_px`](scatter_style.md#marker_sizes_px). A negative return is treated as unset. The unit follows the active [`TauScatterConfig.marker_size_policy`](scatter_config.md#marker_size_policy): pixels under [`THEME`](scatter_config.md#markersizepolicy), X data units under [`DATA_UNITS`](scatter_config.md#markersizepolicy), where the drawn size then changes with the X domain. The callback signature is:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> float
```

The resolved pixel size is raised to `1.0`, so a return of `0.0` draws a one pixel marker rather than hiding one. Hide a marker through [`shape_callback`](#shape_callback) instead.

Under [`DATA_UNITS`](scatter_config.md#markersizepolicy) on a [categorical](axis_config.md#type-enum) X axis there is no data span to convert, and the return value is discarded: the size comes from [`TauScatterStyle.marker_sizes_px`](scatter_style.md#marker_sizes_px), with no error and no warning.

---

### shape_callback

`shape_callback`: `Callable`

Callback computing the marker shape of one sample. Default is an invalid `Callable`.

The return value overrides the shape of the marker, taking priority over [`TauScatterStyle.marker_shapes`](scatter_style.md#marker_shapes). A negative return is treated as unset. Any other value outside [`TauScatterStyle.MarkerShape`](scatter_style.md#markershape) draws a [`CIRCLE`](scatter_style.md#markershape) with no message, since the callback runs once per sample. The callback signature is:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> TauScatterStyle.MarkerShape
```

A return of [`NONE`](scatter_style.md#markershape) draws nothing for that sample. A sample that draws nothing is also left out of hover hit testing, so it reports no [`SampleHit`](sample_hit.md) and never appears in a tooltip.

---

### outline_color_callback

`outline_color_callback`: `Callable`

Callback computing the color of the outline stroked around one marker. Default is an invalid `Callable`.

The return value overrides the outline color of the marker, taking priority over [`TauScatterStyle.outline_color`](scatter_style.md#outline_color). A return of [`ColorBuffer.NO_COLOR`](color_buffer.md) is treated as unset, see [note 1](visual_callbacks.md#notes) on the base class. The callback signature is:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> Color
```

The resolved alpha of the sample is applied on top of the returned color, so a marker and its outline fade together.

---

### outline_width_callback

`outline_width_callback`: `Callable`

Callback computing the thickness in pixels of the outline stroked around one marker. Default is an invalid `Callable`.

The return value overrides the outline width of the marker, taking priority over [`TauScatterStyle.outline_width_px`](scatter_style.md#outline_width_px). A negative return is treated as unset. Valid override values are `0.0` or greater, where `0.0` leaves that marker unoutlined, and the drawn outline never exceeds half the resolved marker size. The callback signature is:

```gdscript
func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> float
```

## Related Classes

* [`VisualCallbacks`](visual_callbacks.md) Base class. Defines the inherited [`color_callback`](visual_callbacks.md#color_callback) and [`alpha_callback`](visual_callbacks.md#alpha_callback), the arguments every callback receives, and their sentinels.
* [`TauScatterConfig`](scatter_config.md) Owns the instance via its [`scatter_visual_callbacks`](scatter_config.md#scatter_visual_callbacks) property. Its [`marker_size_policy`](scatter_config.md#marker_size_policy) decides the unit a [`size_callback`](#size_callback) returns.
* [`ScatterVisualAttributes`](scatter_visual_attributes.md) Companion class that reads the same properties from pre-built buffers rather than computing them. Buffers take priority over callbacks.
* [`TauScatterStyle`](scatter_style.md) Provides the resolved scatter style values the callbacks are applied on top of, including the hovered-state properties that win over them.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class of [`TauScatterConfig`](scatter_config.md). Defines how a per-sample override resolves against a buffer and a style property.
* [`TauAxisConfig`](axis_config.md) Configures the X axis whose type decides whether a [`DATA_UNITS`](scatter_config.md#markersizepolicy) size is converted or discarded.
* [`SampleHit`](sample_hit.md) Reports one hovered sample. A marker hidden through [`shape_callback`](#shape_callback) produces none.
* [`ColorBuffer`](color_buffer.md) Declares the [`NO_COLOR`](color_buffer.md) sentinel a color callback returns to override nothing.
* [`BarVisualCallbacks`](bar_visual_callbacks.md) Sibling subclass for [`BAR`](tau_plot.md#paneoverlaytype) overlays.
* [`LineVisualCallbacks`](line_visual_callbacks.md) Sibling subclass for [`LINE`](tau_plot.md#paneoverlaytype) overlays.
* [`TauXYStyle`](xy_style.md) Provides the per-series color and alpha a sample falls back to.
* [`Dataset`](dataset.md) The data model. Supplies the series index, the sample index, and the X and Y values a callback receives.