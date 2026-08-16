# TauXYStyle

!!! info ""
    **Inherits:** [`TauStyle`](style.md)

Controls the visual appearance of an XY plot.

## Description

`TauXYStyle` covers everything an XY plot draws outside its panes: the axis lines, the tick marks, the tick labels, the padding around the plot area, and the gap between neighbouring panes. It also owns the palette every overlay reads its per-series color from.

`TauXYStyle` lives on [`TauXYConfig.style`](xy_config.md#style). It is created with [`TauXYConfig`](xy_config.md) and is never `null`. Several [`TauXYConfig`](xy_config.md) instances can share the same instance.

Two properties are [cycles](style.md#cycles), [`series_colors`](#series_colors) and [`series_alphas`](#series_alphas), holding one entry per series. Every overlay reads them: they give a bar and a marker their fill color and a curve its stroke color. The rest of the class is scalar and applies to the whole plot.

### Three-layer cascade

Each property is resolved in three layers: the built-in default, then the value the active Godot theme names, then the value assigned on this instance. A property counts as overridden as soon as it is assigned, whatever the value, and for an array property only assigning a new array counts.

See [`TauStyle`](style.md#three-layer-cascade) for the cascade and [`TauStyle`](style.md#theme-keys) for the grammar of the keys listed in [Theming](#theming).

### Theming

`TauXYStyle` reads its keys from the `TauPlot` **theme type variation**, whose base type is `PanelContainer`.

A theme resource using `TauPlot` must include a base type declaration:

```gdscript
[resource]
TauPlot/base_type = &"PanelContainer"
TauPlot/constants/xy_pane_gap = 8
```

The following theme entries are used:

| Theme property | Description |
| --- | --- |
| `series_color_i`: `Color` | Maps to entry `i` of [`series_colors`](#series_colors). |
| `series_alpha_percent_i`: `int` | Maps to entry `i` of [`series_alphas`](#series_alphas). Stored as a percentage, resolved as `percent / 100.0`. |
| `xy_axis_color`: `Color` | Maps to [`axis_color`](#axis_color). |
| `font`: `Font` | Maps to [`label_font`](#label_font). |
| `font_size`: `int` | Maps to [`label_font_size`](#label_font_size). |
| `font_color`: `Color` | Maps to [`label_color`](#label_color). |
| `xy_x_major_tick_length`: `int` | Maps to [`x_major_tick_length_px`](#x_major_tick_length_px). |
| `xy_x_major_tick_thickness`: `int` | Maps to [`x_major_tick_thickness_px`](#x_major_tick_thickness_px). |
| `xy_y_major_tick_length`: `int` | Maps to [`y_major_tick_length_px`](#y_major_tick_length_px). |
| `xy_y_major_tick_thickness`: `int` | Maps to [`y_major_tick_thickness_px`](#y_major_tick_thickness_px). |
| `xy_minor_tick_length_ratio_percent`: `int` | Maps to [`minor_tick_length_ratio`](#minor_tick_length_ratio). Stored as a percentage, resolved as `percent / 100.0`. |
| `xy_x_minor_tick_thickness`: `int` | Maps to [`x_minor_tick_thickness_px`](#x_minor_tick_thickness_px). |
| `xy_y_minor_tick_thickness`: `int` | Maps to [`y_minor_tick_thickness_px`](#y_minor_tick_thickness_px). |
| `xy_x_tick_x_label_gap`: `int` | Maps to [`x_tick_x_label_gap_px`](#x_tick_x_label_gap_px). |
| `xy_y_tick_y_label_gap`: `int` | Maps to [`y_tick_y_label_gap_px`](#y_tick_y_label_gap_px). |
| `xy_padding_left`: `int` | Maps to [`padding_left_px`](#padding_left_px). |
| `xy_padding_right`: `int` | Maps to [`padding_right_px`](#padding_right_px). |
| `xy_padding_top`: `int` | Maps to [`padding_top_px`](#padding_top_px). |
| `xy_padding_bottom`: `int` | Maps to [`padding_bottom_px`](#padding_bottom_px). |
| `xy_pane_gap`: `int` | Maps to [`pane_gap_px`](#pane_gap_px). |

`TauXYStyle` describes the plot as a whole, so no key takes a pane index. The two cycle keys carry a series index, written `i` in the table.

### Side effects

**Layout-affecting**, triggering a layout recomputation and a redraw: [`label_font`](#label_font), [`label_font_size`](#label_font_size), [`x_major_tick_length_px`](#x_major_tick_length_px), [`x_major_tick_thickness_px`](#x_major_tick_thickness_px), [`y_major_tick_length_px`](#y_major_tick_length_px), [`y_major_tick_thickness_px`](#y_major_tick_thickness_px), [`x_tick_x_label_gap_px`](#x_tick_x_label_gap_px), [`y_tick_y_label_gap_px`](#y_tick_y_label_gap_px), [`padding_left_px`](#padding_left_px), [`padding_right_px`](#padding_right_px), [`padding_top_px`](#padding_top_px), [`padding_bottom_px`](#padding_bottom_px), [`pane_gap_px`](#pane_gap_px).

**Visual-only**, triggering a redraw alone: [`series_colors`](#series_colors), [`series_alphas`](#series_alphas), [`axis_color`](#axis_color), [`label_color`](#label_color), [`minor_tick_length_ratio`](#minor_tick_length_ratio), [`x_minor_tick_thickness_px`](#x_minor_tick_thickness_px), [`y_minor_tick_thickness_px`](#y_minor_tick_thickness_px).

### Example

```gdscript
var config := TauXYConfig.new()

config.style.axis_color = Color(0.8, 0.8, 0.8)
config.style.pane_gap_px = 8

# Six series come out cyan, orange, green, cyan, orange, green.
config.style.series_colors = [Color.CYAN, Color.ORANGE, Color.LIME_GREEN]

# One entry, so every series is drawn at 85 percent opacity.
config.style.series_alphas = [0.85]
```

## Constructor

### `new()`

```gdscript
TauXYStyle.new() -> TauXYStyle
```

Creates a `TauXYStyle` holding the built-in default of every property.

## Properties

### series_colors

`series_colors`: `Array[Color]`

Color of one series. Default is a palette of eight colors opening with `DEFAULT_SERIES_COLOR`.

Read as a cycle: series `i` uses entry `i % size`, where `i` is the series index in the [`Dataset`](dataset.md). An empty array falls back to `DEFAULT_SERIES_COLOR` for every series. See [`TauStyle`](style.md#cycles).

An empty array leaves every series in that one color with no way to tell them apart, so the plot pushes a warning when the resolved cycle is empty.

The alpha channel of an entry is ignored and replaced by the matching entry of [`series_alphas`](#series_alphas).

This property can be overridden per sample. See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for more information.

---

### series_alphas

`series_alphas`: `Array[float]`

Opacity of one series, replacing the alpha channel of its [`series_colors`](#series_colors) entry. Default is `[DEFAULT_SERIES_ALPHA]`, fully opaque.

Read as a cycle: series `i` uses entry `i % size`, where `i` is the series index in the [`Dataset`](dataset.md). Entries outside `0.0` to `1.0` are clamped into that range as the array is stored. An empty array falls back to `DEFAULT_SERIES_ALPHA` for every series. See [`TauStyle`](style.md#cycles).

This property can be overridden per sample. See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for more information.

---

### axis_color

`axis_color`: `Color`

Color of the axis lines and of the tick marks on every axis. Default is `Color(1, 1, 1, 1)`.

---

### label_font

`label_font`: `Font`

Font of the tick labels on every axis. Default is `null`.

The font comes from the `font` theme property of the `TauPlot` type variation when the theme sets it, and from the font Godot uses by default otherwise.

A font assigned here replaces the themed one. Assigning `null` is an assignment like any other: it drops the themed font, and the tick labels are drawn in the font Godot uses by default.

Assign a new `Font` rather than mutating the one already assigned. A change made in place is not detected and the plot keeps the previous resolution.

---

### label_font_size

`label_font_size`: `int`

Size in pixels of the tick labels. Default is `16`.

The size comes from the `font_size` theme property of the `TauPlot` type variation when the theme sets it, and from the theme's own default font size otherwise. In a stock project that default is `16`.

A size assigned here replaces the themed one.

Values below `1` are raised to `1` on assignment.

---

### label_color

`label_color`: `Color`

Color of the tick labels on every axis. Default is `Color(1, 1, 1, 1)`.

---

### x_major_tick_length_px

`x_major_tick_length_px`: `int`

How far a major tick on the X axis protrudes from the axis line, measured perpendicular to that line, in pixels. Default is `4`.

`x` names the logical axis and not a screen direction, so this reads the same whether the X axis sits on a horizontal or a vertical edge.

Values below `0` are raised to `0` on assignment.

---

### x_major_tick_thickness_px

`x_major_tick_thickness_px`: `int`

Stroke width in pixels of a major tick on the X axis. Default is `1`.

Values below `0` are raised to `0` on assignment.

---

### y_major_tick_length_px

`y_major_tick_length_px`: `int`

How far a major tick on a Y axis protrudes from the axis line, measured perpendicular to that line, in pixels. Default is `4`.

Applies to every Y axis of every pane.

Values below `0` are raised to `0` on assignment.

---

### y_major_tick_thickness_px

`y_major_tick_thickness_px`: `int`

Stroke width in pixels of a major tick on a Y axis. Default is `1`.

Values below `0` are raised to `0` on assignment.

---

### minor_tick_length_ratio

`minor_tick_length_ratio`: `float`

Length of a minor tick as a fraction of the major tick length of the same axis. Default is `0.5`.

Shared by every axis. Values outside `0.0` to `1.0` are clamped into that range on assignment.

---

### x_minor_tick_thickness_px

`x_minor_tick_thickness_px`: `int`

Stroke width in pixels of a minor tick on the X axis. Default is `1`.

Values below `0` are raised to `0` on assignment.

---

### y_minor_tick_thickness_px

`y_minor_tick_thickness_px`: `int`

Stroke width in pixels of a minor tick on a Y axis. Default is `1`.

Values below `0` are raised to `0` on assignment.

---

### x_tick_x_label_gap_px

`x_tick_x_label_gap_px`: `int`

Gap in pixels between the X axis tick marks and the X tick labels. Default is `4`.

Values below `0` are raised to `0` on assignment.

---

### y_tick_y_label_gap_px

`y_tick_y_label_gap_px`: `int`

Gap in pixels between the Y axis tick marks and the Y tick labels. Default is `4`.

Values below `0` are raised to `0` on assignment.

---

### padding_left_px

`padding_left_px`: `int`

Padding in pixels between the left edge of the plot and the panes, outside the space the axes reserve for their ticks and labels. Default is `4`.

Values below `0` are raised to `0` on assignment.

---

### padding_right_px

`padding_right_px`: `int`

Padding in pixels between the right edge of the plot and the panes, outside the space the axes reserve for their ticks and labels. Default is `4`.

Values below `0` are raised to `0` on assignment.

---

### padding_top_px

`padding_top_px`: `int`

Padding in pixels between the top edge of the plot and the panes, outside the space the axes reserve for their ticks and labels. Default is `4`.

Values below `0` are raised to `0` on assignment.

---

### padding_bottom_px

`padding_bottom_px`: `int`

Padding in pixels between the bottom edge of the plot and the panes, outside the space the axes reserve for their ticks and labels. Default is `4`.

Values below `0` are raised to `0` on assignment.

---

### pane_gap_px

`pane_gap_px`: `int`

Gap in pixels between two neighbouring panes, and between the axis titles that belong to them. Default is `4`.

A plot with a single pane draws nothing this property applies to.

Values below `0` are raised to `0` on assignment.

## Related Classes

* [`TauStyle`](style.md) Base class. Defines the cascade, the cycle indexing, and the theme key grammar.
* [`TauXYConfig`](xy_config.md) Owns the `TauXYStyle` instance through its [`style`](xy_config.md#style) property.
* [`TauPlot`](tau_plot.md) The plot node. Resolves the cascade and holds the Godot theme the second layer reads.
* [`Dataset`](dataset.md) Holds the series a cycle index refers to.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Defines the per-sample overrides that take priority over the two cycles.
* [`TauPaneStyle`](pane_style.md) Sibling style resource for the contents of one pane.
* [`TauBarStyle`](bar_style.md) Sibling style resource for bar overlays.
* [`TauScatterStyle`](scatter_style.md) Sibling style resource for scatter overlays.
* [`TauLineStyle`](line_style.md) Sibling style resource for line overlays.
* [`TauLegendStyle`](legend_style.md) Sibling style resource for the legend.
* [`TauTooltipStyle`](tooltip_style.md) Sibling style resource for the hover tooltip.
* [`TauCrosshairStyle`](crosshair_style.md) Sibling style resource for the hover crosshair.