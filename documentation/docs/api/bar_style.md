# TauBarStyle

!!! info ""
    **Inherits:** [`TauStyle`](style.md)

Controls the visual appearance of bar overlays.

## Description

A bar overlay draws one bar per sample at its X position in the pane. `TauBarStyle` controls how those bars look: their width and intragroup gap under the `THEME` width policy, the `StyleBox` that gives them their shape, their corner radii and their border, and the `StyleBox` that replaces it on the hovered bar.

The fill color of a bar is not a property of this class. It comes from [`TauXYStyle.series_colors`](xy_style.md#series_colors), with its alpha channel replaced by [`TauXYStyle.series_alphas`](xy_style.md#series_alphas).

`TauBarStyle` lives on [`TauBarConfig.style`](bar_config.md#style). It is created with [`TauBarConfig`](bar_config.md) and is never `null`. Several [`TauBarConfig`](bar_config.md) instances can share the same instance.

### Three-layer cascade

Each property is resolved in three layers: the built-in default, then the value the active Godot theme names, then the value assigned on this instance. A property counts as overridden as soon as it is assigned, whatever the value, and for an array property only assigning a new array counts.

See [`TauStyle`](style.md#three-layer-cascade) for the cascade and [`TauStyle`](style.md#theme-keys) for the grammar of the keys listed in [Theming](#theming).

### Theming

`TauBarStyle` reads its keys from the `TauBar` **theme type variation**, whose base type is `Control`.

A theme resource using `TauBar` must include a base type declaration:

```gdscript
[resource]
TauBar/base_type = &"Control"
TauBar/constants/bar_width_px = 48
```

The following theme entries are used:

| Theme property | Description |
| --- | --- |
| `bar_width_px`: `int` | Maps to [`bar_width_px`](#bar_width_px). |
| `bar_intragroup_gap_px`: `int` | Maps to [`bar_intragroup_gap_px`](#bar_intragroup_gap_px). |
| `bar_style_box`: `StyleBox` | Maps to [`style_box`](#style_box). |
| `bar_hovered_style_box`: `StyleBox` | Maps to [`hovered_style_box`](#hovered_style_box). |

`TauBarStyle` describes the contents of a pane, so every key above accepts a pane index appended as a number: `bar_width_px_1` names the second pane alone.

### Side effects

All properties are **visual-only**. A change triggers a redraw and never a layout recomputation.

### Example

```gdscript
var bar_overlay := TauBarConfig.new()

var box := StyleBoxFlat.new()
# Authored as if the bar grew upward, see note 1.
box.corner_radius_top_left = 6
box.corner_radius_top_right = 6
bar_overlay.style.style_box = box
```

### Notes

1. **Corner radii and borders are authored upward.** A `StyleBoxFlat` is read as if the bar grew upward from the baseline, and the plot remaps it to the direction the bar actually grows in. Rounding the top two corners rounds the tip of the bar on an inverted Y axis and on a horizontal one alike.

2. **The hovered box wins over the callback.** [`hovered_style_box`](#hovered_style_box) is applied after [`BarVisualCallbacks.style_box_callback`](bar_visual_callbacks.md#style_box_callback), so the callback picks the shape of every bar except the hovered one.

## Constructor

### `new()`

```gdscript
TauBarStyle.new() -> TauBarStyle
```

Creates a `TauBarStyle` holding the built-in default of every property.

## Properties

### bar_width_px

`bar_width_px`: `int`

Width of one bar in pixels. Default is `64`.

Only read under [`TauBarConfig.BarWidthPolicy.THEME`](bar_config.md#barwidthpolicy). The other width policies derive the width from the category slot or from the local sample spacing and ignore this property.

Values below `1` are raised to `1` on assignment.

---

### bar_intragroup_gap_px

`bar_intragroup_gap_px`: `int`

Gap in pixels between two bars of the same group. Default is `0`.

Only read under [`TauBarConfig.BarWidthPolicy.THEME`](bar_config.md#barwidthpolicy), and only in [`GROUPED`](bar_config.md#barmode) mode, the one mode where several series share an X position.

Values below `0` are raised to `0` on assignment.

---

### style_box

`style_box`: `StyleBox`

`StyleBox` every bar is drawn with in its normal state. Default is `null`, resolving to a square-cornered `StyleBoxFlat` with no border and no content margin.

The accepted concrete types are `StyleBoxFlat` and `StyleBoxTexture`. Any other subclass pushes an error and the bar falls back to the built-in default. `StyleBoxFlat.bg_color` and `StyleBoxTexture.modulate_color` are ignored, since the fill color comes from [`TauXYStyle.series_colors`](xy_style.md#series_colors). Corner radii and borders are remapped, see [note 1](#notes).

Assigning `null` marks the property like any other assignment, so the theme no longer writes it and the bars fall back to the built-in default.

Assign a new `StyleBox` rather than mutating the one already assigned. A change made in place is not detected and the plot keeps the previous resolution.

This property can be overridden per sample. See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for more information.

---

### hovered_style_box

`hovered_style_box`: `StyleBox`

`StyleBox` the hovered bar is drawn with, replacing [`style_box`](#style_box) for that bar alone. Default is `null`, resolving to the [`style_box`](#style_box) default plus a 2 pixel white border on all sides.

The type, color, and remapping rules of [`style_box`](#style_box) apply here as well. Only the bar under the cursor takes it, so with the cursor between two bars the tooltip still lists them and neither one changes. Under [`X_ALIGNED`](hover_config.md#hovermode) hover a [`GROUPED`](bar_config.md#barmode) overlay is the exception: every bar of the hovered category takes it together. The order against the per-sample callback is in [note 2](#notes).

## Related Classes

* [`TauStyle`](style.md) Base class. Defines the cascade, the cycle indexing, and the theme key grammar.
* [`TauBarConfig`](bar_config.md) Owns the `TauBarStyle` instance through its [`style`](bar_config.md#style) property.
* [`BarVisualCallbacks`](bar_visual_callbacks.md) Supplies the per-sample `StyleBox` that [`style_box`](#style_box) falls back to.
* [`BarVisualAttributes`](bar_visual_attributes.md) Supplies the per-sample color and alpha buffers.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class of [`TauBarConfig`](bar_config.md). Defines how a per-sample override is resolved.
* [`SampleHit`](sample_hit.md) Reports the hit that decides which bar is emphasized.
* [`TauHoverConfig`](hover_config.md) Decides whether hover emphasis happens at all.
* [`TauPlot`](tau_plot.md) The plot node. Resolves the cascade and holds the Godot theme the second layer reads.
* [`TauXYStyle`](xy_style.md) Sibling style resource for the plot as a whole. Supplies the fill color of a bar.
* [`TauPaneStyle`](pane_style.md) Sibling style resource for the contents of one pane.
* [`TauScatterStyle`](scatter_style.md) Sibling style resource for scatter overlays.
* [`TauLineStyle`](line_style.md) Sibling style resource for line overlays.
* [`TauLegendStyle`](legend_style.md) Sibling style resource for the legend.
* [`TauTooltipStyle`](tooltip_style.md) Sibling style resource for the hover tooltip.
* [`TauCrosshairStyle`](crosshair_style.md) Sibling style resource for the hover crosshair.