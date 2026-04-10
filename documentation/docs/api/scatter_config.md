# TauScatterConfig

!!! info ""
    **Inherits:** [`TauPaneOverlayConfig`](pane_overlay_config.md)

Configures a [`SCATTER`](tau_plot.md#paneoverlaytype) overlay rendered inside a pane.

## Description

`TauScatterConfig` is the concrete [`TauPaneOverlayConfig`](pane_overlay_config.md) subclass for scatter overlays. Place one instance in [`TauPaneConfig.overlays`](pane_config.md#overlays) to draw scatter markers in that pane. The plot sets [`overlay_type`](pane_overlay_config.md#overlay_type) to [`SCATTER`](tau_plot.md#paneoverlaytype) at construction.

The **marker size policy** controls how marker sizes are computed:

- [`AUTO`](#markersizepolicy) resolves to [`THEME`](#markersizepolicy).
- [`THEME`](#markersizepolicy) reads the marker size from the Godot theme via [`TauScatterStyle`](scatter_style.md), falling back to built-in defaults when no theme value is defined.
- [`DATA_UNITS`](#markersizepolicy) expresses the marker size in X data units, so markers grow and shrink in screen space as the X domain changes.

All properties on this class are visual-only. No property affects domain computation or layout. Every change triggers a redraw without rebuilding the layout.

The **hover distance gate** controls how close the cursor must be to a marker for it to register as a hit. [`hover_max_distance_px`](#hover_max_distance_px) sets this threshold and its interpretation depends on the active [`hover mode`](hover_config.md#hovermode) and the [`X axis type`](axis_config.md#type).

Visual appearance is controlled by [`style`](#style), which holds marker size, outline width and color, hover highlight parameters, and the shape palette. Per-sample color, alpha, size, shape, outline color, and outline width overrides are applied through [`scatter_visual_callbacks`](#scatter_visual_callbacks) or through [`ScatterVisualAttributes`](scatter_visual_attributes.md) on the series binding.

After [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) succeeds, the plot holds a reference to this instance. Mutating a property at runtime is supported, but requires calling [`TauPlot.queue_refresh()`](tau_plot.md#queue_refresh) to apply the change.

### Example

```gdscript
var scatter := TauScatterConfig.new()
scatter.marker_size_policy = TauScatterConfig.MarkerSizePolicy.DATA_UNITS
scatter.marker_size_data_units = 0.5
scatter.hover_max_distance_px = 16

var pane := TauPaneConfig.new()
pane.y_left_axis = TauAxisConfig.new()
pane.overlays = [scatter]
```

## Enums

### `MarkerSizePolicy`

Selects the strategy used to compute scatter marker sizes.

| Value | Meaning |
|---|---|
| `AUTO` | Resolves to [`THEME`](#markersizepolicy). |
| `THEME` | Reads the marker size from the Godot theme via [`TauScatterStyle.marker_size_px`](scatter_style.md#marker_size_px). Falls back to the built-in default when no theme value is defined. |
| `DATA_UNITS` | Expresses the marker size in X data units using [`marker_size_data_units`](#marker_size_data_units). The rendered size in pixels changes as the X domain changes. |

## Constructor

### `new()`

```gdscript
TauScatterConfig.new() -> TauScatterConfig
```

Creates a new `TauScatterConfig` with all properties set to their built-in defaults and [`overlay_type`](pane_overlay_config.md#overlay_type) set to [`SCATTER`](tau_plot.md#paneoverlaytype). The instance is ready to place in [`TauPaneConfig.overlays`](pane_config.md#overlays).

## Properties

### marker_size_policy

`marker_size_policy`: [`MarkerSizePolicy`](#markersizepolicy)

The strategy used to compute marker sizes. Default is [`AUTO`](#markersizepolicy).

Determines which size property is active:

- [`DATA_UNITS`](#markersizepolicy) activates [`marker_size_data_units`](#marker_size_data_units). 
- [`THEME`](#markersizepolicy) activate the size resolved from [`TauScatterStyle`](scatter_style.md) and the Godot theme.

This property is visual-only.

---

### marker_size_data_units

`marker_size_data_units`: `float`

The marker size expressed in X data units. Default is `1.0`.

Only used when the active policy is [`DATA_UNITS`](#markersizepolicy). Must be `>= 0`. The rendered pixel size scales with the X axis domain, so markers cover a constant span of data space rather than a constant number of pixels. This property is visual-only.

---

### hover_max_distance_px

`hover_max_distance_px`: `int`

The maximum pixel distance from the cursor to a marker center for the marker to be considered a hover hit. Default is `20`.

The exact gating behavior depends on the active [`hover mode`](hover_config.md#hovermode) and the [`X axis type`](axis_config.md#type). See [`TauHoverConfig`](hover_config.md) for the full description. This property is visual-only.

---

### style

`style`: [`TauScatterStyle`](scatter_style.md)

The visual style applied to markers in this overlay: marker size, outline width and color, hover highlight, and shape palette. Default is a freshly constructed [`TauScatterStyle`](scatter_style.md) with all built-in defaults.

Never `null`. Modify properties directly on the instance. Any property left at its built-in default remains overridable by the active Godot theme. Multiple `TauScatterConfig` instances can share the same [`TauScatterStyle`](scatter_style.md) resource.

---

### scatter_visual_callbacks

`scatter_visual_callbacks`: [`ScatterVisualCallbacks`](scatter_visual_callbacks.md)

Typed accessor for per-sample visual callbacks on this scatter overlay. Default is `null`.

Reads and writes the inherited [`TauPaneOverlayConfig.visual_callbacks`](pane_overlay_config.md#visual_callbacks) property cast to [`ScatterVisualCallbacks`](scatter_visual_callbacks.md). Assigning a non-[`ScatterVisualCallbacks`](scatter_visual_callbacks.md) instance through the base property and then reading `scatter_visual_callbacks` returns `null`. Assign a [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) instance here to override color, alpha, size, shape, outline color, or outline width per sample at draw time. When both this and [`ScatterVisualAttributes`](scatter_visual_attributes.md) buffers are set, buffers take priority over callbacks.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauScatterConfig` during layout and rendering.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class. Defines [`overlay_type`](pane_overlay_config.md#overlay_type), [`z_order`](pane_overlay_config.md#z_order), [`hoverable`](pane_overlay_config.md#hoverable), and [`visual_callbacks`](pane_overlay_config.md#visual_callbacks).
* [`TauPaneConfig`](pane_config.md) Holds the overlay in its [`overlays`](pane_config.md#overlays) array.
* [`TauScatterStyle`](scatter_style.md) Controls visual appearance. Owned by this config via [`style`](#style).
* [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) Supplies per-sample color, alpha, size, shape, and outline overrides via callbacks.
* [`ScatterVisualAttributes`](scatter_visual_attributes.md) Supplies per-sample color, alpha, size, shape, and outline overrides via pre-built buffers. Takes priority over [`ScatterVisualCallbacks`](scatter_visual_callbacks.md).
* [`TauXYStyle`](xy_style.md) Provides the series color palette applied when no per-sample overrides are active.
* [`TauBarConfig`](bar_config.md) Sibling overlay configuration for bar overlays.