# TauTooltipStyle

!!! info ""
    **Inherits:** `Resource`  

Controls the visual appearance of the hover tooltip popup.

## Description

`TauTooltipStyle` controls how the tooltip popup looks: its background, font, text color, internal padding, position offset, and maximum width before text wraps.

The tooltip appears in two states. A **transient** tooltip follows the cursor or snaps to the hovered sample and disappears when the cursor moves away. A **pinned** tooltip stays visible after a click and is dismissed explicitly. `TauTooltipStyle` provides a dedicated `StyleBox` for each state: [`style_box`](#style_box) and [`pinned_style_box`](#pinned_style_box).

`TauTooltipStyle` is assigned to [`TauHoverConfig.tooltip_style`](hover_config.md#tooltip_style). It is created automatically when [`TauHoverConfig`](hover_config.md) is instantiated, so it is never `null`.

### Three-layer cascade

Each property's final value is resolved through the following cascade, in order:

1. **Built-in default**  
    The final value starts from the built-in default.

2. **Theme value**  
    If the active Godot theme defines a matching tooltip property, that value replaces the built-in default.

3. **User override**  
    If the property is explicitly set on the `TauTooltipStyle` instance, that value overrides both the theme and the built-in default.

In short:

- the last layer that provides a value wins
- the Godot theme is suited for **project-wide styling**
- `TauTooltipStyle` is suited for **per-plot styling**

**Override detection limitation**

A property is considered overridden only when its value differs from the corresponding built-in default constant. For `StyleBox` and `Font` properties, a non-`null` value is treated as an override.

As a result, assigning a scalar property to exactly its built-in default value does **not** force it to override the theme.

Example:

* built-in default `padding_px` is `8`
* the theme sets `tooltip_padding` to `12`
* setting `style.padding_px = 8` does **not** override the theme

### Theming

`TauTooltipStyle` reads theme values from the `TauTooltip` **theme type variation**. Its base type is `Control`.

A theme resource using `TauTooltip` must therefore include a base type declaration:

```gdscript
[resource]
TauTooltip/base_type = &"Control"
TauTooltip/constants/tooltip_padding = 12
```

The following theme entries are used:

| Theme property | Description |
| --- | --- |
| `tooltip_style_box`: `StyleBox` | Maps to [`style_box`](#style_box) |
| `tooltip_pinned_style_box`: `StyleBox` | Maps to [`pinned_style_box`](#pinned_style_box) |
| `font`: `Font` | Maps to [`font`](#font) |
| `font_size`: `int` | Maps to [`font_size`](#font_size) |
| `font_color`: `Color` | Maps to [`font_color`](#font_color) |
| `tooltip_padding`: `int` | Maps to [`padding_px`](#padding_px) |
| `tooltip_offset_x`: `int` | Maps to the X component of [`offset_px`](#offset_px) |
| `tooltip_offset_y`: `int` | Maps to the Y component of [`offset_px`](#offset_px) |
| `tooltip_max_width`: `int` | Maps to [`max_width_px`](#max_width_px) |

### Side effects

All properties are **visual-only**. Every change triggers a redraw but never triggers layout recomputation.

## Constructor

### `new()`

```gdscript
TauTooltipStyle.new() -> TauTooltipStyle
```

Creates a new `TauTooltipStyle` with all properties set to their built-in defaults. Properties left at their defaults remain theme-overridable.

## Properties

### style_box

`style_box`: `StyleBox`

The `StyleBox` drawn behind the transient tooltip. Default is `null`.

If `null`, the renderer uses a `StyleBoxFlat` with a dark semi-transparent background (`Color(0.1, 0.1, 0.1, 0.85)`) and 4-pixel corner radii on all corners.

The accepted concrete types are `StyleBoxFlat` and `StyleBoxTexture`. Assigning any non-`null` `StyleBox` replaces the default entirely.

---

### pinned_style_box

`pinned_style_box`: `StyleBox`

The `StyleBox` drawn behind the pinned tooltip. Default is `null`.

If `null`, the renderer falls back to [`style_box`](#style_box). When set, it replaces the fallback entirely for pinned tooltips, which allows a visual distinction between the transient and pinned states.

The built-in pinned default uses a slightly more opaque background (`Color(0.1, 0.1, 0.1, 0.95)`) and a 1-pixel white border with 30% alpha on all sides.

The same rules apply as for [`style_box`](#style_box).

---

### font

`font`: `Font`

The font used to render the tooltip text. Default is `null`.

If `null`, Godot's built-in default font applies.

---

### font_size

`font_size`: `int`

The font size in pixels used for the tooltip text. Default is `14`.

---

### font_color

`font_color`: `Color`

The color used to render the tooltip text. Default is `Color(1, 1, 1, 1)`.

---

### padding_px

`padding_px`: `int`

The padding in pixels between the tooltip border and its text content. Default is `8`.

This value is applied uniformly on all sides.

---

### offset_px

`offset_px`: `Vector2i`

The pixel offset from the anchor point to the top-left corner of the tooltip. Default is `Vector2i(12, -12)`.

The anchor point is either the hovered sample position or the cursor position, depending on [`TauHoverConfig.tooltip_position_mode`](hover_config.md#tooltip_position_mode). When the offset would place the tooltip outside the plot bounds, the renderer flips the sign of the affected axis component to keep the tooltip visible.

---

### max_width_px

`max_width_px`: `int`

The maximum width in pixels of the tooltip before text wraps. Default is `300`.

A value of `0` disables the constraint and lets the tooltip grow as wide as its content requires.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauTooltipStyle` during rendering and theme resolution.
* [`TauHoverConfig`](hover_config.md) Owns the `TauTooltipStyle` instance via its [`tooltip_style`](hover_config.md#tooltip_style) property.
* [`TauXYStyle`](xy_style.md) Provides the fallback font and font size when [`font`](#font) and [`font_size`](#font_size) are not overridden.
* [`TauPaneStyle`](pane_style.md) Sibling style resource for individual panes.
* [`TauBarStyle`](bar_style.md) Sibling style resource for bar overlays.
* [`TauScatterStyle`](scatter_style.md) Sibling style resource for scatter overlays.
* [`TauLegendStyle`](legend_style.md) Sibling style resource for the legend.
* [`TauCrosshairStyle`](crosshair_style.md) Sibling style resource for the hover crosshair.
