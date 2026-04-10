# TauScatterStyle

!!! info ""
    **Inherits:** `Resource`  

Controls the visual appearance of scatter overlays.

## Description

A scatter overlay draws one marker per sample at its (X, Y) position in the pane. `TauScatterStyle` controls how those markers look: their size, the width and color of their outline, how both change when a marker is hovered, and the palette of shapes cycled across series.

`TauScatterStyle` lives on [`TauScatterConfig.style`](scatter_config.md#style). It is created automatically when [`TauScatterConfig`](scatter_config.md) is instantiated, so it is never `null`.

Multiple [`TauScatterConfig`](scatter_config.md) instances can reference the same `TauScatterStyle` resource. Every scatter overlay that holds a reference picks up any change made to that shared instance.

The fill color of each marker is not a property of `TauScatterStyle`. It comes from [`TauXYStyle.series_colors`](xy_style.md#series_colors), with its alpha channel overwritten by [`TauXYStyle.series_alpha`](xy_style.md#series_alpha), except when per-sample overrides are active (see note [1](#notes)).

### Three-layer cascade

Each property's final value is resolved through the following cascade, in order:

1. **Built-in default**  
    The final value starts from the built-in default.

2. **Theme value**  
    If the active Godot theme defines a matching scatter property, that value replaces the built-in default. The theme is checked twice per scalar property. First, the non-indexed key is read and applies to every pane. Then, a pane-indexed key is read and applies only to the pane at that index, overwriting the non-indexed value for that pane alone.

    For example, with two panes:

    ```gdscript
    # Applies to all panes.
    TauScatter/constants/scatter_marker_size_px = 10
    # Overrides only pane 1, leaving pane 0 at the value above.
    TauScatter/constants/scatter_marker_size_px_1 = 14
    ```
    
    Pane `0` uses `10`. Pane `1` uses `14`.

3. **User override**  
    If the property is explicitly set on the `TauScatterStyle` instance, that value overrides both the theme and the built-in default.

In short:

- the last layer that provides a value wins
- the Godot theme is suited for **project-wide styling**, with optional per-pane targeting via indexed keys
- `TauScatterStyle` is suited for **per-plot or per-pane styling**

**Override detection limitation**

A property is considered overridden only when its value differs from the corresponding built-in default constant.

As a result, assigning a property to exactly its built-in default value does **not** force it to override the theme.

Example:

* built-in default `marker_size_px` is `12.0`
* the theme sets `scatter_marker_size_px` to `16`
* setting `style.marker_size_px = 12.0` does **not** override the theme

### Theming

`TauScatterStyle` reads theme values from the `TauScatter` **theme type variation**. Its base type is `Control`.

A theme resource using `TauScatter` must therefore include a base type declaration:

```gdscript
[resource]
TauScatter/base_type = &"Control"
TauScatter/constants/scatter_marker_size_px = 10
```

The following theme entries are used:

| Theme property | Description |
| --- | --- |
| `scatter_marker_size_px`:`int` | Maps to [`marker_size_px`](#marker_size_px) |
| `scatter_outline_width_px`: `int` | Maps to [`outline_width_px`](#outline_width_px) |
| `scatter_outline_color`: `Color` | Maps to [`outline_color`](#outline_color) |
| `scatter_hovered_marker_size_px`: `int` | Maps to [`hovered_marker_size_px`](#hovered_marker_size_px) |
| `scatter_hovered_outline_width_px`: `int` | Maps to [`hovered_outline_width_px`](#hovered_outline_width_px) |
| `scatter_hovered_outline_color`: `Color` | Maps to [`hovered_outline_color`](#hovered_outline_color) |
| `scatter_marker_shape_i`: `int` | Maps to [`marker_shapes[i]`](#marker_shapes) where `i` is the series index. |

Every entry above also supports a pane-indexed variant formed by appending an underscore and the zero-based pane index (for example, `scatter_marker_size_px_0`). The indexed variant overwrites the shared value when both are defined.

Example with two panes:

```gdscript
# Defaults for all panes.
TauScatter/constants/scatter_marker_size_px = 12 # All markers have a size of 12px by default
TauScatter/constants/scatter_marker_shape_0 = 0  # series 0: CIRCLE
TauScatter/constants/scatter_marker_shape_1 = 1  # series 1: SQUARE
TauScatter/constants/scatter_marker_shape_2 = 4  # series 2: DIAMOND

# But in pane 1 the markers are smaller.
TauScatter/constants/scatter_marker_size_px_1 = 8

# And series 0 in pane 1 uses PLUS shape instead.
TauScatter/constants/scatter_marker_shape_0_1 = 6  # series 0: PLUS
```

Series `0` in pane `0` uses `CIRCLE`. Series `0` in pane `1` uses `PLUS`. All other series use the global shapes in both panes.

### Side effects

All properties are **visual-only**. Every change triggers a redraw but never triggers layout recomputation.

### Notes

1. **Per-sample visual overrides.** [`ScatterVisualAttributes`](scatter_visual_attributes.md) and [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) can override fill color, alpha, [`outline_color`](#outline_color), [`outline_width_px`](#outline_width_px), [`marker_size_px`](#marker_size_px), and [`marker_shapes`](#marker_shapes) per sample. Fill color and alpha overrides take priority over [`TauXYStyle.series_colors`](xy_style.md#series_colors) and [`TauXYStyle.series_alpha`](xy_style.md#series_alpha).

## Enums

### `MarkerShape`

Controls the shape of the marker drawn at each scatter sample position.

| Value | Meaning |
|---|---|
| `CIRCLE` | Circular marker. |
| `SQUARE` | Square marker. |
| `TRIANGLE_UP` | Upward-pointing triangle marker. |
| `TRIANGLE_DOWN` | Downward-pointing triangle marker. |
| `DIAMOND` | Diamond marker. |
| `CROSS` | Cross-shaped marker (X shape). |
| `PLUS` | Plus-shaped marker (+ shape). |
| `COUNT` | The total number of distinct drawable shapes. Not a valid shape value for rendering. |
| `NONE` | Invisible marker. The sample retains its position for hit testing but no shape is drawn. |

## Constructor

### `new()`

```gdscript
TauScatterStyle.new() -> TauScatterStyle
```

Creates a new `TauScatterStyle` with all properties set to their built-in defaults. Properties left at their defaults remain theme-overridable.

## Properties

### marker_size_px

`marker_size_px`: `float`

The size in pixels of each scatter marker in its normal state. Default is `12.0`.

Can be overridden per sample (see note [1](#notes)).

---

### outline_width_px

`outline_width_px`: `float`

The stroke width in pixels of the marker outline in its normal state. Default is `1.0`. A value of `0.0` disables the outline entirely.

Can be overridden per sample (see note [1](#notes)).

---

### outline_color

`outline_color`: `Color`

The color of the marker outline in its normal state. Default is `Color(0, 0, 0, 1)`.

Can be overridden per sample (see note [1](#notes)).

---

### hovered_marker_size_px

`hovered_marker_size_px`: `float`

The size in pixels of a marker when it is hovered. Default is `16.0`.

---

### hovered_outline_width_px

`hovered_outline_width_px`: `float`

The stroke width in pixels of the marker outline when the marker is hovered. Default is `2.0`.

A value of `0.0` disables the outline on hover.

---

### hovered_outline_color

`hovered_outline_color`: `Color`

The color of the marker outline when the marker is hovered. Default is `Color(1, 1, 1, 1)`.

---

### marker_shapes

`marker_shapes`: `Array[MarkerShape]`

The ordered shape palette assigned to scatter series. Default is a seven-shape palette: [`CIRCLE`](#markershape), [`SQUARE`](#markershape), [`TRIANGLE_UP`](#markershape), [`TRIANGLE_DOWN`](#markershape), [`DIAMOND`](#markershape), [`CROSS`](#markershape), [`PLUS`](#markershape).

Shapes are assigned by series index in the [Dataset](dataset.md). The first series gets the shape at position `0`, the second gets position `1`, and so on. When the series index exceeds the last position in the palette, the palette wraps back to its first entry and continues from there. Assigning a non-empty array that differs from the built-in default replaces the palette entirely for that pane.

If the array is empty, all series fall back to [`CIRCLE`](#markershape). Can be overridden per sample (see note [1](#notes)).

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauScatterStyle` during rendering and theme resolution.
* [`TauScatterConfig`](scatter_config.md) Owns the `TauScatterStyle` instance via its [`style`](scatter_config.md#style) property.
* [`TauXYStyle`](xy_style.md) Sibling style resource for the whole plot.
* [`TauPaneStyle`](pane_style.md) Sibling style resource for individual panes.
* [`TauBarStyle`](bar_style.md) Sibling style resource for bar overlays.
* [`TauLegendStyle`](legend_style.md) Sibling style resource for the legend.
* [`TauTooltipStyle`](tooltip_style.md) Sibling style resource for the hover tooltip.
* [`TauCrosshairStyle`](crosshair_style.md) Sibling style resource for the hover crosshair.