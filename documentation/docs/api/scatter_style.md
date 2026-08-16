# TauScatterStyle

!!! info ""
    **Inherits:** [`TauStyle`](style.md)

Controls the visual appearance of scatter overlays.

## Description

A scatter overlay draws one marker per sample at its X and Y position in the pane. `TauScatterStyle` controls how those markers look: their size, their shape, the width and the color of their outline, and how the size and the outline change on the hovered marker.

The fill color of a marker is not a property of this class. It comes from [`TauXYStyle.series_colors`](xy_style.md#series_colors), with its alpha channel replaced by [`TauXYStyle.series_alphas`](xy_style.md#series_alphas).

Three properties are [cycles](style.md#cycles), holding one entry per series: [`marker_sizes_px`](#marker_sizes_px), [`hovered_marker_sizes_px`](#hovered_marker_sizes_px), and [`marker_shapes`](#marker_shapes). The outline properties are scalar and apply to every series of the overlay.

`TauScatterStyle` lives on [`TauScatterConfig.style`](scatter_config.md#style). It is created with [`TauScatterConfig`](scatter_config.md) and is never `null`. Several [`TauScatterConfig`](scatter_config.md) instances can share the same instance.

### Three-layer cascade

Each property is resolved in three layers: the built-in default, then the value the active Godot theme names, then the value assigned on this instance. A property counts as overridden as soon as it is assigned, whatever the value, and for an array property only assigning a new array counts.

See [`TauStyle`](style.md#three-layer-cascade) for the cascade and [`TauStyle`](style.md#theme-keys) for the grammar of the keys listed in [Theming](#theming).

### Theming

`TauScatterStyle` reads its keys from the `TauScatter` **theme type variation**, whose base type is `Control`.

A theme resource using `TauScatter` must include a base type declaration:

```gdscript
[resource]
TauScatter/base_type = &"Control"
TauScatter/constants/scatter_marker_size_px_0 = 10
```

The following theme entries are used:

| Theme property | Description |
| --- | --- |
| `scatter_marker_size_px_i`: `int` | Maps to entry `i` of [`marker_sizes_px`](#marker_sizes_px), in pixels. |
| `scatter_hovered_marker_size_px_i`: `int` | Maps to entry `i` of [`hovered_marker_sizes_px`](#hovered_marker_sizes_px), in pixels. |
| `scatter_marker_shape_i`: `int` | Maps to entry `i` of [`marker_shapes`](#marker_shapes). The value is a [`MarkerShape`](#markershape) member as an integer. Any other integer is an error and the entry falls back to [`CIRCLE`](#markershape). |
| `scatter_outline_width_px`: `int` | Maps to [`outline_width_px`](#outline_width_px). |
| `scatter_outline_color`: `Color` | Maps to [`outline_color`](#outline_color). |
| `scatter_hovered_outline_width_px`: `int` | Maps to [`hovered_outline_width_px`](#hovered_outline_width_px). |
| `scatter_hovered_outline_color`: `Color` | Maps to [`hovered_outline_color`](#hovered_outline_color). |

The three cycle keys carry a series index, written `i` in the table, and there is no key without one. `TauScatterStyle` describes the contents of a pane, so every key above also accepts a pane index appended as a further number: `scatter_marker_shape_0_1` names the first series of the second pane, `scatter_outline_color_1` the second pane.

### Side effects

All properties are **visual-only**. A change triggers a redraw and never a layout recomputation.

### Example

```gdscript
var scatter_overlay := TauScatterConfig.new()

# Four series come out circle, square, circle, square.
scatter_overlay.style.marker_shapes = [
	TauScatterStyle.MarkerShape.CIRCLE,
	TauScatterStyle.MarkerShape.SQUARE,
]
# One entry, so every series gets 8 pixel markers. No outline anywhere.
scatter_overlay.style.marker_sizes_px = [8.0]
scatter_overlay.style.outline_width_px = 0.0
```

### Notes

1. **The hovered size replaces the base size.** A hovered marker is drawn at its [`hovered_marker_sizes_px`](#hovered_marker_sizes_px) size, larger or smaller than its normal size. Under [`DATA_UNITS`](scatter_config.md#markersizepolicy) the normal size is in data units and the hovered size is still in pixels, so the two grow and shrink independently: pick the hovered size against the size the markers reach on screen, not against the data.

## Enums

### `MarkerShape`

Shape drawn at a sample position.

| Value | Meaning |
|---|---|
| `CIRCLE` | Filled disc. |
| `SQUARE` | Filled axis-aligned square. |
| `TRIANGLE_UP` | Filled triangle pointing up. |
| `TRIANGLE_DOWN` | Filled triangle pointing down. |
| `DIAMOND` | Filled square turned 45 degrees. |
| `CROSS` | Two diagonal strokes. |
| `PLUS` | One horizontal and one vertical stroke. |
| `COUNT` | The number of drawable shapes. Not a shape itself: assigning it is reported and draws a `CIRCLE`, like any other value outside the enum. |
| `NONE` | Draws nothing, hiding the markers of a series without removing its samples from the dataset. The samples still answer hover. |

## Constructor

### `new()`

```gdscript
TauScatterStyle.new() -> TauScatterStyle
```

Creates a `TauScatterStyle` holding the built-in default of every property.

## Properties

### marker_sizes_px

`marker_sizes_px`: `Array[float]`

Size of the marker of one series, in pixels. Default is `[DEFAULT_MARKER_SIZE_PX]`, which is `12.0`.

Read as a cycle: series `i` uses entry `i % size`, where `i` is the series index in the [`Dataset`](dataset.md). Entries below `1.0` are raised to `1.0` as the array is stored. An empty array falls back to `DEFAULT_MARKER_SIZE_PX` for every series. See [`TauStyle`](style.md#cycles).

Only read under [`TauScatterConfig.MarkerSizePolicy.THEME`](scatter_config.md#markersizepolicy). Under [`DATA_UNITS`](scatter_config.md#markersizepolicy) the size comes from [`TauScatterConfig.marker_size_data_units`](scatter_config.md#marker_size_data_units), except on a [categorical](axis_config.md#type) X axis where there is no data span to convert and this cycle applies again.

This property can be overridden per sample. See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for more information.

---

### outline_width_px

`outline_width_px`: `float`

Thickness in pixels of the outline stroked around every marker. Default is `1.0`.

`0.0` leaves the markers unoutlined. Values below `0.0` are raised to `0.0` on assignment, and the drawn outline never exceeds half the resolved marker size.

This property can be overridden per sample. See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for more information.

---

### outline_color

`outline_color`: `Color`

Color of the outline stroked around every marker. Default is `Color(0, 0, 0, 1)`.

The alpha of the resolved series is applied on top of it, so a marker and its outline fade together.

This property can be overridden per sample. See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for more information.

---

### hovered_marker_sizes_px

`hovered_marker_sizes_px`: `Array[float]`

Size of the hovered marker of one series, in pixels. Default is `[16.0]`.

Read as a cycle: series `i` uses entry `i % size`, where `i` is the series index in the [`Dataset`](dataset.md). Entries below `0.0` are raised to `0.0` as the array is stored. An empty array falls back to `0.0` for every series, a sentinel meaning no size change, which leaves the hovered marker at its [`marker_sizes_px`](#marker_sizes_px) size. See [`TauStyle`](style.md#cycles).

An entry of `0.0` reads as that same sentinel. The floor is `0.0` here and `1.0` on [`marker_sizes_px`](#marker_sizes_px), since only this cycle carries a no-change value. The size replaces rather than raises the base size, see [note 1](#notes).

Only the marker under the cursor takes the hovered size, so with the cursor between two markers the tooltip still lists them and neither one changes.

---

### hovered_outline_width_px

`hovered_outline_width_px`: `float`

Thickness in pixels of the outline stroked around the hovered marker. Default is `2.0`.

`0.0` leaves the hovered marker unoutlined. Values below `0.0` are raised to `0.0` on assignment, and the drawn outline never exceeds half the resolved marker size. A per-sample override of [`outline_width_px`](#outline_width_px) does not apply to the hovered marker.

---

### hovered_outline_color

`hovered_outline_color`: `Color`

Color of the outline stroked around the hovered marker. Default is `Color(1, 1, 1, 1)`.

The alpha of the resolved series is applied on top of it. A per-sample override of [`outline_color`](#outline_color) does not apply to the hovered marker.

---

### marker_shapes

`marker_shapes`: `Array[MarkerShape]`

Shape of the marker of one series. Default is the seven drawable shapes in declaration order, from [`CIRCLE`](#markershape) to [`PLUS`](#markershape).

Read as a cycle: series `i` uses entry `i % size`, where `i` is the series index in the [`Dataset`](dataset.md). An empty array falls back to [`CIRCLE`](#markershape) for every series. See [`TauStyle`](style.md#cycles).

An entry outside [`MarkerShape`](#markershape) draws a [`CIRCLE`](#markershape), and the plot reports it with an error naming the entry index and the value. A per-sample override outside [`MarkerShape`](#markershape) draws a [`CIRCLE`](#markershape) as well, with no message, since it is read once per sample.

This property can be overridden per sample. See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for more information.

## Related Classes

* [`TauStyle`](style.md) Base class. Defines the cascade, the cycle indexing, and the theme key grammar.
* [`TauScatterConfig`](scatter_config.md) Owns the `TauScatterStyle` instance through its [`style`](scatter_config.md#style) property. Its [`marker_size_policy`](scatter_config.md#marker_size_policy) decides whether [`marker_sizes_px`](#marker_sizes_px) is read.
* [`ScatterVisualAttributes`](scatter_visual_attributes.md) Supplies the per-sample size, shape, outline, color, and alpha buffers.
* [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) Supplies the same values as functions called at draw time.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class of [`TauScatterConfig`](scatter_config.md). Defines how a per-sample override is resolved.
* [`SampleHit`](sample_hit.md) Reports the hit that decides which marker is emphasized.
* [`TauAxisConfig`](axis_config.md) Configures the X axis whose type decides how a [`DATA_UNITS`](scatter_config.md#markersizepolicy) size is converted.
* [`Dataset`](dataset.md) Holds the series a cycle index refers to.
* [`TauPlot`](tau_plot.md) The plot node. Resolves the cascade and holds the Godot theme the second layer reads.
* [`TauXYStyle`](xy_style.md) Sibling style resource for the plot as a whole. Supplies the fill color of a marker.
* [`TauPaneStyle`](pane_style.md) Sibling style resource for the contents of one pane.
* [`TauBarStyle`](bar_style.md) Sibling style resource for bar overlays.
* [`TauLineStyle`](line_style.md) Sibling style resource for line overlays.
* [`TauLegendStyle`](legend_style.md) Sibling style resource for the legend.
* [`TauTooltipStyle`](tooltip_style.md) Sibling style resource for the hover tooltip.
* [`TauCrosshairStyle`](crosshair_style.md) Sibling style resource for the hover crosshair.