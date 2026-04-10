# TauLegendConfig

!!! info ""
    **Inherits:** `Resource`  

Configures the legend system: placement, flow direction, and visual style.

## Description

`TauLegendConfig` is the configuration object for the legend in [`TauPlot`](tau_plot.md). It is assigned to [`TauPlot.legend_config`](tau_plot.md#legend_config). The legend itself is enabled or disabled through [`TauPlot.legend_enabled`](tau_plot.md#legend_enabled). When `legend_config` is `null`, built-in defaults apply for all settings.

The **position** controls where the legend appears relative to the plot area. `OUTSIDE_*` positions place the legend outside the plot area and consume space from it. `INSIDE_*` positions float the legend over the plot area without affecting its layout. See [`Position`](#position-enum) for the full list of values.

The **flow direction** controls whether legend items are arranged in a row or a column. [`AUTO`](#flowdirection) derives the direction from [`position`](#position): `OUTSIDE_LEFT` and `OUTSIDE_RIGHT` use vertical flow, all other positions use horizontal flow. See [`FlowDirection`](#flowdirection) for details.

Visual appearance is controlled by [`style`](#style), which holds font properties, key sizing, spacing, background, and margins. The style follows the standard three-layer cascade: built-in defaults, then Godot theme values, then user overrides. Any property left at its built-in default on the style resource remains overridable by the active Godot theme.

After [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) succeeds, the plot holds a reference to this instance. Mutating a property at runtime is supported, but requires calling [`TauPlot.queue_refresh()`](tau_plot.md#queue_refresh) to apply the change.

### Example

```gdscript
var legend := TauLegendConfig.new()
legend.position = TauLegendConfig.Position.INSIDE_TOP_RIGHT
legend.flow_direction = TauLegendConfig.FlowDirection.VERTICAL

%MyPlot.legend_config = legend
%MyPlot.legend_enabled = true
```

## Enums

### `Position` { #position-enum }

Controls where the legend is placed relative to the plot area.

| Value | Meaning |
|---|---|
| `OUTSIDE_TOP` | Legend is placed above the plot area and consumes vertical space from it. |
| `OUTSIDE_BOTTOM` | Legend is placed below the plot area and consumes vertical space from it. |
| `OUTSIDE_LEFT` | Legend is placed to the left of the plot area and consumes horizontal space from it. |
| `OUTSIDE_RIGHT` | Legend is placed to the right of the plot area and consumes horizontal space from it. |
| `INSIDE_TOP` | Legend floats over the plot area, centered along the top edge. |
| `INSIDE_BOTTOM` | Legend floats over the plot area, centered along the bottom edge. |
| `INSIDE_LEFT` | Legend floats over the plot area, centered along the left edge. |
| `INSIDE_RIGHT` | Legend floats over the plot area, centered along the right edge. |
| `INSIDE_TOP_LEFT` | Legend floats over the plot area, anchored to the top-left corner. |
| `INSIDE_TOP_RIGHT` | Legend floats over the plot area, anchored to the top-right corner. |
| `INSIDE_BOTTOM_LEFT` | Legend floats over the plot area, anchored to the bottom-left corner. |
| `INSIDE_BOTTOM_RIGHT` | Legend floats over the plot area, anchored to the bottom-right corner. |

---

### `FlowDirection`

Controls the direction in which legend items are arranged.

| Value | Meaning |
|---|---|
| `AUTO` | Direction is derived from [`position`](#position): `OUTSIDE_LEFT` and `OUTSIDE_RIGHT` use vertical flow, all other positions use horizontal flow. |
| `HORIZONTAL` | Items are arranged in a row. |
| `VERTICAL` | Items are arranged in a column. |

## Constructor

### `new()`

```gdscript
TauLegendConfig.new() -> TauLegendConfig
```

Creates a new `TauLegendConfig` with all properties set to their built-in defaults. The instance is ready to assign to [`TauPlot.legend_config`](tau_plot.md#legend_config).

## Properties

### position

`position`: [`Position`](#position-enum)

The placement of the legend relative to the plot area. Default is [`OUTSIDE_TOP`](#position-enum).

`OUTSIDE_*` values place the legend outside the plot area and consume space from it. `INSIDE_*` values float the legend over the plot area without affecting layout.

---

### flow_direction

`flow_direction`: [`FlowDirection`](#flowdirection)

The direction in which legend items are arranged. Default is [`AUTO`](#flowdirection).

[`AUTO`](#flowdirection) derives the direction from [`position`](#position): `OUTSIDE_LEFT` and `OUTSIDE_RIGHT` use vertical flow, all other positions use horizontal flow.

---

### style

`style`: [`TauLegendStyle`](legend_style.md)

The visual style applied to the legend: font, key size, spacing, background, and margins. Default is a freshly constructed [`TauLegendStyle`](legend_style.md) with all built-in defaults.

Never `null`. Modify properties directly on the instance. Any property left at its built-in default remains overridable by the active Godot theme. Multiple `TauLegendConfig` instances can share the same [`TauLegendStyle`](legend_style.md) resource.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Accepts `TauLegendConfig` via [`legend_config`](tau_plot.md#legend_config) and controls visibility via [`legend_enabled`](tau_plot.md#legend_enabled).
* [`TauLegendStyle`](legend_style.md) Controls the visual appearance of the legend, assigned to [`style`](#style).
* [`TauXYConfig`](xy_config.md) Top-level XY plot configuration. Sibling configuration object passed alongside `TauLegendConfig` to the plot.