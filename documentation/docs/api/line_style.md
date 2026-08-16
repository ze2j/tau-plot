# TauLineStyle

!!! info ""
    **Inherits:** [`TauStyle`](style.md)

Controls the visual appearance of line overlays.

## Description

A line overlay draws one curve per series through its samples, in X order. `TauLineStyle` controls how those curves look: their width in the normal and in the hovered state, their dash length, and the [`TauLineFill`](line_fill.md) that paints the area around each of them.

The stroke color of a curve is not a property of this class. It comes from [`TauXYStyle.series_colors`](xy_style.md#series_colors), with its alpha channel replaced by [`TauXYStyle.series_alphas`](xy_style.md#series_alphas).

`TauLineStyle` lives on [`TauLineConfig.style`](line_config.md#style). It is created with [`TauLineConfig`](line_config.md) and is never `null`. Several [`TauLineConfig`](line_config.md) instances can share the same instance.

Every property is a [cycle](style.md#cycles), holding one entry per series. Three of them replace the themed cycle once assigned, the way a cycle normally does. [`fills`](#fills) is the exception: it merges with the themed cycle field by field, so a fill only has to carry what it changes. See [note 3](#notes).

### Three-layer cascade

Each property is resolved in three layers: the built-in default, then the value the active Godot theme names, then the value assigned on this instance. A property counts as overridden as soon as it is assigned, whatever the value, and for an array property only assigning a new array counts.

See [`TauStyle`](style.md#three-layer-cascade) for the cascade and [`TauStyle`](style.md#theme-keys) for the grammar of the keys listed in [Theming](#theming).

### Theming

`TauLineStyle` reads its keys from the `TauLine` **theme type variation**, whose base type is `Control`.

A theme resource using `TauLine` must include a base type declaration:

```gdscript
[resource]
TauLine/base_type = &"Control"
TauLine/constants/line_width_px_0 = 3
```

The following theme entries are used:

| Theme property | Description |
| --- | --- |
| `line_width_px_i`: `int` | Maps to entry `i` of [`line_widths_px`](#line_widths_px), in pixels. |
| `line_hovered_width_px_i`: `int` | Maps to entry `i` of [`hovered_line_widths_px`](#hovered_line_widths_px), in pixels. |
| `line_dash_px_i`: `int` | Maps to entry `i` of [`dash_lengths_px`](#dash_lengths_px), in pixels. |

Every key carries a series index, written `i` in the table, and there is no key without one. `TauLineStyle` describes the contents of a pane, so every key also accepts a pane index appended as a further number: `line_width_px_0_1` names the first series of the second pane.

[`fills`](#fills) has no key of its own. A [`TauLineFill`](line_fill.md) reads its own keys, from this same `TauLine` theme type variation and under the same two-level indexing, and they are listed on [`TauLineFill`](line_fill.md#theming). Each of its fields scans its series index on its own, so a theme may define more entries for one field than for another.

### Side effects

All properties are **visual-only**. A change triggers a redraw and never a layout recomputation.

### Example

```gdscript
var line_overlay := TauLineConfig.new()

# Four series come out 1 pixel, 3 pixels, 1 pixel, 3 pixels.
line_overlay.style.line_widths_px = [1.0, 3.0]

# The second series is dashed, the others solid.
line_overlay.style.dash_lengths_px = [0, 6]
```

### Notes

1. **Zero width draws no line.** An entry of `0` in [`line_widths_px`](#line_widths_px) draws no line for that series and leaves only its [`TauLineFill`](line_fill.md), the way to get an area chart with no outline. Such a series still reports hover on its samples. A series with neither a line nor a fill paints nothing and answers no hover. With every entry of the cycle at `0` and no fill left painting, the whole overlay comes out blank and the plot pushes a warning when the style is resolved.

2. **Hovered width never goes below the base width.** A series whose [`hovered_line_widths_px`](#hovered_line_widths_px) entry sits below its [`line_widths_px`](#line_widths_px) entry is drawn at the base width instead, so a thick series never becomes thinner on hover.

3. **`fills` merges instead of replacing.** [`line_widths_px`](#line_widths_px), [`hovered_line_widths_px`](#hovered_line_widths_px), and [`dash_lengths_px`](#dash_lengths_px) drop the themed cycle entirely once assigned. [`fills`](#fills) does not: each entry merges with the themed [`TauLineFill`](line_fill.md) at the same position, field by field, so an assigned field wins and an unassigned one keeps what the theme gave it. A `null` entry leaves its whole position to the theme, and an empty array leaves the themed cycle untouched. When the two cycles differ in length, the resolved cycle is as long as the longer one and the shorter one repeats to fill it.

## Constructor

### `new()`

```gdscript
TauLineStyle.new() -> TauLineStyle
```

Creates a `TauLineStyle` holding the built-in default of every property.

## Properties

### line_widths_px

`line_widths_px`: `Array[float]`

Width of the curve of one series in the normal state, in pixels. Default is `[2.0]`.

Read as a cycle: series `i` uses entry `i % size`, where `i` is the series index in the [`Dataset`](dataset.md). Entries below `0.0` are raised to `0.0` as the array is stored. An empty array falls back to `2.0` for every series. See [`TauStyle`](style.md#cycles).

An entry of `0` draws no line, see [note 1](#notes).

---

### hovered_line_widths_px

`hovered_line_widths_px`: `Array[float]`

Width of the two segments adjacent to the hovered sample, in pixels. Default is `[3.0]`.

Read as a cycle: series `i` uses entry `i % size`, where `i` is the series index in the [`Dataset`](dataset.md). Entries below `0.0` are raised to `0.0` as the array is stored. An empty array falls back to `0.0` for every series, a sentinel meaning no hover emphasis, which leaves those segments at the [`line_widths_px`](#line_widths_px) width. See [`TauStyle`](style.md#cycles).

An entry of `0.0` reads as that same sentinel, since a width below the base width is drawn at the base width, see [note 2](#notes).

The curve running nearest the cursor is the one emphasized, and a series drawn at width `0` has no curve to emphasize.

---

### dash_lengths_px

`dash_lengths_px`: `Array[int]`

Length of one dash of the curve of one series, with an equal gap between dashes, in pixels. Default is `[0]`.

Read as a cycle: series `i` uses entry `i % size`, where `i` is the series index in the [`Dataset`](dataset.md). Entries below `0` are raised to `0` as the array is stored. An empty array falls back to `0` for every series. See [`TauStyle`](style.md#cycles).

An entry of `0` draws a solid line.

---

### fills

`fills`: `Array[TauLineFill]`

Area painted around the curve of one series. Default is an empty array, which paints nothing.

Read as a cycle: series `i` uses entry `i % size`, where `i` is the series index in the [`Dataset`](dataset.md). An empty array falls back to a [`TauLineFill`](line_fill.md) at its own built-in defaults for every series. See [`TauStyle`](style.md#cycles).

This cycle merges with the themed one rather than replacing it, and a `null` entry is legal, see [note 3](#notes).

## Related Classes

* [`TauStyle`](style.md) Base class. Defines the cascade, the cycle indexing, the theme key grammar, and the field-by-field merge.
* [`TauLineConfig`](line_config.md) Owns the `TauLineStyle` instance through its [`style`](line_config.md#style) property.
* [`TauLineFill`](line_fill.md) Describes the area painted around one curve. Held in [`fills`](#fills) and themed under the same theme type variation.
* [`LineVisualAttributes`](line_visual_attributes.md) Supplies the per-sample color and alpha buffers a curve is stroked with.
* [`LineVisualCallbacks`](line_visual_callbacks.md) Supplies the same values as functions called at draw time.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class of [`TauLineConfig`](line_config.md). Defines how a per-sample override is resolved.
* [`SampleHit`](sample_hit.md) Reports the hit that decides which curve is emphasized.
* [`Dataset`](dataset.md) Holds the series a cycle index refers to.
* [`TauPlot`](tau_plot.md) The plot node. Resolves the cascade and holds the Godot theme the second layer reads.
* [`TauXYStyle`](xy_style.md) Sibling style resource for the plot as a whole. Supplies the stroke color of a curve through [`series_colors`](xy_style.md#series_colors) and [`series_alphas`](xy_style.md#series_alphas).
* [`TauPaneStyle`](pane_style.md) Sibling style resource for the contents of one pane.
* [`TauBarStyle`](bar_style.md) Sibling style resource for bar overlays.
* [`TauScatterStyle`](scatter_style.md) Sibling style resource for scatter overlays.
* [`TauLegendStyle`](legend_style.md) Sibling style resource for the legend.
* [`TauTooltipStyle`](tooltip_style.md) Sibling style resource for the hover tooltip.
* [`TauCrosshairStyle`](crosshair_style.md) Sibling style resource for the hover crosshair.