# TauLegendStyle

!!! info ""
    **Inherits:** [`TauStyle`](style.md)

Controls the visual appearance of the legend.

## Description

The legend lists one entry per visible series. An entry holds a **key strip** and a **label**: the strip carries one key per overlay the series is drawn by, and the label carries the series name. A series drawn as bars and as markers therefore shows two keys before its name.

Which series appear is decided by [`TauXYSeriesBinding.show_in_legend`](xy_series_binding.md#show_in_legend), one flag per binding. `TauLegendStyle` controls what an entry looks like: the font of the label, the size of a key, the gaps inside and between entries, the panel behind the whole legend, and the cap past which entries are reached by scrolling.

`TauLegendStyle` lives on [`TauLegendConfig.style`](legend_config.md#style). It is created with [`TauLegendConfig`](legend_config.md) and is never `null`. Several [`TauLegendConfig`](legend_config.md) instances can share the same instance.

### Three-layer cascade

Each property is resolved in three layers: the built-in default, then the value the active Godot theme names, then the value assigned on this instance. A property counts as overridden as soon as it is assigned, whatever the value, and for an array property only assigning a new array counts.

See [`TauStyle`](style.md#three-layer-cascade) for the cascade and [`TauStyle`](style.md#theme-keys) for the grammar of the keys listed in [Theming](#theming).

### Theming

`TauLegendStyle` reads its keys from the `TauLegend` **theme type variation**, whose base type is `PanelContainer`.

A theme resource using `TauLegend` must include a base type declaration:

```gdscript
[resource]
TauLegend/base_type = &"PanelContainer"
TauLegend/constants/legend_key_label_gap_px = 8
```

The following theme entries are used:

| Theme property | Description |
| --- | --- |
| `font`: `Font` | Maps to [`font`](#font). |
| `font_size`: `int` | Maps to [`font_size`](#font_size). |
| `font_color`: `Color` | Maps to [`font_color`](#font_color). |
| `legend_key_size_px`: `int` | Maps to [`key_size_px`](#key_size_px). |
| `legend_key_gap_px`: `int` | Maps to [`key_gap_px`](#key_gap_px). |
| `legend_key_label_gap_px`: `int` | Maps to [`key_label_gap_px`](#key_label_gap_px). |
| `legend_item_gap_px`: `int` | Maps to [`item_gap_px`](#item_gap_px). |
| `legend_background`: `StyleBox` | Maps to [`background`](#background). |
| `legend_margin_px`: `int` | Maps to [`margin_px`](#margin_px). |
| `legend_max_size_px`: `int` | Maps to [`max_size_px`](#max_size_px). |

The plot draws one legend, so no key takes a pane index.

### Side effects

**Layout-affecting**, triggering a layout recomputation and a redraw: [`font`](#font), [`font_size`](#font_size), [`key_size_px`](#key_size_px), [`key_gap_px`](#key_gap_px), [`key_label_gap_px`](#key_label_gap_px), [`item_gap_px`](#item_gap_px), [`background`](#background), [`margin_px`](#margin_px), [`max_size_px`](#max_size_px).

**Visual-only**, triggering a redraw alone: [`font_color`](#font_color).

### Example

```gdscript
var legend := TauLegendConfig.new()

legend.style.key_size_px = 16
legend.style.font_size = 12
legend.style.item_gap_px = 12
```

## Constructor

### `new()`

```gdscript
TauLegendStyle.new() -> TauLegendStyle
```

Creates a `TauLegendStyle` holding the built-in default of every property.

## Properties

### font

`font`: `Font`

Font of the series names. Default is `null`.

The font comes from the `font` theme property of the `TauLegend` type variation when the theme sets it, and from the font Godot uses by default otherwise.

A font assigned here replaces the themed one. Assigning `null` is an assignment like any other: it drops the themed font, and the series names are drawn in the font Godot uses by default.

Assign a new `Font` rather than mutating the one already assigned. A change made in place is not detected and the plot keeps the previous resolution.

---

### font_size

`font_size`: `int`

Size in pixels of the series names. Default is `16`.

The size comes from the `font_size` theme property of the `TauLegend` type variation when the theme sets it, and from the theme's own default font size otherwise. In a stock project that default is `16`.

A size assigned here replaces the themed one.

Values below `1` are raised to `1` on assignment.

---

### font_color

`font_color`: `Color`

Color of the series names. Default is `Color(1, 1, 1, 1)`.

---

### key_size_px

`key_size_px`: `int`

Height in pixels of one legend key. Default is `12`.

A key keeps its aspect ratio, so this height scales the whole key.

Values below `1` are raised to `1` on assignment.

---

### key_gap_px

`key_gap_px`: `int`

Gap in pixels between two keys of the same entry. Default is `2`.

Only visible on a series drawn by more than one overlay, which is the one case where an entry carries several keys.

Values below `0` are raised to `0` on assignment.

---

### key_label_gap_px

`key_label_gap_px`: `int`

Gap in pixels between the key strip of an entry and its series name. Default is `6`.

Values below `0` are raised to `0` on assignment.

---

### item_gap_px

`item_gap_px`: `int`

Gap in pixels between two legend entries. Default is `8`.

Applies along the flow direction and between wrapped rows or columns alike. Values below `0` are raised to `0` on assignment.

---

### background

`background`: `StyleBox`

`StyleBox` drawn behind the legend. Its content margins set the padding between its border and the entries. Default is `null`, resolving to a fully transparent `StyleBoxFlat` with an 8 pixel content margin on all sides.

Assign a new `StyleBox` rather than mutating the one already assigned. A change made in place is not detected and the plot keeps the previous resolution.

---

### margin_px

`margin_px`: `int`

Distance in pixels between the legend and the edges of the data area. Default is `8`.

Only read for the `INSIDE_*` values of [`TauLegendConfig.position`](legend_config.md#position), where the legend floats over the data area. A corner position applies it in both directions, an edge-centered position in the perpendicular direction alone.

Values below `0` are raised to `0` on assignment.

---

### max_size_px

`max_size_px`: `int`

Cap in pixels on the legend across its flow direction: the height of a legend flowing horizontally, the width of one flowing vertically. Default is `0`.

`0` applies no cap. Entries past the cap are reached by scrolling. Values below `0` are raised to `0` on assignment.

## Related Classes

* [`TauStyle`](style.md) Base class. Defines the cascade, the cycle indexing, and the theme key grammar.
* [`TauLegendConfig`](legend_config.md) Owns the `TauLegendStyle` instance through its [`style`](legend_config.md#style) property. Its [`position`](legend_config.md#position) decides the flow direction the size cap applies across.
* [`TauXYSeriesBinding`](xy_series_binding.md) Decides through [`show_in_legend`](xy_series_binding.md#show_in_legend) whether a series contributes an entry.
* [`TauPlot`](tau_plot.md) The plot node. Accepts a [`TauLegendConfig`](legend_config.md) through [`legend_config`](tau_plot.md#legend_config), resolves the cascade, and holds the Godot theme the second layer reads.
* [`TauXYStyle`](xy_style.md) Sibling style resource for the plot as a whole.
* [`TauPaneStyle`](pane_style.md) Sibling style resource for the contents of one pane.
* [`TauBarStyle`](bar_style.md) Sibling style resource for bar overlays.
* [`TauScatterStyle`](scatter_style.md) Sibling style resource for scatter overlays.
* [`TauLineStyle`](line_style.md) Sibling style resource for line overlays.
* [`TauTooltipStyle`](tooltip_style.md) Sibling style resource for the hover tooltip.
* [`TauCrosshairStyle`](crosshair_style.md) Sibling style resource for the hover crosshair.