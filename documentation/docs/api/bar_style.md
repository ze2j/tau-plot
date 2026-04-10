# TauBarStyle

!!! info ""
    **Inherits:** `Resource`  

Controls the visual appearance of bar overlays.

## Description

A bar overlay draws one bar per sample at its X position in the pane. `TauBarStyle` controls how those bars look: their pixel width and intragroup gap when the `THEME` width policy is active, the `StyleBox` that defines their shape, corner radii, and border, and how both change when a bar is hovered.

`TauBarStyle` lives on [`TauBarConfig.style`](bar_config.md#style). It is created automatically when [`TauBarConfig`](bar_config.md) is instantiated, so it is never `null`.

Multiple [`TauBarConfig`](bar_config.md) instances can reference the same `TauBarStyle` resource. Every bar overlay that holds a reference picks up any change made to that shared instance.

### Three-layer cascade

Each property's final value is resolved through the following cascade, in order:

1. **Built-in default**  
    The final value starts from the built-in default.

2. **Theme value**  
    If the active Godot theme defines a matching bar property, that value replaces the built-in default. The theme is checked twice per scalar property. First, the non-indexed key is read and applies to every pane. Then, a pane-indexed key is read and applies only to the pane at that index, overwriting the non-indexed value for that pane alone.

    For example, with two panes:

    ```gdscript
    # Applies to all panes.
    TauBar/constants/bar_width_px = 48
    # Overrides only pane 1, leaving pane 0 at the value above.
    TauBar/constants/bar_width_px_1 = 32
    ```

    Pane `0` uses `48`. Pane `1` uses `32`.

3. **User override**  
    If the property is explicitly set on the `TauBarStyle` instance, that value overrides both the theme and the built-in default.

In short:

- the last layer that provides a value wins
- the Godot theme is suited for **project-wide styling**, with optional per-pane targeting via indexed keys
- `TauBarStyle` is suited for **per-plot or per-pane styling**

**Override detection limitation**

A property is considered overridden only when its value differs from the corresponding built-in default constant. For `StyleBox` properties, a non-`null` value is treated as an override.

As a result, assigning a scalar property to exactly its built-in default value does **not** force it to override the theme.

Example:

* built-in default `bar_width_px` is `64`
* the theme sets `bar_width_px` to `48`
* setting `style.bar_width_px = 64` does **not** override the theme

### Theming

`TauBarStyle` reads theme values from the `TauBar` **theme type variation**. Its base type is `Control`.

A theme resource using `TauBar` must therefore include a base type declaration:

```gdscript
[resource]
TauBar/base_type = &"Control"
TauBar/constants/bar_width_px = 48
```

The following theme entries are used:

| Theme property | Description |
| --- | --- |
| `bar_width_px`: `int` | Maps to [`bar_width_px`](#bar_width_px) |
| `bar_intragroup_gap_px`: `int` | Maps to [`bar_intragroup_gap_px`](#bar_intragroup_gap_px) |
| `bar_style_box`: `StyleBox` | Maps to [`style_box`](#style_box) |
| `bar_hovered_style_box`: `StyleBox` | Maps to [`hovered_style_box`](#hovered_style_box) |

Every entry above also supports a pane-indexed variant formed by appending an underscore and the zero-based pane index (for example, `bar_width_px_0`). The indexed variant overwrites the shared value when both are defined.

### Side effects

All properties are **visual-only**. Every change triggers a redraw but never triggers layout recomputation.

### Notes

1. **Per-sample color overrides.** [`BarVisualAttributes`](bar_visual_attributes.md) and [`BarVisualCallbacks`](bar_visual_callbacks.md) can override the fill color and alpha per sample, taking priority over [`TauXYStyle.series_colors`](xy_style.md#series_colors) and [`TauXYStyle.series_alpha`](xy_style.md#series_alpha).

## Constructor

### `new()`

```gdscript
TauBarStyle.new() -> TauBarStyle
```

Creates a new `TauBarStyle` with all properties set to their built-in defaults. Properties left at their defaults remain theme-overridable.

## Properties

### bar_width_px

`bar_width_px`: `int`

The width in pixels of each bar when [`TauBarConfig.bar_width_policy`](bar_config.md#bar_width_policy) is set to `THEME`. Default is `64`.

This property has no effect when the active width policy is not `THEME`.

---

### bar_intragroup_gap_px

`bar_intragroup_gap_px`: `int`

The pixel gap between adjacent bars within the same group in `GROUPED` mode when [`TauBarConfig.bar_width_policy`](bar_config.md#bar_width_policy) is set to `THEME`. Default is `0`.

This property has no effect when the active width policy is not `THEME`.

---

### style_box

`style_box`: `StyleBox`

The `StyleBox` used to draw each bar in its normal state. Default is `null`.

If `null`, the renderer uses a plain `StyleBoxFlat` with no corner radii, no border, and no content margins.

The accepted concrete types are `StyleBoxFlat` and `StyleBoxTexture`. Any other subclass logs an error and the bar is not drawn. 

`StyleBoxFlat.bg_color` and `StyleBoxTexture.modulate_color` are always ignored: the fill color comes from [`series_colors`](xy_style.md#series_colors) and [`series_alpha`](xy_style.md#series_alpha), except when per-sample overrides are active (see note [1](#notes)).

Assigning any non-null `StyleBox` replaces the default entirely.

---

### hovered_style_box

`hovered_style_box`: `StyleBox`

The `StyleBox` used to draw a bar when it is hovered. Default is `null`.

If `null`, the renderer uses a `StyleBoxFlat` with no corner radii and a 2-pixel white border on all sides.

The same rules apply as for [`style_box`](#style_box).

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauBarStyle` during rendering and theme resolution.
* [`TauBarConfig`](bar_config.md) Owns the `TauBarStyle` instance via its [`style`](bar_config.md#style) property.
* [`TauXYStyle`](xy_style.md) Sibling style resource for the whole plot.
* [`TauPaneStyle`](pane_style.md) Sibling style resource for individual panes.
* [`TauScatterStyle`](scatter_style.md) Sibling style resource for scatter overlays.
* [`TauLegendStyle`](legend_style.md) Sibling style resource for the legend.
* [`TauTooltipStyle`](tooltip_style.md) Sibling style resource for the hover tooltip.
* [`TauCrosshairStyle`](crosshair_style.md) Sibling style resource for the hover crosshair.
