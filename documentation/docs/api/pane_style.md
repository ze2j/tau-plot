# TauPaneStyle

!!! info ""
    **Inherits:** `Resource`  

Controls the visual appearance of a single pane.

## Description

`TauPaneStyle` controls the visual appearance of a pane rendered by `TauPlot`. Grid lines are the horizontal and vertical lines drawn across the pane background at each tick position, giving the reader a reference grid to read data values against. Major grid lines align with major ticks. Minor grid lines align with minor ticks and are typically thinner and more transparent to stay visually subordinate.

`TauPaneStyle` lives on [`TauPaneConfig.style`](pane_config.md#style). It defaults to `null`, in which case the pane falls back to theme values and then to built-in defaults. Assign a `TauPaneStyle` instance to override individual properties for that pane.

Multiple `TauPaneConfig` instances can reference the same `TauPaneStyle` resource. Every pane that holds a reference picks up any change made to that shared instance.

### Three-layer cascade

Each property's final value is resolved through the following cascade, in order:

1. **Built-in default**  
    The final value starts from the built-in default.

2. **Theme value**  
    If the active Godot theme defines a matching pane property, that value replaces the built-in default. The theme is checked twice per property. First, the non-indexed key is read and applies to every pane. Then, a pane-indexed key is read and applies only to the pane at that index, overwriting the non-indexed value for that pane alone.

    For example, with two panes:

    ```gdscript
    # Applies to all panes.
    TauPane/colors/pane_x_major_grid_line_color = Color(1, 1, 1, 0.15)
    # Overrides only pane 1, leaving pane 0 at the value above.
    TauPane/colors/pane_x_major_grid_line_color_1 = Color(1, 0.5, 0, 0.3)
    ```

    Pane `0` uses `Color(1, 1, 1, 0.15)`. Pane `1` uses `Color(1, 0.5, 0, 0.3)`.

3. **User override**  
    If the property is explicitly set on the `TauPaneStyle` instance, that value overrides both the theme and the built-in default.

In short:

- the last layer that provides a value wins
- the Godot theme is suited for **project-wide styling**, with optional per-pane targeting via indexed keys
- `TauPaneStyle` is suited for **per-plot or per-pane styling**

**Override detection limitation**

A property is considered overridden only when its value differs from the corresponding built-in default constant.

As a result, assigning a property to exactly its built-in default value does **not** force it to override the theme.

Example:

* built-in default `x_major_grid_line_thickness_px` is `1`
* the theme sets `pane_x_major_grid_line_thickness` to `2`
* setting `style.x_major_grid_line_thickness_px = 1` does **not** override the theme

### Theming

`TauPaneStyle` reads theme values from the `TauPane` **theme type variation**. Its base type is `Control`.

A theme resource using `TauPane` must therefore include a base type declaration:

```gdscript
[resource]
TauPane/base_type = &"Control"
TauPane/constants/pane_x_major_grid_line_thickness = 2
```

The following theme entries are used:

| Theme property | Description |
| --- | --- |
|  `pane_x_major_grid_line_color`: `Color` | Maps to [`x_major_grid_line_color`](#x_major_grid_line_color) |
| `pane_x_major_grid_line_thickness`: `int` | Maps to [`x_major_grid_line_thickness_px`](#x_major_grid_line_thickness_px) |
| `pane_x_major_grid_line_dash`: `int` | Maps to [`x_major_grid_line_dash_px`](#x_major_grid_line_dash_px) |
| `pane_x_minor_grid_line_color`: `Color` | Maps to [`x_minor_grid_line_color`](#x_minor_grid_line_color) |
| `pane_x_minor_grid_line_thickness`: `int` | Maps to [`x_minor_grid_line_thickness_px`](#x_minor_grid_line_thickness_px) |
| `pane_x_minor_grid_line_dash`: `int` | Maps to [`x_minor_grid_line_dash_px`](#x_minor_grid_line_dash_px) |
| `pane_y_major_grid_line_color`: `Color` | Maps to [`y_major_grid_line_color`](#y_major_grid_line_color) |
| `pane_y_major_grid_line_thickness`: `int` | Maps to [`y_major_grid_line_thickness_px`](#y_major_grid_line_thickness_px) |
| `pane_y_major_grid_line_dash`: `int` | Maps to [`y_major_grid_line_dash_px`](#y_major_grid_line_dash_px) |
| `pane_y_minor_grid_line_color`: `Color` | Maps to [`y_minor_grid_line_color`](#y_minor_grid_line_color) |
| `pane_y_minor_grid_line_thickness`: `int` | Maps to [`y_minor_grid_line_thickness_px`](#y_minor_grid_line_thickness_px) |
| `pane_y_minor_grid_line_dash`: `int` | Maps to [`y_minor_grid_line_dash_px`](#y_minor_grid_line_dash_px) |

Each entry above also supports a pane-indexed variant formed by appending an underscore and the zero-based pane index (for example, `pane_x_major_grid_line_color_0`). The indexed variant overwrites the shared value when both are defined.

### Side effects

All properties are **visual-only**. Every change triggers a redraw but never triggers layout recomputation.

## Constructor

### `new()`

```gdscript
TauPaneStyle.new() -> TauPaneStyle
```

Creates a new `TauPaneStyle` with all properties set to their built-in defaults. Properties left at their defaults remain theme-overridable.

## Properties

### x_major_grid_line_color

`x_major_grid_line_color`: `Color`

The color used to draw major grid lines on the X axis. Default is `Color(1, 1, 1, 0.15)`.

---

### x_major_grid_line_thickness_px

`x_major_grid_line_thickness_px`: `int`

The stroke width in pixels of major grid lines on the X axis. Default is `1`.

---

### x_major_grid_line_dash_px

`x_major_grid_line_dash_px`: `int`

The dash length in pixels of major grid lines on the X axis. Default is `0`.

A value of `0` produces a solid line. Any positive value switches the line to dashed rendering with alternating segments of that length.

---

### x_minor_grid_line_color

`x_minor_grid_line_color`: `Color`

The color used to draw minor grid lines on the X axis. Default is `Color(1, 1, 1, 0.08)`.

---

### x_minor_grid_line_thickness_px

`x_minor_grid_line_thickness_px`: `int`

The stroke width in pixels of minor grid lines on the X axis. Default is `1`.

---

### x_minor_grid_line_dash_px

`x_minor_grid_line_dash_px`: `int`

The dash length in pixels of minor grid lines on the X axis. Default is `0`.

A value of `0` produces a solid line. Any positive value switches the line to dashed rendering with alternating segments of that length.

---

### y_major_grid_line_color

`y_major_grid_line_color`: `Color`

The color used to draw major grid lines on the Y axis. Default is `Color(1, 1, 1, 0.15)`.

---

### y_major_grid_line_thickness_px

`y_major_grid_line_thickness_px`: `int`

The stroke width in pixels of major grid lines on the Y axis. Default is `1`.

---

### y_major_grid_line_dash_px

`y_major_grid_line_dash_px`: `int`

The dash length in pixels of major grid lines on the Y axis. Default is `0`.

A value of `0` produces a solid line. Any positive value switches the line to dashed rendering with alternating segments of that length.

---

### y_minor_grid_line_color

`y_minor_grid_line_color`: `Color`

The color used to draw minor grid lines on the Y axis. Default is `Color(1, 1, 1, 0.08)`.

---

### y_minor_grid_line_thickness_px

`y_minor_grid_line_thickness_px`: `int`

The stroke width in pixels of minor grid lines on the Y axis. Default is `1`.

---

### y_minor_grid_line_dash_px

`y_minor_grid_line_dash_px`: `int`

The dash length in pixels of minor grid lines on the Y axis. Default is `0`.

A value of `0` produces a solid line. Any positive value switches the line to dashed rendering with alternating segments of that length.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauPaneStyle` during rendering and theme resolution.
* [`TauPaneConfig`](pane_config.md) Owns the `TauPaneStyle` instance via its [`style`](pane_config.md#style) property.
* [`TauXYStyle`](xy_style.md) Sibling style resource for the whole plot.
* [`TauBarStyle`](bar_style.md) Sibling style resource for bar overlays.
* [`TauScatterStyle`](scatter_style.md) Sibling style resource for scatter overlays.
* [`TauLegendStyle`](legend_style.md) Sibling style resource for the legend.
* [`TauTooltipStyle`](tooltip_style.md) Sibling style resource for the hover tooltip.
* [`TauCrosshairStyle`](crosshair_style.md) Sibling style resource for the hover crosshair.
