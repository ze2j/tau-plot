# TauCrosshairStyle

!!! info ""
    **Inherits:** [`TauStyle`](style.md)

Controls the visual appearance of the crosshair guide lines drawn at the hovered position.

## Description

The crosshair draws up to two guide lines in the hovered pane. The X line crosses the pane at the hovered X position, the Y line at the hovered Y position, and each spans the pane from edge to edge. `TauCrosshairStyle` controls their color, their stroke width, and their dash length.

Which of the two lines appears comes from [`TauHoverConfig.crosshair_mode`](hover_config.md#crosshair_mode), not from this class. Both lines are drawn alike, so a plot cannot style one differently from the other.

`TauCrosshairStyle` lives on [`TauHoverConfig.crosshair_style`](hover_config.md#crosshair_style). It is created with [`TauHoverConfig`](hover_config.md) and is never `null`. Several [`TauHoverConfig`](hover_config.md) instances can share the same instance.

### Three-layer cascade

Each property is resolved in three layers: the built-in default, then the value the active Godot theme names, then the value assigned on this instance. A property counts as overridden as soon as it is assigned, whatever the value, and for an array property only assigning a new array counts.

See [`TauStyle`](style.md#three-layer-cascade) for the cascade and [`TauStyle`](style.md#theme-keys) for the grammar of the keys listed in [Theming](#theming).

### Theming

`TauCrosshairStyle` reads its keys from the `TauCrosshair` **theme type variation**, whose base type is `Control`.

A theme resource using `TauCrosshair` must include a base type declaration:

```gdscript
[resource]
TauCrosshair/base_type = &"Control"
TauCrosshair/constants/crosshair_thickness = 2
```

The following theme entries are used:

| Theme property | Description |
| --- | --- |
| `crosshair_color`: `Color` | Maps to [`color`](#color). |
| `crosshair_thickness`: `int` | Maps to [`thickness_px`](#thickness_px). |
| `crosshair_dash`: `int` | Maps to [`dash_px`](#dash_px). |

One crosshair is drawn at a time, in the hovered pane, so no key takes a pane index.

### Side effects

All properties are **visual-only**. A change triggers a redraw and never a layout recomputation.

### Example

```gdscript
var hover := TauHoverConfig.new()

hover.crosshair_mode = TauHoverConfig.CrosshairMode.BOTH
hover.crosshair_style.color = Color(1, 1, 1, 0.6)
hover.crosshair_style.dash_px = 0
```

## Constructor

### `new()`

```gdscript
TauCrosshairStyle.new() -> TauCrosshairStyle
```

Creates a `TauCrosshairStyle` holding the built-in default of every property.

## Properties

### color

`color`: `Color`

Color of the crosshair guide lines. Default is `Color(1, 1, 1, 0.4)`.

---

### thickness_px

`thickness_px`: `int`

Stroke width in pixels of the crosshair guide lines. Default is `1`.

Values below `1` are raised to `1` on assignment, so the crosshair cannot be hidden this way. Use [`TauHoverConfig.crosshair_mode`](hover_config.md#crosshair_mode) instead.

---

### dash_px

`dash_px`: `int`

Length in pixels of one dash of the crosshair guide lines, with an equal gap between dashes. Default is `4`.

`0` draws solid lines. Values below `0` are raised to `0` on assignment.

## Related Classes

* [`TauStyle`](style.md) Base class. Defines the cascade, the cycle indexing, and the theme key grammar.
* [`TauHoverConfig`](hover_config.md) Owns the `TauCrosshairStyle` instance through its [`crosshair_style`](hover_config.md#crosshair_style) property, and decides which guide lines are drawn.
* [`TauPlot`](tau_plot.md) The plot node. Resolves the cascade and holds the Godot theme the second layer reads.
* [`TauXYStyle`](xy_style.md) Sibling style resource for the plot as a whole.
* [`TauPaneStyle`](pane_style.md) Sibling style resource for the contents of one pane.
* [`TauBarStyle`](bar_style.md) Sibling style resource for bar overlays.
* [`TauScatterStyle`](scatter_style.md) Sibling style resource for scatter overlays.
* [`TauLineStyle`](line_style.md) Sibling style resource for line overlays.
* [`TauLegendStyle`](legend_style.md) Sibling style resource for the legend.
* [`TauTooltipStyle`](tooltip_style.md) Sibling style resource for the hover tooltip.