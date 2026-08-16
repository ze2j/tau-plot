# TauPaneStyle

!!! info ""
    **Inherits:** [`TauStyle`](style.md)

Controls the visual appearance of a pane.

## Description

A pane is one plotting area of an XY plot, a rectangle holding its own axes and the overlays drawn against them. [`TauXYConfig.panes`](xy_config.md#panes) lists the panes of a plot.

`TauPaneStyle` carries the appearance of what the plot draws inside that rectangle. That is the grid lines: the lines crossing the pane at tick positions, giving a value something to be read against. A major grid line sits at a major tick and a minor grid line at a minor tick, on the X axis and on a Y axis alike, and each of those four families has its own color, thickness, and dash length.

Which grid lines are drawn at all is not decided here. It comes from [`TauGridLineConfig`](grid_line_config.md), held by [`TauPaneConfig.grid_line`](pane_config.md#grid_line), which defaults to `null`. A pane without one draws no grid line and reads no property of this class.

`TauPaneStyle` lives on [`TauPaneConfig.style`](pane_config.md#style). It is created with [`TauPaneConfig`](pane_config.md) and is never `null`. Several [`TauPaneConfig`](pane_config.md) instances can share the same instance.

### Three-layer cascade

Each property is resolved in three layers: the built-in default, then the value the active Godot theme names, then the value assigned on this instance. A property counts as overridden as soon as it is assigned, whatever the value, and for an array property only assigning a new array counts.

See [`TauStyle`](style.md#three-layer-cascade) for the cascade and [`TauStyle`](style.md#theme-keys) for the grammar of the keys listed in [Theming](#theming).

### Theming

`TauPaneStyle` reads its keys from the `TauPane` **theme type variation**, whose base type is `Control`.

A theme resource using `TauPane` must include a base type declaration:

```gdscript
[resource]
TauPane/base_type = &"Control"
TauPane/constants/pane_x_major_grid_line_thickness = 2
```

The following theme entries are used:

| Theme property | Description |
| --- | --- |
| `pane_x_major_grid_line_color`: `Color` | Maps to [`x_major_grid_line_color`](#x_major_grid_line_color). |
| `pane_x_major_grid_line_thickness`: `int` | Maps to [`x_major_grid_line_thickness_px`](#x_major_grid_line_thickness_px). |
| `pane_x_major_grid_line_dash`: `int` | Maps to [`x_major_grid_line_dash_px`](#x_major_grid_line_dash_px). |
| `pane_x_minor_grid_line_color`: `Color` | Maps to [`x_minor_grid_line_color`](#x_minor_grid_line_color). |
| `pane_x_minor_grid_line_thickness`: `int` | Maps to [`x_minor_grid_line_thickness_px`](#x_minor_grid_line_thickness_px). |
| `pane_x_minor_grid_line_dash`: `int` | Maps to [`x_minor_grid_line_dash_px`](#x_minor_grid_line_dash_px). |
| `pane_y_major_grid_line_color`: `Color` | Maps to [`y_major_grid_line_color`](#y_major_grid_line_color). |
| `pane_y_major_grid_line_thickness`: `int` | Maps to [`y_major_grid_line_thickness_px`](#y_major_grid_line_thickness_px). |
| `pane_y_major_grid_line_dash`: `int` | Maps to [`y_major_grid_line_dash_px`](#y_major_grid_line_dash_px). |
| `pane_y_minor_grid_line_color`: `Color` | Maps to [`y_minor_grid_line_color`](#y_minor_grid_line_color). |
| `pane_y_minor_grid_line_thickness`: `int` | Maps to [`y_minor_grid_line_thickness_px`](#y_minor_grid_line_thickness_px). |
| `pane_y_minor_grid_line_dash`: `int` | Maps to [`y_minor_grid_line_dash_px`](#y_minor_grid_line_dash_px). |

`TauPaneStyle` describes the contents of a pane, so every key above accepts a pane index appended as a number: `pane_x_major_grid_line_color_1` names the second pane alone.

### Side effects

All properties are **visual-only**. A change triggers a redraw and never a layout recomputation.

### Example

```gdscript
var pane := TauPaneConfig.new()

# Grid lines are drawn only once a grid line configuration is set.
pane.grid_line = TauGridLineConfig.new()

pane.style.y_major_grid_line_color = Color(1, 1, 1, 0.25)
pane.style.y_major_grid_line_dash_px = 4
```

## Constructor

### `new()`

```gdscript
TauPaneStyle.new() -> TauPaneStyle
```

Creates a `TauPaneStyle` holding the built-in default of every property.

## Properties

### x_major_grid_line_color

`x_major_grid_line_color`: `Color`

Color of the X major grid lines. Default is `Color(1, 1, 1, 0.15)`.

---

### x_major_grid_line_thickness_px

`x_major_grid_line_thickness_px`: `int`

Stroke width in pixels of the X major grid lines. Default is `1`.

Values below `0` are raised to `0` on assignment. A grid line at `0` thickness is not drawn.

---

### x_major_grid_line_dash_px

`x_major_grid_line_dash_px`: `int`

Length in pixels of one dash of the X major grid lines, with an equal gap between dashes. Default is `0`.

`0` draws solid lines. Any positive value cuts them into dashes of that length. Values below `0` are raised to `0` on assignment.

---

### x_minor_grid_line_color

`x_minor_grid_line_color`: `Color`

Color of the X minor grid lines. Default is `Color(1, 1, 1, 0.08)`.

---

### x_minor_grid_line_thickness_px

`x_minor_grid_line_thickness_px`: `int`

Stroke width in pixels of the X minor grid lines. Default is `1`.

Values below `0` are raised to `0` on assignment. A grid line at `0` thickness is not drawn.

---

### x_minor_grid_line_dash_px

`x_minor_grid_line_dash_px`: `int`

Length in pixels of one dash of the X minor grid lines, with an equal gap between dashes. Default is `0`.

`0` draws solid lines. Any positive value cuts them into dashes of that length. Values below `0` are raised to `0` on assignment.

---

### y_major_grid_line_color

`y_major_grid_line_color`: `Color`

Color of the Y major grid lines. Default is `Color(1, 1, 1, 0.15)`.

---

### y_major_grid_line_thickness_px

`y_major_grid_line_thickness_px`: `int`

Stroke width in pixels of the Y major grid lines. Default is `1`.

Values below `0` are raised to `0` on assignment. A grid line at `0` thickness is not drawn.

---

### y_major_grid_line_dash_px

`y_major_grid_line_dash_px`: `int`

Length in pixels of one dash of the Y major grid lines, with an equal gap between dashes. Default is `0`.

`0` draws solid lines. Any positive value cuts them into dashes of that length. Values below `0` are raised to `0` on assignment.

---

### y_minor_grid_line_color

`y_minor_grid_line_color`: `Color`

Color of the Y minor grid lines. Default is `Color(1, 1, 1, 0.08)`.

---

### y_minor_grid_line_thickness_px

`y_minor_grid_line_thickness_px`: `int`

Stroke width in pixels of the Y minor grid lines. Default is `1`.

Values below `0` are raised to `0` on assignment. A grid line at `0` thickness is not drawn.

---

### y_minor_grid_line_dash_px

`y_minor_grid_line_dash_px`: `int`

Length in pixels of one dash of the Y minor grid lines, with an equal gap between dashes. Default is `0`.

`0` draws solid lines. Any positive value cuts them into dashes of that length. Values below `0` are raised to `0` on assignment.

## Related Classes

* [`TauStyle`](style.md) Base class. Defines the cascade, the cycle indexing, and the theme key grammar.
* [`TauPaneConfig`](pane_config.md) Owns the `TauPaneStyle` instance through its [`style`](pane_config.md#style) property.
* [`TauGridLineConfig`](grid_line_config.md) Decides which grid lines are drawn and which axis they are read from.
* [`TauPlot`](tau_plot.md) The plot node. Resolves the cascade and holds the Godot theme the second layer reads.
* [`TauXYConfig`](xy_config.md) Holds the pane list a pane index refers to.
* [`TauXYStyle`](xy_style.md) Sibling style resource for the plot as a whole.
* [`TauBarStyle`](bar_style.md) Sibling style resource for bar overlays.
* [`TauScatterStyle`](scatter_style.md) Sibling style resource for scatter overlays.
* [`TauLineStyle`](line_style.md) Sibling style resource for line overlays.
* [`TauLegendStyle`](legend_style.md) Sibling style resource for the legend.
* [`TauTooltipStyle`](tooltip_style.md) Sibling style resource for the hover tooltip.
* [`TauCrosshairStyle`](crosshair_style.md) Sibling style resource for the hover crosshair.