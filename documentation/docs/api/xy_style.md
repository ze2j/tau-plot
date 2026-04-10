# TauXYStyle

!!! info ""
    **Inherits:** `Resource`  

Controls the visual appearance the XY plot.

## Description

`TauXYStyle` controls axis colors, tick dimensions, tick label gaps, plot padding, pane spacing, and the series color palette for an XY plot rendered by `TauPlot`.

`TauXYStyle` lives on [`TauXYConfig.style`](xy_config.md#style). It is created automatically when `TauXYConfig` is instantiated, so it is never `null`.

### Three-layer cascade

Each property's final value is resolved through the following cascade, in order:

1. **Built-in default**  
    The final value starts from the built-in default.

2. **Theme value**  
    If the active Godot theme defines a matching property on the `TauPlot` node, that value replaces the built-in default.

3. **User override**  
    If the property is explicitly set on the `TauXYStyle` instance, that value overrides both the theme and the built-in default.

In short:

- the last layer that provides a value wins
- the Godot theme is suited for **project-wide styling**
- `TauXYStyle` is suited for **per-plot styling**

**Override detection limitation**

A property is considered overridden only when its value differs from the corresponding built-in default constant.

As a result, assigning a property to exactly its built-in default value does **not** force it to override the theme.

Example:

* built-in default `label_font_size` is `16`
* the theme sets `font_size` to `20`
* setting `style.label_font_size = 16` does **not** override the theme

### Theming

`TauXYStyle` reads theme values from the `TauPlot` **theme type variation**. Its base type is `PanelContainer`.

A theme resource using `TauPlot` must therefore include a base type declaration:

```gdscript
[resource]
TauPlot/base_type = &"PanelContainer"
TauPlot/constants/xy_pane_gap = 8
```

The following theme properties are used:

| Theme property | Description |
| --- | --- |
| `series_color_i`: `Color` | Maps to [`series_colors[i]`](#series_colors) where `i` is the series index. See note [1](#notes). |
| `series_alpha_percent`: `int` | Maps to [`series_alpha`](#series_alpha). Stored as an integer percentage (0–100), resolved as `percent / 100.0`, clamped to `[0.0, 1.0]`. |
| `xy_axis_color`: `Color` | Maps to [`axis_color`](#axis_color). |
| `font`: `Font` | Maps to [`label_font`](#label_font). |
| `font_size`: `int` | Maps to [`label_font_size`](#label_font_size). |
| `font_color`: `Color` | Maps to [`label_color`](#label_color). |
| `xy_x_major_tick_length`: `int` | Maps to [`x_major_tick_length_px`](#x_major_tick_length_px). |
| `xy_x_major_tick_thickness`: `int` | Maps to [`x_major_tick_thickness_px`](#x_major_tick_thickness_px). |
| `xy_y_major_tick_length`: `int` | Maps to [`y_major_tick_length_px`](#y_major_tick_length_px). |
| `xy_y_major_tick_thickness`: `int` | Maps to [`y_major_tick_thickness_px`](#y_major_tick_thickness_px). |
| `xy_minor_tick_length_ratio_percent`: `int` | Maps to [`minor_tick_length_ratio`](#minor_tick_length_ratio). Stored as an integer percentage (0–100), resolved as `percent / 100.0`, clamped to `[0.0, 1.0]`. |
| `xy_x_minor_tick_thickness`: `int` | Maps to [`x_minor_tick_thickness_px`](#x_minor_tick_thickness_px). |
| `xy_y_minor_tick_thickness`: `int` | Maps to [`y_minor_tick_thickness_px`](#y_minor_tick_thickness_px). |
| `xy_x_tick_x_label_gap`: `int` | Maps to [`x_tick_x_label_gap_px`](#x_tick_x_label_gap_px). |
| `xy_y_tick_y_label_gap`: `int` | Maps to [`y_tick_y_label_gap_px`](#y_tick_y_label_gap_px). |
| `xy_padding_left`: `int` | Maps to [`padding_left_px`](#padding_left_px). |
| `xy_padding_right`: `int` | Maps to [`padding_right_px`](#padding_right_px). |
| `xy_padding_top`: `int` | Maps to [`padding_top_px`](#padding_top_px). |
| `xy_padding_bottom`: `int` | Maps to [`padding_bottom_px`](#padding_bottom_px). |
| `xy_pane_gap`: `int` | Maps to [`pane_gap_px`](#pane_gap_px). |

### Side effects

Some property changes trigger a full layout recomputation. Others only trigger a redraw.

**Layout-affecting** (trigger both layout and redraw): [`label_font`](#label_font), [`label_font_size`](#label_font_size), [`x_major_tick_length_px`](#x_major_tick_length_px), [`x_major_tick_thickness_px`](#x_major_tick_thickness_px), [`y_major_tick_length_px`](#y_major_tick_length_px), [`y_major_tick_thickness_px`](#y_major_tick_thickness_px), [`x_tick_x_label_gap_px`](#x_tick_x_label_gap_px), [`y_tick_y_label_gap_px`](#y_tick_y_label_gap_px), [`padding_left_px`](#padding_left_px), [`padding_right_px`](#padding_right_px), [`padding_top_px`](#padding_top_px), [`padding_bottom_px`](#padding_bottom_px), [`pane_gap_px`](#pane_gap_px).

**Visual-only** (trigger redraw only): [`axis_color`](#axis_color), [`series_colors`](#series_colors), [`series_alpha`](#series_alpha), [`label_color`](#label_color), [`x_minor_tick_thickness_px`](#x_minor_tick_thickness_px), [`y_minor_tick_thickness_px`](#y_minor_tick_thickness_px), [`minor_tick_length_ratio`](#minor_tick_length_ratio).

### Example

```gdscript
var config := TauXYConfig.new()
config.style.axis_color = Color(0.8, 0.8, 0.8)
config.style.pane_gap_px = 8
config.style.series_colors = [Color.CYAN, Color.ORANGE, Color.LIME_GREEN]
config.style.series_alpha = 0.85
```

### Notes

1. **Partial series color palette override from theme.** When the theme defines `series_color_0`, `series_color_1`, ... entries, they are read sequentially starting from index 0 and stopping at the first missing index. Each entry overwrites the palette at the matching position. If the theme defines fewer colors than the built-in palette, the remaining entries keep their built-in values. If the theme defines more, the palette grows to accommodate them. Gaps are not supported: **if `series_color_0` is absent, no theme colors are loaded at all**, even if higher indices exist.

## Constructor

### `new()`

```gdscript
TauXYStyle.new() -> TauXYStyle
```

Creates a new `TauXYStyle` with all properties set to their built-in defaults. Properties left at their defaults remain theme-overridable.

## Properties

### series_colors

`series_colors`: `Array[Color]`

The ordered color palette assigned to series. Default is an eight-color palette.

Series colors are indexed by their series index in the [Dataset](dataset.md). Assigning a non-empty array that differs from the built-in default replaces the palette entirely for that plot.

---

### series_alpha

`series_alpha`: `float`

The alpha value applied to all series colors, overriding their alpha channel. Default is `1.0`.

Valid range is `0.0` (fully transparent) to `1.0` (fully opaque). This value replaces the alpha channel of every series color, ignoring any alpha encoded in the color itself.

---

### axis_color

`axis_color`: `Color`

The color used to draw axis lines and tick marks. Default is `Color(1, 1, 1, 1)`.

---

### label_font

`label_font`: `Font`

The font used to render tick labels on both axes. Default is `null`.

If `null`, the plot reads the font from the Godot theme entry `font` on the `TauPlot` node. If the theme does not define it either, Godot's built-in default font applies.

---

### label_font_size

`label_font_size`: `int`

The font size in pixels used for tick labels. Default is `16`.

---

### label_color

`label_color`: `Color`

The color used to render tick labels on both axes. Default is `Color(1, 1, 1, 1)`.

---

### x_major_tick_length_px

`x_major_tick_length_px`: `int`

The length in pixels of major tick marks on the X axis, measured perpendicular to the axis line. Default is `4`.

This value is orientation-independent: it applies regardless of which edge carries the X axis.

---

### x_major_tick_thickness_px

`x_major_tick_thickness_px`: `int`

The stroke width in pixels of major tick marks on the X axis. Default is `1`.

---

### y_major_tick_length_px

`y_major_tick_length_px`: `int`

The length in pixels of major tick marks on the Y axis, measured perpendicular to the axis line. Default is `4`.

This value is orientation-independent: it applies regardless of which edge carries the Y axis.

---

### y_major_tick_thickness_px

`y_major_tick_thickness_px`: `int`

The stroke width in pixels of major tick marks on the Y axis. Default is `1`.

---

### minor_tick_length_ratio

`minor_tick_length_ratio`: `float`

The length of a minor tick mark as a fraction of the corresponding major tick length. Default is `0.5`.

Valid range is `0.0` to `1.0`. This ratio is shared across both axes.

---

### x_minor_tick_thickness_px

`x_minor_tick_thickness_px`: `int`

The stroke width in pixels of minor tick marks on the X axis. Default is `1`.

---

### y_minor_tick_thickness_px

`y_minor_tick_thickness_px`: `int`

The stroke width in pixels of minor tick marks on the Y axis. Default is `1`.

---

### x_tick_x_label_gap_px

`x_tick_x_label_gap_px`: `int`

The pixel gap between the end of an X axis tick mark and its label. Default is `4`.

---

### y_tick_y_label_gap_px

`y_tick_y_label_gap_px`: `int`

The pixel gap between the end of a Y axis tick mark and its label. Default is `4`.

---

### padding_left_px

`padding_left_px`: `int`

The pixel padding between the left edge of the plot node and the left edge of the plot area. Default is `4`.

---

### padding_right_px

`padding_right_px`: `int`

The pixel padding between the right edge of the plot node and the right edge of the plot area. Default is `4`.

---

### padding_top_px

`padding_top_px`: `int`

The pixel padding between the top edge of the plot node and the top edge of the plot area. Default is `4`.

---

### padding_bottom_px

`padding_bottom_px`: `int`

The pixel padding between the bottom edge of the plot node and the bottom edge of the plot area. Default is `4`.

---

### pane_gap_px

`pane_gap_px`: `int`

The pixel gap between adjacent panes along the stacking direction. Default is `4`.

This property has no visible effect when the plot contains only one pane.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauXYStyle` during rendering and theme resolution.
* [`TauXYConfig`](xy_config.md) Owns the `TauXYStyle` instance via its [`style`](xy_config.md#style) property.
* [`TauPaneStyle`](pane_style.md) Sibling style resource for individual panes.
* [`TauBarStyle`](bar_style.md) Sibling style resource for bar overlays.
* [`TauScatterStyle`](scatter_style.md) Sibling style resource for scatter overlays.
* [`TauLegendStyle`](legend_style.md) Sibling style resource for the legend.
