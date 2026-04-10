# TauLegendStyle

!!! info ""
    **Inherits:** `Resource`  

Controls the visual appearance of the legend.

## Description

`TauLegendStyle` controls the appearance of the legend rendered by `TauPlot`.

The legend shows one item per visible series. Each item contains:

* a **key strip**, which displays one key for each [`overlay_type`](tau_plot.md#paneoverlaytype) used by the series
* a **label**, which displays the series name

For example, if one series is drawn both as bars and as scatter markers, its legend item shows **two keys** before the label.

### Three-layer cascade

Each property's final value is resolved through the following cascade, in order:

1. **Built-in default**  
    The final value starts from the built-in default.

2. **Theme value**  
    If the active Godot theme defines a matching legend property, that value replaces the built-in default.

3. **User override**  
    If the property is explicitly set on the `TauLegendStyle` instance, that value overrides both the theme and the built-in default.

In short:

- the last layer that provides a value wins
- the Godot theme is suited for **project-wide styling**
- `TauLegendStyle` is suited for **per-plot styling**

**Override detection limitation**

A property is considered overridden only when its value differs from the corresponding built-in default constant.

As a result, assigning a property to exactly its built-in default value does **not** force it to override the theme.

Example:

* built-in default `font_size` is `14`
* the theme sets `font_size` to `18`
* setting `style.font_size = 14` does **not** override the theme

### Theming

`TauLegendStyle` reads theme values from the `TauLegend` **theme type variation**. Its base type is `PanelContainer`.

A theme resource using `TauLegend` must therefore include a base type declaration:

```gdscript
[resource]
TauLegend/base_type = &"PanelContainer"
TauLegend/constants/legend_key_label_gap_px = 8
```

The following theme entries are used:

| Theme property | Description |
| --- | --- |
| `font`: `Font` | Maps to [`font`](#font) |
| `font_size`: `int` | Maps to [`font_size`](#font_size) |
| `font_color`: `Color` | Maps to [`font_color`](#font_color) |
| `legend_key_size_px`: `int` | Maps to [`key_size_px`](#key_size_px) |
| `legend_key_gap_px`: `int` | Maps to [`key_gap_px`](#key_gap_px) |
| `legend_key_label_gap_px`: `int` | Maps to [`key_label_gap_px`](#key_label_gap_px) |
| `legend_item_gap_px`: `int` | Maps to [`item_gap_px`](#item_gap_px) |
| `legend_background`: `StyleBox` | Maps to [`background`](#background) |
| `legend_margin_px`: `int` | Maps to [`margin_px`](#margin_px) |
| `legend_max_size_px`: `int` | Maps to [`max_size_px`](#max_size_px) |

### Side effects

Some property changes trigger a full layout recomputation. Others only trigger a redraw.

**Layout-affecting** (trigger both layout and redraw): [`font`](#font), [`font_size`](#font_size), [`key_size_px`](#key_size_px), [`key_gap_px`](#key_gap_px), [`key_label_gap_px`](#key_label_gap_px), [`item_gap_px`](#item_gap_px), [`background`](#background), [`margin_px`](#margin_px), [`max_size_px`](#max_size_px).

**Visual-only** (trigger redraw only): [`font_color`](#font_color).

## Constructor

### `new()`

```gdscript
TauLegendStyle.new() -> TauLegendStyle
```

Creates a new `TauLegendStyle` with all properties set to their built-in defaults. Properties left at their defaults remain theme-overridable.

## Properties

### font

`font`: `Font`

The font used to render series labels in the legend. Default is `null`.

If `null`, the plot reads the font from the Godot theme entry `font` on the `TauLegend` type variation. If the theme does not define it either, Godot's built-in default font applies.

---

### font_size

`font_size`: `int`

The font size in pixels used for series labels. Default is `14`.

---

### font_color

`font_color`: `Color`

The color used to render series labels. Default is `Color(1, 1, 1, 1)`.

---

### key_size_px

`key_size_px`: `int`

The side length in pixels of each key in the key strip. Default is `12`.

---

### key_gap_px

`key_gap_px`: `int`

The pixel gap between adjacent keys within the same key strip. Default is `2`.

This applies only when a series is bound to more than one [overlay type](tau_plot.md#paneoverlaytype).

---

### key_label_gap_px

`key_label_gap_px`: `int`

The pixel gap between the key strip and the series label. Default is `6`.

---

### item_gap_px

`item_gap_px`: `int`

The pixel gap between separate legend items in the legend `FlowContainer`. Default is `8`.

This value is applied as both the horizontal and vertical separation of the container.

---

### background

`background`: `StyleBox`

The `StyleBox` drawn behind the legend. Default is `null` and fallbacks to a fully transparent `StyleBoxFlat` with 8-pixel content margins on all sides is used.

Assigning any non-null `StyleBox` replaces the background entirely, including that transparent fallback.

---

### margin_px

`margin_px`: `int`

The pixel inset from the data area edge when the legend uses an `INSIDE_*` position. Default is `8`.

For corner positions, this applies on both axes. For edge-centered positions, it applies only on the perpendicular axis.

---

### max_size_px

`max_size_px`: `int`

The maximum size in pixels along the cross-axis of the legend flow direction. Default is `0`.

A value of `0` disables the constraint.

For horizontal flow (`OUTSIDE_TOP`, `OUTSIDE_BOTTOM`, `INSIDE_TOP`, `INSIDE_BOTTOM`), this limits the height.

For vertical flow (`OUTSIDE_LEFT`, `OUTSIDE_RIGHT`, `INSIDE_LEFT`, `INSIDE_RIGHT`), this limits the width.

When the content exceeds this limit, the legend becomes scrollable along the cross-axis.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Accepts `TauLegendConfig` via [`legend_config`](tau_plot.md#legend_config).
* [`TauLegendConfig`](xy_style.md) Owns the `TauLegendStyle` instance via its [`style`](legend_config.md#style) property.
* [`TauXYStyle`](xy_style.md) Sibling style resource for the whole plot.
* [`TauPaneStyle`](pane_style.md) Sibling style resource of individual panes.
* [`TauTooltipStyle`](tooltip_style.md) Sibling style resource of the hover tooltip.
* [`TauCrosshairStyle`](crosshair_style.md) Sibling style resource of the hover crosshair.
