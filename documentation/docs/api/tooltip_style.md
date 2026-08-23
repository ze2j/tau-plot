# TauTooltipStyle

!!! info ""
    **Inherits:** [`TauStyle`](style.md)

Controls the visual appearance of the hover tooltip.

## Description

The tooltip is the popup listing the samples under the cursor. It appears in two states. A **transient** tooltip follows the cursor or snaps to the hovered sample and goes away when the cursor leaves. A **pinned** tooltip stays after a click and is dismissed explicitly.

`TauTooltipStyle` controls how that popup looks: its background in each of the two states, the font and the color of its text, its internal padding, its offset from the anchor point, and the width past which its text wraps. What the text says is decided by [`TauHoverConfig`](hover_config.md), not here.

`TauTooltipStyle` lives on [`TauHoverConfig.tooltip_style`](hover_config.md#tooltip_style). It is created with [`TauHoverConfig`](hover_config.md) and is never `null`. Several [`TauHoverConfig`](hover_config.md) instances can share the same instance.

### Three-layer cascade

Each property is resolved in three layers: the built-in default, then the value the active Godot theme names, then the value assigned on this instance. A property counts as overridden as soon as it is assigned, whatever the value, and for an array property only assigning a new array counts.

See [`TauStyle`](style.md#three-layer-cascade) for the cascade and [`TauStyle`](style.md#theme-keys) for the grammar of the keys listed in [Theming](#theming).

### Theming

`TauTooltipStyle` reads its keys from the `TauTooltip` **theme type variation**, whose base type is `Control`.

A theme resource using `TauTooltip` must include a base type declaration:

```gdscript
[resource]
TauTooltip/base_type = &"Control"
TauTooltip/constants/tooltip_padding = 12
```

The following theme entries are used:

| Theme property | Description |
| --- | --- |
| `tooltip_style_box`: `StyleBox` | Maps to [`style_box`](#style_box). |
| `tooltip_pinned_style_box`: `StyleBox` | Maps to [`pinned_style_box`](#pinned_style_box). |
| `font`: `Font` | Maps to [`font`](#font). |
| `font_size`: `int` | Maps to [`font_size`](#font_size). |
| `font_color`: `Color` | Maps to [`font_color`](#font_color). |
| `tooltip_padding`: `int` | Maps to [`padding_px`](#padding_px). |
| `tooltip_offset_x`: `int` | Maps to the X component of [`offset_px`](#offset_px). |
| `tooltip_offset_y`: `int` | Maps to the Y component of [`offset_px`](#offset_px). |
| `tooltip_max_width`: `int` | Maps to [`max_width_px`](#max_width_px). |

The plot draws one tooltip at a time, so no key takes a pane index.

### Side effects

All properties are **visual-only**. A change triggers a redraw and never a layout recomputation.

### Example

```gdscript
var hover := TauHoverConfig.new()

var box := StyleBoxFlat.new()
box.bg_color = Color(0, 0, 0, 0.9)
box.corner_radius_top_left = 8
box.corner_radius_top_right = 8
box.corner_radius_bottom_left = 8
box.corner_radius_bottom_right = 8

# The pinned tooltip keeps this background, having none of its own.
hover.tooltip_style.style_box = box
hover.tooltip_style.padding_px = 12
```

## Constructor

### `new()`

```gdscript
TauTooltipStyle.new() -> TauTooltipStyle
```

Creates a `TauTooltipStyle` holding the built-in default of every property.

## Properties

### style_box

`style_box`: `StyleBox`

`StyleBox` drawn behind the transient tooltip. Default is `null`, resolving to a `StyleBoxFlat` with a dark semi-transparent background, `Color(0.1, 0.1, 0.1, 0.85)`, and a 4 pixel radius on every corner.

Assign a new `StyleBox` rather than mutating the one already assigned. A change made in place is not detected and the plot keeps the previous resolution.

---

### pinned_style_box

`pinned_style_box`: `StyleBox`

`StyleBox` drawn behind the pinned tooltip, which is how a pinned tooltip is told apart from a transient one. Default is `null`, resolving to the [`style_box`](#style_box) default at a higher opacity, `Color(0.1, 0.1, 0.1, 0.95)`, plus a 1 pixel border at 30 percent white on all sides.

A resolved value of `null` draws the pinned tooltip with [`style_box`](#style_box) instead.

Assign a new `StyleBox` rather than mutating the one already assigned. A change made in place is not detected and the plot keeps the previous resolution.

---

### font

`font`: `Font`

Font of the tooltip text. Default is `null`.

The font comes from the `font` theme property of the `TauTooltip` type variation when the theme sets it, and from the font Godot uses by default otherwise.

A font assigned here replaces the themed one. Assigning `null` is an assignment like any other: it drops the themed font, and the tooltip text is drawn in the font Godot uses by default.

Assign a new `Font` rather than mutating the one already assigned. A change made in place is not detected and the plot keeps the previous resolution.

---

### font_size

`font_size`: `int`

Size in pixels of the tooltip text. Default is `16`.

The size comes from the `font_size` theme property of the `TauTooltip` type variation when the theme sets it, and from the theme's own default font size otherwise. In a stock project that default is `16`.

A size assigned here replaces the themed one.

Values below `1` are raised to `1` on assignment.

---

### font_color

`font_color`: `Color`

Color of the tooltip text. Default is `Color(1, 1, 1, 1)`.

A tooltip built by [`TauHoverConfig.create_tooltip_control`](hover_config.md#create_tooltip_control) paints its own content and reads none of the text properties.

---

### padding_px

`padding_px`: `int`

Padding in pixels between the border of the tooltip and its content. Default is `8`.

Applied on all four sides. Values below `0` are raised to `0` on assignment.

---

### offset_px

`offset_px`: `Vector2i`

Offset in pixels from the anchor point to the top left corner of the tooltip. Default is `Vector2i(12, -12)`.

The anchor point is the hovered sample position or the cursor position, following [`TauHoverConfig.tooltip_position_mode`](hover_config.md#tooltip_position_mode). When the offset would push the tooltip past the edge of the plot, the plot flips the sign of the component at fault to keep it visible.

---

### max_width_px

`max_width_px`: `int`

Width in pixels past which the tooltip text wraps. Default is `300`.

`0` applies no cap and lets the tooltip grow as wide as its content. Values below `0` are raised to `0` on assignment.

## Related Classes

* [`TauStyle`](style.md) Base class. Defines the cascade, the cycle indexing, and the theme key grammar.
* [`TauHoverConfig`](hover_config.md) Owns the `TauTooltipStyle` instance through its [`tooltip_style`](hover_config.md#tooltip_style) property, and decides what the tooltip says and where it sits.
* [`SampleHit`](sample_hit.md) One hit reported under the cursor, the material the tooltip text is built from.
* [`TauPlot`](tau_plot.md) The plot node. Resolves the cascade and holds the Godot theme the second layer reads.
* [`TauXYStyle`](xy_style.md) Sibling style resource for the plot as a whole.
* [`TauPaneStyle`](pane_style.md) Sibling style resource for the contents of one pane.
* [`TauBarStyle`](bar_style.md) Sibling style resource for bar overlays.
* [`TauScatterStyle`](scatter_style.md) Sibling style resource for scatter overlays.
* [`TauLineStyle`](line_style.md) Sibling style resource for line overlays.
* [`TauLegendStyle`](legend_style.md) Sibling style resource for the legend.
* [`TauCrosshairStyle`](crosshair_style.md) Sibling style resource for the hover crosshair.