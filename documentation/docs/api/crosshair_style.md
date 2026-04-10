# TauCrosshairStyle

!!! info ""
    **Inherits:** `Resource`  

Controls the visual appearance of the crosshair guide lines drawn at the hovered position.

## Description

`TauCrosshairStyle` controls how the crosshair looks: the color, stroke width, and dash length of the lines drawn across a pane at the hovered sample position.

The crosshair draws up to two lines per pane. An X line runs perpendicular to the X axis at the hovered X position, spanning the full pane extent along the Y direction. A Y line runs perpendicular to the Y axis at the hovered Y position, spanning the full pane extent along the X direction. Which lines appear depends on [`TauHoverConfig.crosshair_mode`](hover_config.md#crosshair_mode), not on `TauCrosshairStyle`.

`TauCrosshairStyle` lives on [`TauHoverConfig.crosshair_style`](hover_config.md#crosshair_style). It is created automatically when [`TauHoverConfig`](hover_config.md) is instantiated, so it is never `null`.

Multiple [`TauHoverConfig`](hover_config.md) instances can reference the same `TauCrosshairStyle` resource. Every crosshair that holds a reference picks up any change made to that shared instance.

### Three-layer cascade

Each property's final value is resolved through the following cascade, in order:

1. **Built-in default**  
    The final value starts from the built-in default.

2. **Theme value**  
    If the active Godot theme defines a matching crosshair property, that value replaces the built-in default.

3. **User override**  
    If the property is explicitly set on the `TauCrosshairStyle` instance, that value overrides both the theme and the built-in default.

In short:

- the last layer that provides a value wins
- the Godot theme is suited for **project-wide styling**
- `TauCrosshairStyle` is suited for **per-plot styling**

**Override detection limitation**

A property is considered overridden only when its value differs from the corresponding built-in default constant.

As a result, assigning a property to exactly its built-in default value does **not** force it to override the theme.

Example:

* built-in default `thickness_px` is `1`
* the theme sets `crosshair_thickness` to `3`
* setting `style.thickness_px = 1` does **not** override the theme

### Theming

`TauCrosshairStyle` reads theme values from the `TauCrosshair` **theme type variation**. Its base type is `Control`.

A theme resource using `TauCrosshair` must therefore include a base type declaration:

```gdscript
[resource]
TauCrosshair/base_type = &"Control"
TauCrosshair/constants/crosshair_thickness = 2
```

The following theme entries are used:

| Theme property | Description |
| --- | --- |
| `crosshair_color`: `Color` | Maps to [`color`](#color) |
| `crosshair_thickness`: `int` | Maps to [`thickness_px`](#thickness_px) |
| `crosshair_dash`: `int` | Maps to [`dash_px`](#dash_px) |

### Side effects

All properties are **visual-only**. Every change triggers a redraw but never triggers layout recomputation.

## Constructor

### `new()`

```gdscript
TauCrosshairStyle.new() -> TauCrosshairStyle
```

Creates a new `TauCrosshairStyle` with all properties set to their built-in defaults. Properties left at their defaults remain theme-overridable.

## Properties

### color

`color`: `Color`

The color used to draw the crosshair lines. Default is `Color(1, 1, 1, 0.4)`.

---

### thickness_px

`thickness_px`: `int`

The stroke width in pixels of the crosshair lines. Default is `1`.

---

### dash_px

`dash_px`: `int`

The dash length in pixels of the crosshair lines. Default is `4`.

A value of `0` produces solid lines. Any positive value switches the lines to dashed rendering with alternating segments of that length.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauCrosshairStyle` during rendering and theme resolution.
* [`TauHoverConfig`](hover_config.md) Owns the `TauCrosshairStyle` instance via its [`crosshair_style`](hover_config.md#crosshair_style) property.
* [`TauXYStyle`](xy_style.md) Sibling style resource for the whole plot.
* [`TauPaneStyle`](pane_style.md) Sibling style resource for individual panes.
* [`TauBarStyle`](bar_style.md) Sibling style resource for bar overlays.
* [`TauScatterStyle`](scatter_style.md) Sibling style resource for scatter overlays.
* [`TauLegendStyle`](legend_style.md) Sibling style resource for the legend.
* [`TauTooltipStyle`](tooltip_style.md) Sibling style resource for the hover tooltip.
