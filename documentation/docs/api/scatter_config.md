# TauScatterConfig

!!! info ""
    **Inherits:** [`TauPaneOverlayConfig`](pane_overlay_config.md)

Configures a [`SCATTER`](tau_plot.md#paneoverlaytype) overlay rendered inside a pane.

## Description

`TauScatterConfig` is the concrete [`TauPaneOverlayConfig`](pane_overlay_config.md) subclass for scatter overlays. Place one instance in [`TauPaneConfig.overlays`](pane_config.md#overlays) to draw scatter markers in that pane. The plot sets [`overlay_type`](pane_overlay_config.md#overlay_type) to [`SCATTER`](tau_plot.md#paneoverlaytype) at construction.

The **marker size policy** controls where the size of a marker comes from:

- [`AUTO`](#markersizepolicy) resolves to [`THEME`](#markersizepolicy).
- [`THEME`](#markersizepolicy) reads the resolved [`TauScatterStyle.marker_sizes_px`](scatter_style.md#marker_sizes_px), a [cycle](style.md#cycles) holding one pixel size per series.
- [`DATA_UNITS`](#markersizepolicy) reads [`marker_size_data_units`](#marker_size_data_units), so markers grow and shrink in screen space as the X domain changes.

All properties on this class are visual-only. No property affects domain computation or layout. Every change triggers a redraw without rebuilding the layout.

Hover hit testing is gated by [`hover_max_distance_px`](#hover_max_distance_px). What the threshold measures depends on the resolved [hover mode](hover_config.md#hovermode) and on the [X axis type](axis_config.md#type-enum).

Visual appearance is controlled by [`style`](#style), which holds the marker size and shape cycles, the outline, and the hovered-state size, outline width, and outline color. Per-sample color, alpha, size, shape, outline color, and outline width overrides are applied through [`scatter_visual_callbacks`](#scatter_visual_callbacks) or through [`ScatterVisualAttributes`](scatter_visual_attributes.md) on the series binding. See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for the order the two mechanisms resolve in.

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
| `THEME` | Reads the marker size in pixels from the resolved [`TauScatterStyle.marker_sizes_px`](scatter_style.md#marker_sizes_px) cycle. |
| `DATA_UNITS` | Expresses the marker size in X data units using [`marker_size_data_units`](#marker_size_data_units). The rendered size in pixels changes as the X domain changes. A categorical X axis has no data span to convert, and the size falls back to the [`TauScatterStyle.marker_sizes_px`](scatter_style.md#marker_sizes_px) cycle. |

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

Determines which size source is active:

- [`DATA_UNITS`](#markersizepolicy) activates [`marker_size_data_units`](#marker_size_data_units).
- [`THEME`](#markersizepolicy) activates the size resolved from [`TauScatterStyle`](scatter_style.md).

This property is visual-only.

---

### marker_size_data_units

`marker_size_data_units`: `float`

The marker size expressed in X data units. Default is `1.0`.

Only used when the active policy is [`DATA_UNITS`](#markersizepolicy). Must be above `0.0`, and a lower value is a validation error and [`TauPlot.plot_xy()`](tau_plot.md#plot_xy) aborts. The rendered pixel size scales with the X axis domain, so markers cover a constant span of data space rather than a constant number of pixels.

On a categorical X axis the property is not read at all. There is no data span to convert, so markers are sized from [`TauScatterStyle.marker_sizes_px`](scatter_style.md#marker_sizes_px) instead, with no error and no warning.

This property is visual-only.

---

### hover_max_distance_px

`hover_max_distance_px`: `int`

The maximum distance in pixels from the cursor to a marker center for the marker to count as a hover hit. Default is `20`.

In [`NEAREST`](hover_config.md#hovermode) mode the threshold is a 2D distance gate in pane-local screen space. Markers farther than this from the cursor are excluded, and the closest of the remaining markers becomes the hit.

In [`X_ALIGNED`](hover_config.md#hovermode) mode on a [`CONTINUOUS`](axis_config.md#type-enum) X axis, the overlay picks the X position where it has markers closest to the hovered X position, and reports the markers there. It reports nothing when that position is farther than this distance from the hovered X position. Only the distance along the X axis counts here. The same threshold is then compared with the 2D distance between the cursor and each reported marker, which sets [`SampleHit.contains_pointer`](sample_hit.md#contains_pointer).

In [`X_ALIGNED`](hover_config.md#hovermode) mode on a [`CATEGORICAL`](axis_config.md#type-enum) X axis the threshold gates nothing. Every marker at the hovered category is collected, and the threshold only sets [`SampleHit.contains_pointer`](sample_hit.md#contains_pointer).

This property is visual-only.

---

### style

`style`: [`TauScatterStyle`](scatter_style.md)

The visual style applied to markers in this overlay: the marker size and shape cycles, the outline width and color, and the hovered-state marker size, outline width, and outline color. Default is a freshly constructed [`TauScatterStyle`](scatter_style.md) with all built-in defaults.

Never `null`. Modify properties directly on the instance. Any property left unassigned on this instance can still be set by the active Godot theme. Multiple `TauScatterConfig` instances can share the same [`TauScatterStyle`](scatter_style.md) resource.

---

### scatter_visual_callbacks

`scatter_visual_callbacks`: [`ScatterVisualCallbacks`](scatter_visual_callbacks.md)

Typed accessor for per-sample visual callbacks on this scatter overlay. Default is `null`.

Reads and writes the inherited [`TauPaneOverlayConfig.visual_callbacks`](pane_overlay_config.md#visual_callbacks) property cast to [`ScatterVisualCallbacks`](scatter_visual_callbacks.md). Assigning a non-[`ScatterVisualCallbacks`](scatter_visual_callbacks.md) instance through the base property and then reading `scatter_visual_callbacks` returns `null`. Assign a [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) instance here to override color, alpha, size, shape, outline color, or outline width per sample at draw time. See [`TauPaneOverlayConfig`](pane_overlay_config.md#per-sample-overrides) for the order a callback resolves in against a [`ScatterVisualAttributes`](scatter_visual_attributes.md) buffer and the style property.

`scatter_visual_callbacks` is not serializable. The property is not exported and cannot be saved in a `.tres` resource file. Assign it at runtime only.

## Related Classes

* [`TauPlot`](tau_plot.md) The plot node. Consumes `TauScatterConfig` during layout and rendering.
* [`TauPaneOverlayConfig`](pane_overlay_config.md) Base class. Defines [`overlay_type`](pane_overlay_config.md#overlay_type), [`z_order`](pane_overlay_config.md#z_order), [`hoverable`](pane_overlay_config.md#hoverable), and [`visual_callbacks`](pane_overlay_config.md#visual_callbacks).
* [`TauPaneConfig`](pane_config.md) Holds the overlay in its [`overlays`](pane_config.md#overlays) array.
* [`TauAxisConfig`](axis_config.md) Configures the X axis whose type decides how [`hover_max_distance_px`](#hover_max_distance_px) and [`DATA_UNITS`](#markersizepolicy) sizing behave.
* [`TauHoverConfig`](hover_config.md) Holds the hover mode that [`hover_max_distance_px`](#hover_max_distance_px) is read under.
* [`SampleHit`](sample_hit.md) Describes one hovered sample, including [`contains_pointer`](sample_hit.md#contains_pointer).
* [`TauScatterStyle`](scatter_style.md) Controls visual appearance. Owned by this config via [`style`](#style).
* [`ScatterVisualCallbacks`](scatter_visual_callbacks.md) Supplies per-sample color, alpha, size, shape, and outline overrides via callbacks.
* [`ScatterVisualAttributes`](scatter_visual_attributes.md) Supplies per-sample color, alpha, size, shape, and outline overrides via pre-built buffers.
* [`TauStyle`](style.md) Base class of [`TauScatterStyle`](scatter_style.md). Defines how a cycle is indexed.
* [`TauXYStyle`](xy_style.md) Provides the series color cycle applied when no per-sample override supplies a color.
* [`TauBarConfig`](bar_config.md) Sibling overlay configuration for bar overlays.
* [`TauLineConfig`](line_config.md) Sibling overlay configuration for line overlays.